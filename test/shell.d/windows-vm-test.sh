#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

windows_vm_command="$ROOT/bin/omarchy-windows-vm"
windows_vm_rules="$ROOT/default/hypr/apps/windows-vm.lua"

rg -q '^    restart: "no"$' "$windows_vm_command" ||
  fail "Windows VM uses manual startup by default"
pass "Windows VM uses manual startup by default"

if rg -q '^    restart: unless-stopped$' "$windows_vm_command"; then
  fail "Windows VM does not restart automatically at boot"
fi
pass "Windows VM does not restart automatically at boot"

# Tolerate either shell quoting of the argument -- what must not drift is the
# title itself, since the Hyprland rule below matches on it.
rg -q 'title:"?Windows VM - Omarchy"' "$windows_vm_command" ||
  fail "Windows VM launches FreeRDP with its expected title"
rg -q 'class = "\^xfreerdp\$", title = "\^Windows VM - Omarchy\$"' "$windows_vm_rules" ||
  fail "Windows VM opacity rule targets its FreeRDP window"
rg -q 'tag = "-default-opacity"' "$windows_vm_rules" ||
  fail "Windows VM opts out of default opacity"
rg -q 'opacity = "1 1"' "$windows_vm_rules" ||
  fail "Windows VM stays fully opaque"
pass "Windows VM stays fully opaque"

# dockurr/windows sets the setgid bit on ~/Windows (2700/2777). GNU chmod keeps
# that bit for 0700 and 00700, so the mode-700 preflight refused every relaunch.
rg -q 'chmod u=rwx,go=,g-s -- "/proc/\$BASHPID/fd/\$storage_fd"' "$windows_vm_command" ||
  fail "Windows VM clears setgid when hardening pinned mount sources"
rg -q 'chmod u=rwx,go=,g-s -- "\$storage" "\$shared"' "$windows_vm_command" ||
  fail "Windows VM clears setgid on the user shared directory"
pass "Windows VM clears setgid on the shared directory"
