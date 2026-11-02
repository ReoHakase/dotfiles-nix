#!/usr/bin/env bash
# Used by the Home Manager strata-qwen-setup command. Large downloads are explicit.
set -euo pipefail
umask 077

operation="${1:-prepare}"
family="nvfp4"
model="NVFP4"
case "$operation" in
  install | prepare) ;;
  iq3_s) family="qwen"; model="IQ3_S" ;;
  *) echo "Usage: strata-qwen-setup [install|prepare|iq3_s]" >&2; exit 2 ;;
esac

: "${STRATA_INSTALLER:?Use the Home Manager strata-qwen-setup command}"
: "${STRATA_FEED:?Missing pinned release feed}"
: "${STRATA_VECTOR:?Missing pinned control vector}"
strata_bin="$HOME/.local/bin/strata"
if [[ "$operation" == install || ! -x "$strata_bin" ]]; then
  sh "$STRATA_INSTALLER"
fi
if [[ "$operation" == install ]]; then
  exec "$strata_bin" --version
fi

if ! nvidia-smi --query-gpu=name,memory.total --format=csv; then
  echo "GPU unavailable. Repair the Ubuntu NVIDIA kernel modules first; see docs/strata.md." >&2
  exit 1
fi

# The API key never appears in process arguments or in the repository.
key_dir="${XDG_CONFIG_HOME:-$HOME/.config}/strata-kcvl"
mkdir -p "$key_dir"
chmod 700 "$key_dir"
python3 - "$key_dir/api-key" <<'PY'
import os, pathlib, secrets, sys
p = pathlib.Path(sys.argv[1])
if not p.exists():
    fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(secrets.token_hex(32) + "\n")
os.chmod(p, 0o600)
PY
STRATA_API_KEY="$(cat "$key_dir/api-key")"
export STRATA_API_KEY

# Stop only our service/profile before re-preparing or changing model size.
systemctl --user stop strata-qwen.service
"$strata_bin" launch --preset kcvl-qwen --stop
result_file="$(mktemp)"
trap 'rm -f "$result_file"' EXIT
"$strata_bin" launch --family "$family" --model "$model" \
  --context 32k --parallel 1 --vision off --access local --port 8080 \
  --api-key-env STRATA_API_KEY --save-preset kcvl-qwen --yes --no-tui --feed "$STRATA_FEED" \
  --set "control-vector-scaled=$STRATA_VECTOR:1.0" \
  --set 'control-vector-layer-range=4 44' --set cvec-mode=project --set cvec-dir=per-layer \
  --output json > "$result_file"
"$strata_bin" launch --preset kcvl-qwen --stop
"$strata_bin" profile show launch-kcvl-qwen --output json > "$result_file"

# Persist the projection through setup/app rewrites using Strata's supported user_args.
python3 - "$result_file" "$STRATA_VECTOR" <<'PY'
import json, os, pathlib, sys, tempfile
result = json.loads(pathlib.Path(sys.argv[1]).read_text())
path = pathlib.Path(result["profile"]["source_config"])
cfg = json.loads(path.read_text())
projection = ["--control-vector-scaled", sys.argv[2] + ":1.0",
    "--control-vector-layer-range", "4", "44", "--cvec-mode", "project", "--cvec-dir", "per-layer"]
flags = {token for token in projection if token.startswith("--")}
groups = []
for token in cfg.get("user_args", []):
    if token.startswith("--") or not groups:
        groups.append([token])
    else:
        groups[-1].append(token)
cfg["user_args"] = [token for group in groups if group[0] not in flags for token in group] + projection
cfg.setdefault("sampling", {})["experimental_speed_projection"] = True
fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=".qwen-")
with os.fdopen(fd, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
PY
systemctl --user daemon-reload
echo "Prepared $family/$model. Model is stopped. Start from the Mac with qwen-start."
