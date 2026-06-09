#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$SCRIPT_DIR/build" "$SCRIPT_DIR/install" "$SCRIPT_DIR/src"
