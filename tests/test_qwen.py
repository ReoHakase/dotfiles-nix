"""Exercise the SSH/API and private-config boundaries without a GPU or model download."""

import contextlib
import http.server
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("qwen", ROOT / "scripts/qwen.py")
qwen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qwen)
KEY = "a" * 64


@contextlib.contextmanager
def server(respond):
    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            code, headers, body = respond(self.path, self.headers)
            self.send_response(code)
            for name, value in headers.items():
                self.send_header(name, value)
            self.end_headers()
            self.wfile.write(json.dumps(body).encode())

        def log_message(self, *args):
            pass

    instance = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=instance.serve_forever, daemon=True)
    thread.start()
    try:
        with patch.object(qwen, "BASE", f"http://127.0.0.1:{instance.server_port}"):
            yield
    finally:
        instance.shutdown()
        instance.server_close()
        thread.join()


class ClientTests(unittest.TestCase):
    def test_piped_prompt_survives_ssh_setup(self):
        def respond(path, headers):
            return 200, {}, ({"service": "strata", "loaded": True} if path == "/health"
                             else {"data": [{"id": "live-model"}]})

        with tempfile.TemporaryDirectory() as directory, server(respond):
            root = Path(directory)
            ssh = root / "ssh"
            ssh.write_text('#!/usr/bin/env python3\nimport sys\nsys.stdin.read()\n'
                           'if sys.argv[1:3] != ["-F", "/nix/store/generated-ssh-config"]: sys.exit(2)\n'
                           f'print({KEY!r} if "cat " in sys.argv[-1] else "")\n')
            ssh.chmod(0o755)
            aichat = root / "aichat"
            aichat.write_text('#!/usr/bin/env python3\nimport sys\nsys.stdout.write(sys.stdin.read())\n')
            aichat.chmod(0o755)
            code = (f'import sys; sys.path.insert(0, {str(ROOT / "scripts")!r}); import qwen; '
                    f'qwen.BASE={qwen.BASE!r}; sys.argv=["qwen", "chat"]; qwen.main()')
            result = subprocess.run([sys.executable, "-c", code], text=True, input="日本語の質問\n",
                                    capture_output=True, check=True,
                                    env={**os.environ, "XDG_CONFIG_HOME": str(root / "config"),
                                         "QWEN_SSH_CONFIG": "/nix/store/generated-ssh-config",
                                         "PATH": str(root) + os.pathsep + os.environ["PATH"]})
            self.assertEqual(result.stdout.strip(), "日本語の質問")

    def test_readiness_waits_for_loaded_model_and_uses_live_id(self):
        loaded = iter([False, True])
        requests = []

        def respond(path, headers):
            requests.append((path, headers.get("Authorization")))
            body = {"service": "strata", "loaded": next(loaded)} if path == "/health" else {
                "data": [{"id": "alias", "alias_of": "real-model"}, {"id": "real-model"}]}
            return 200, {}, body

        with server(respond), patch.object(qwen.time, "sleep"):
            self.assertEqual(qwen.wait_ready(KEY), "real-model")
        self.assertEqual([p for p, _ in requests], ["/health", "/health", "/v1/models"])
        self.assertTrue(all(auth == "Bearer " + KEY for _, auth in requests))

    def test_api_does_not_follow_redirects_with_credentials(self):
        paths = []

        def respond(path, headers):
            paths.append(path)
            return 302, {"Location": "/would-receive-key"}, {}

        with server(respond), self.assertRaisesRegex(RuntimeError, "redirected"):
            qwen.api("/health", KEY)
        self.assertEqual(paths, ["/health"])

    def test_wrong_service_and_bad_credentials_fail_immediately(self):
        for code, body, message in [(200, {"service": "other"}, "not the Strata"),
                                    (401, {}, "rejected the API key")]:
            with self.subTest(code=code), server(lambda *_: (code, {}, body)):
                with self.assertRaisesRegex(RuntimeError, message):
                    qwen.wait_ready(KEY)

    def test_start_reuses_tunnel_and_generates_private_local_client_configs(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(qwen, "CONFIG", Path(directory) / "config"):
            with patch.object(qwen, "ssh", return_value=subprocess.CompletedProcess([], 0)) as ssh:
                with patch.object(qwen, "remote", return_value=subprocess.CompletedProcess([], 0, KEY + "\n")) as remote:
                    with patch.object(qwen, "wait_ready", return_value="live-model"):
                        qwen.start()
                        qwen.start()
            self.assertTrue(all("-M" not in call.args for call in ssh.call_args_list))
            self.assertIn("start --no-block strata-qwen.service", str(remote.call_args_list))
            self.assertNotIn(KEY, str(ssh.call_args_list) + str(remote.call_args_list))
            for path in qwen.CONFIG.rglob("*"):
                if path.is_file():
                    self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            config = json.loads((qwen.CONFIG / "opencode.json").read_text())
            self.assertEqual(config["enabled_providers"], ["kcvl"])
            self.assertEqual(config["model"], "kcvl/live-model")
            self.assertEqual(config["provider"]["kcvl"]["options"]["baseURL"], qwen.BASE + "/v1")

    def test_missing_key_does_not_start_service_or_write_client_configs(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(qwen, "CONFIG", Path(directory) / "config"):
            with patch.object(qwen, "ssh", return_value=subprocess.CompletedProcess([], 0)):
                with patch.object(qwen, "remote", return_value=subprocess.CompletedProcess([], 0, "")) as remote:
                    with self.assertRaisesRegex(RuntimeError, "invalid API key"):
                        qwen.start()
            self.assertEqual(remote.call_count, 1)
            self.assertFalse(qwen.CONFIG.exists())

    def test_stop_closes_only_dedicated_tunnel_even_when_server_stop_fails(self):
        with patch.object(qwen, "remote", side_effect=RuntimeError("unreachable")):
            with patch.object(qwen, "ssh") as ssh, self.assertRaisesRegex(RuntimeError, "unreachable"):
                qwen.stop()
        self.assertEqual(ssh.call_args.args, ("-O", "exit", "kcvl-strata"))

    def test_desktop_preserves_other_connections_and_requires_quiet_host(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(qwen.Path, "home", return_value=Path(directory)):
            target = Path(directory) / ".strata/data/model-providers.json"
            other = {"id": "other", "name": "Other provider", "apiKey": "other-secret"}
            qwen.save_json(target, [other])
            with patch.object(qwen.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)):
                with self.assertRaisesRegex(RuntimeError, "Quit Strata"):
                    qwen.configure_desktop("live-model", KEY)
            self.assertEqual(json.loads(target.read_text()), [other])
            with patch.object(qwen.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
                qwen.configure_desktop("live-model", KEY)
            self.assertEqual(json.loads(target.read_text())[0], other)
            original = target.read_bytes()
            # Once registered, a running app needs no config rewrite.
            with patch.object(qwen.subprocess, "run", side_effect=AssertionError("no process check needed")):
                qwen.configure_desktop("live-model", KEY)
            self.assertEqual(target.read_bytes(), original)


class SetupTests(unittest.TestCase):
    def test_unavailable_gpu_stops_before_model_download_or_key_creation(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            bin_dir = home / ".local/bin"
            bin_dir.mkdir(parents=True)
            for name in ("strata", "nvidia-smi"):
                script = bin_dir / name
                script.write_text("#!/bin/sh\nexit 1\n")
                script.chmod(0o755)
            env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / "config"),
                   "PATH": str(bin_dir) + os.pathsep + os.environ["PATH"],
                   "STRATA_INSTALLER": "/unused", "STRATA_FEED": "https://example.invalid/pinned",
                   "STRATA_VECTOR": "/nix/store/pinned-vector.gguf"}
            result = subprocess.run(["bash", ROOT / "scripts/setup-strata.sh", "prepare"],
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn("GPU unavailable", result.stderr)
            self.assertFalse((home / "config").exists())

    def test_prepare_retains_user_options_and_key_and_stops_model(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            bin_dir = home / ".local/bin"
            bin_dir.mkdir(parents=True)
            config = home / "model.json"
            config.write_text(json.dumps({"user_args": ["--prefill", "512"], "sampling": {"temperature": 0.7}}))
            log = home / "calls.jsonl"
            stub = f'''#!/usr/bin/env python3
import json, os, pathlib, sys
with pathlib.Path({str(log)!r}).open("a") as f:
    f.write(json.dumps([pathlib.Path(sys.argv[0]).name, *sys.argv[1:]]) + "\\n")
if sys.argv[1:3] == ["profile", "show"]:
    print(json.dumps({{"profile": {{"source_config": {str(config)!r}}}}}))
'''
            for name in ("strata", "nvidia-smi", "systemctl"):
                path = bin_dir / name
                path.write_text(stub)
                path.chmod(0o755)
            env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / "config"),
                   "PATH": str(bin_dir) + os.pathsep + os.environ["PATH"],
                   "STRATA_INSTALLER": "/unused", "STRATA_FEED": "https://example.invalid/pinned",
                   "STRATA_VECTOR": "/nix/store/pinned-vector.gguf"}
            for operation in ("prepare", "iq3_s"):
                subprocess.run(["bash", ROOT / "scripts/setup-strata.sh", operation], env=env, check=True, capture_output=True)
                key = (home / "config/strata-kcvl/api-key").read_text()
                if operation == "prepare":
                    original_key = key
            self.assertEqual(key, original_key)
            saved = json.loads(config.read_text())
            self.assertEqual(saved["user_args"][:2], ["--prefill", "512"])
            self.assertEqual(saved["user_args"].count("--control-vector-scaled"), 1)
            self.assertTrue(saved["sampling"]["experimental_speed_projection"])
            self.assertEqual(saved["sampling"]["temperature"], 0.7)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertIn(["strata", "launch", "--preset", "kcvl-qwen", "--stop"], calls)
            self.assertNotIn(original_key.strip(), log.read_text())
            self.assertEqual(config.stat().st_mode & 0o777, 0o600)


if __name__ == "__main__":
    unittest.main()
