#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_PATH="${1:-$ROOT_DIR/input.md}"

"$ROOT_DIR/master.sh" "$INPUT_PATH"
