#!/bin/sh
# Cross-platform launcher for the SDD validator self-tests.
# Delegates to the PowerShell source of truth so validation logic is never duplicated.
set -e
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if command -v pwsh >/dev/null 2>&1; then
    ps_shell="pwsh"
elif command -v powershell >/dev/null 2>&1; then
    ps_shell="powershell"
else
    echo "PowerShell (pwsh or powershell) is required. See https://aka.ms/powershell for installation." >&2
    exit 1
fi
exec "$ps_shell" -ExecutionPolicy Bypass -File "$script_dir/test-validators.ps1" "$@"
