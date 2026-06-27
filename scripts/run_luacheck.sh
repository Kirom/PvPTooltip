#!/bin/bash

echo "============================"
echo "PvP Profile Linter"
echo "============================"

# Check if luacheck exists.
# Note: Depending on your installation and environment (like Git Bash),
# the executable might be named 'luacheck' without the .exe extension.
# This script checks for 'luacheck' first, and then 'luacheck.exe'.
if command -v luacheck &> /dev/null; then
    LUACHECK_CMD="luacheck"
elif [ -f luacheck.exe ]; then
    LUACHECK_CMD="./luacheck.exe"
else
    echo "ERROR: luacheck executable not found. Please ensure 'luacheck' is in your PATH or 'luacheck.exe' is in the current directory."
    exit 1
fi


# Run luacheck on all Lua files
echo "Running luacheck on addon files..."
"$LUACHECK_CMD" src/*.lua src/providers/*.lua src/db/*.lua --config .luacheckrc

# Capture the exit code of the luacheck command
EXIT_CODE=$?

echo "============================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "Lint check completed successfully."
else
    echo "Lint check completed with errors. See above for details."
fi
echo "============================"