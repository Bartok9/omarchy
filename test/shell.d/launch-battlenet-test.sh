#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
prefix="$test_tmp/Games/battlenet"
launcher="$prefix/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"
mkdir -p "$(dirname "$launcher")" "$mock_bin"
: >"$launcher"

cat >"$mock_bin/hyprctl" <<'SH'
#!/bin/bash
if [[ ${1:-} == clients ]]; then
  printf '%s\n' "${OMARCHY_TEST_CLIENTS_JSON:-[]}"
  exit 0
fi
if [[ ${1:-} == dispatch ]]; then
  printf 'focus:%s\n' "$*" >>"$OMARCHY_TEST_LOG"
  exit 0
fi
exit 0
SH

cat >"$mock_bin/jq" <<'SH'
#!/bin/bash
python3 -c 'import json,sys,re
clients=json.load(sys.stdin)
pat=re.compile(r"battle.?net", re.I)
for c in clients:
    cls=str(c.get("class") or "")
    title=str(c.get("title") or "")
    if pat.search(cls) or pat.search(title):
        print(c.get("address",""))
        break
'
SH

cat >"$mock_bin/pgrep" <<'SH'
#!/bin/bash
[[ ${OMARCHY_TEST_PGREP:-0} == 1 ]]
SH

cat >"$mock_bin/umu-run" <<'SH'
#!/bin/bash
printf 'launch:%s\n' "$*" >>"$OMARCHY_TEST_LOG"
SH

chmod +x "$mock_bin"/*

launch_log="$test_tmp/launch-log"
run_launch() {
  : >"$launch_log"
  HOME="$test_tmp" PATH="$mock_bin:$PATH" OMARCHY_TEST_LOG="$launch_log" \
    bash "$ROOT/bin/omarchy-launch-battlenet" "$@"
}

export OMARCHY_TEST_CLIENTS_JSON='[]'
export OMARCHY_TEST_PGREP=0
run_launch
grep -Fq 'launch:' "$launch_log" || fail "launcher starts umu-run when no Battle.net tree exists"
pass "launcher starts umu-run when no Battle.net tree exists"

export OMARCHY_TEST_CLIENTS_JSON='[{"class":"battle.net.exe","title":"Battle.net","address":"0xabc"}]'
export OMARCHY_TEST_PGREP=0
run_launch
grep -Fq 'focus:' "$launch_log" || fail "launcher focuses an existing Battle.net window"
grep -Fq 'launch:' "$launch_log" && fail "launcher must not stack umu-run when a window exists"
pass "launcher focuses an existing Battle.net window"

export OMARCHY_TEST_CLIENTS_JSON='[]'
export OMARCHY_TEST_PGREP=1
run_launch
grep -Fq 'launch:' "$launch_log" && fail "launcher must not stack umu-run when a headless tree exists"
pass "launcher refuses to stack a headless Battle.net tree"
