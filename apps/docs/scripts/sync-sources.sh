#!/usr/bin/env bash
# Sync ValidusBot Lua LLM spec + local core library into apps/docs/scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPEC_URL="${SPEC_URL:-https://raw.githubusercontent.com/petkoGH/validusbot-lua/main/lua-llm-scripting-spec.md}"
SPEC_DEST="${SCRIPT_DIR}/lua-llm-scripting-spec.md"
CORE_DEST="${SCRIPT_DIR}/core"

# Prefer explicit override, then WSL path for the Windows ValidusBot install.
DEFAULT_CORE_SRC="/mnt/c/Users/olsza/AppData/Local/ValidusBot/Products/tibia/UserData/Scripts/core"
CORE_SRC="${CORE_SCRIPTS_DIR:-$DEFAULT_CORE_SRC}"

if [[ ! -d "$CORE_SRC" ]]; then
  echo "Core library not found: $CORE_SRC" >&2
  echo "Set CORE_SCRIPTS_DIR to the ValidusBot Scripts/core directory." >&2
  exit 1
fi

echo "Fetching spec from $SPEC_URL"
curl -fsSL "$SPEC_URL" -o "$SPEC_DEST.tmp"
mv "$SPEC_DEST.tmp" "$SPEC_DEST"

echo "Syncing core from $CORE_SRC -> $CORE_DEST"
mkdir -p "$CORE_DEST"
rsync -a --delete \
  --exclude '__pycache__/' \
  --exclude '*.pyc' \
  --exclude '.DS_Store' \
  "$CORE_SRC"/ "$CORE_DEST"/

echo "Spec:  $SPEC_DEST ($(wc -l < "$SPEC_DEST") lines)"
echo "Core:  $CORE_DEST ($(find "$CORE_DEST" -maxdepth 1 -name '*.lua' | wc -l) lua files)"
