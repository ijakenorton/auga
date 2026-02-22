#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD="$SCRIPT_DIR/build"
TOOLS="$SCRIPT_DIR/tools/linux"

mkdir -p "$BUILD"

if command -v clang >/dev/null 2>&1; then
    CC="clang"
elif command -v gcc >/dev/null 2>&1; then
    CC="gcc"
elif command -v cc >/dev/null 2>&1; then
    CC="cc"
elif [ -x "$TOOLS/tcc" ]; then
    CC="$TOOLS/tcc -B $TOOLS"
    echo "No system compiler found, using bundled tcc"
else
    echo "Error: no C compiler found and bundled tcc is missing" >&2
    exit 1
fi

echo "CC: $CC"
$CC -Wall -Wextra -o "$BUILD/auga" "$SCRIPT_DIR/auga.c"
echo "Built: $BUILD/auga"
