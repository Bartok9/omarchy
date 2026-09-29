#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

migration="$ROOT/migrations/1790712217.sh"
[[ -f $migration ]] || fail "the restore migration is present"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

home="$tmpdir/home"
mkdir -p "$home/.local/bin" "$home/.local/state/omarchy"

run() {
  env HOME="$home" OMARCHY_PATH="$ROOT" PATH="$ROOT/bin:$PATH" \
    bash -euo pipefail "$migration"
}

run
[[ -x $home/.local/bin/gh ]] || fail "an empty ~/.local/bin gets the gh stub back"
[[ -x $home/.local/bin/codex ]] || fail "an empty ~/.local/bin gets the other canonical stubs"
pass "wiping ~/.local/bin restores gh from the canonical list"

run
[[ -x $home/.local/bin/gh ]] || fail "a second run still leaves gh"
pass "the restore is idempotent"

touch "$home/.local/state/omarchy/preinstalls-removed"
rm -f "$home/.local/bin/"*
run
[[ -x $home/.local/bin/gh ]] || fail "preinstalls-removed still restores gh"
[[ ! -e $home/.local/bin/hey ]] || fail "preinstalls-removed does not restore hey"
[[ ! -e $home/.local/bin/basecamp ]] || fail "preinstalls-removed does not restore basecamp"
[[ ! -e $home/.local/bin/cf ]] || fail "preinstalls-removed does not restore cf"
pass "removed preinstalls stay removed"
