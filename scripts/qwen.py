#!/usr/bin/env python3
"""Start the kcvl service, tunnel its API, and launch existing clients."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

HOST = "kcvl-strata"
BASE = "http://127.0.0.1:8180"
SERVICE = "strata-qwen.service"
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "strata-kcvl"


class LocalAPIOnly(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise RuntimeError("Strata API redirected the request. Check the SSH tunnel.")


def ssh(*args, capture=False, check=True):
    return subprocess.run(
        ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", *args],
        check=check, text=True, stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None, stdin=subprocess.DEVNULL,
    )


def remote(command, capture=False):
    return ssh("-o", "ClearAllForwardings=yes", HOST, command, capture=capture)


def private_write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(path.parent, 0o700)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".qwen-")
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(value)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def save_json(path, value):
    private_write(path, json.dumps(value, indent=2) + "\n")


def api(path, key):
    request = urllib.request.Request(BASE + path, headers={"Authorization": "Bearer " + key})
    # A configured corporate HTTP proxy must not receive the local API credential.
    with urllib.request.build_opener(urllib.request.ProxyHandler({}), LocalAPIOnly()).open(request, timeout=5) as response:
        return json.load(response)


def wait_ready(key, timeout=600):
    deadline = time.monotonic() + timeout
    while True:
        try:
            health = api("/health", key)
            if health.get("service") != "strata":
                raise RuntimeError("Port 8180 is not the Strata API. Check the SSH tunnel.")
            if health.get("loaded"):
                models = api("/v1/models", key).get("data", [])
                model = next((row["id"] for row in models if not row.get("alias_of")), None)
                if model:
                    return model
        except urllib.error.HTTPError as error:
            if error.code in (401, 403):
                raise RuntimeError("Strata rejected the API key. Re-run strata-qwen-setup on kcvl.") from None
            if error.code != 503:
                raise RuntimeError(f"Strata API returned HTTP {error.code}.") from None
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            pass
        if time.monotonic() >= deadline:
            raise RuntimeError("Model did not become ready in 10 minutes. Check: ssh kcvl 'journalctl --user -u strata-qwen -n 60'")
        time.sleep(2)


def configure_clients(model, key):
    save_json(CONFIG / "aichat" / "config.yaml", {
        "model": "kcvl:" + model,
        "clients": [{"type": "openai-compatible", "name": "kcvl", "api_base": BASE + "/v1",
                     "api_key": key, "models": [{"name": model, "max_input_tokens": 24576,
                                                "max_output_tokens": 8192}]}],
    })
    save_json(CONFIG / "opencode.json", {
        "$schema": "https://opencode.ai/config.json",
        "model": "kcvl/" + model, "small_model": "kcvl/" + model,
        "enabled_providers": ["kcvl"], "share": "disabled", "autoupdate": False,
        "provider": {"kcvl": {"npm": "@ai-sdk/openai-compatible", "name": "kcvl Strata",
                    "options": {"baseURL": BASE + "/v1", "apiKey": key},
                    "models": {model: {"name": "Qwen3.8-Flash-Next (kcvl)", "tool_call": True, "reasoning": True,
                                       "limit": {"context": 32768, "input": 24576, "output": 8192}}}}},
    })


def start():
    if ssh("-O", "check", HOST, capture=True, check=False).returncode:
        ssh("-M", "-N", "-f", "-o", "ControlPersist=no", "-o", "ExitOnForwardFailure=yes", HOST)
    key = remote('cat "${XDG_CONFIG_HOME:-$HOME/.config}/strata-kcvl/api-key"', capture=True).stdout.strip()
    if not re.fullmatch(r"[0-9a-f]{64}", key):
        raise RuntimeError("Missing or invalid API key. Run strata-qwen-setup on kcvl first.")
    remote("systemctl --user start --no-block " + SERVICE)
    print("Waiting for Qwen on kcvl…", file=sys.stderr)
    model = wait_ready(key)
    private_write(CONFIG / "api-key", key + "\n")
    configure_clients(model, key)
    return model, key


def stop():
    try:
        remote("systemctl --user stop " + SERVICE)
    finally:
        ssh("-O", "exit", HOST, capture=True, check=False)
    print("Qwen stopped; the dedicated SSH tunnel is closed.")


def configure_desktop(model, key):
    path = Path(os.environ.get("STRATA_HOME", Path.home() / ".strata")) / "data" / "model-providers.json"
    connections = json.loads(path.read_text()) if path.exists() else []
    existing = next((row for row in connections if row.get("name") == "kcvl Strata"), None)
    entry = {"id": existing["id"] if existing else "kcvl-strata",
             "kind": "custom", "provider": None, "name": "kcvl Strata",
             "baseUrl": BASE + "/v1", "protocol": "openai-chat", "apiKey": key,
             "models": [{"id": model, "name": "Qwen3.8-Flash-Next (kcvl)",
                         "contextMax": 32768, "maxOutput": 8192, "vision": False, "reasoning": True}]}
    if existing == entry:
        return
    # The host caches this file; do not race its in-memory state or other connections.
    running = subprocess.run(["pgrep", "-x", "strata-desktop"], stdout=subprocess.DEVNULL, check=False)
    if running.returncode == 0:
        raise RuntimeError("Quit Strata once, then run qwen-desktop to register/update the kcvl connection.")
    save_json(path, [entry if row is existing else row for row in connections] if existing else connections + [entry])


def main():
    operation, *args = sys.argv[1:]
    if operation == "stop":
        stop()
        return
    model, key = start()
    if operation == "start":
        print(f"Ready: {model} at {BASE}/v1")
    elif operation == "chat":
        os.environ["AICHAT_CONFIG_DIR"] = str(CONFIG / "aichat")
        os.execvp("aichat", ["aichat", *args])
    elif operation == "code":
        os.environ["OPENCODE_CONFIG"] = str(CONFIG / "opencode.json")
        os.execvp("opencode", ["opencode", *args, "--standalone"])
    elif operation == "desktop":
        configure_desktop(model, key)
        subprocess.run(["/usr/bin/open", "-a", os.environ["STRATA_DESKTOP_APP"]], check=True)
    else:
        raise RuntimeError("Unknown qwen command.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, subprocess.CalledProcessError) as error:
        # Never echo captured subprocess output: a failed credential read may contain secrets.
        print(f"qwen: {error}", file=sys.stderr)
        sys.exit(1)
