#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command mogrify
require_command magick

helper="$ROOT/bin/omarchy-imv-rotate"
[[ -x $helper ]] || fail "omarchy-imv-rotate is executable"

grep -Fq 'omarchy-imv-rotate "$imv_current_file"' "$ROOT/config/imv/config" ||
  fail "stock imv config uses the atomic rotate helper"
! grep -Fq 'mogrify -rotate 90 "$imv_current_file"' "$ROOT/config/imv/config" ||
  fail "stock imv config no longer rotates with in-place mogrify"
pass "stock imv Ctrl+R uses omarchy-imv-rotate"

grep -Fq 'omarchy-imv-rotate "$imv_current_file"' "$ROOT/migrations/1791577200.sh" ||
  fail "the migration rewrites the stock mogrify rotate binding"
pass "migration rewrites the stock imv rotate binding"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

src="$test_tmp/photo.jpg"
magick -size 32x16 xc:red "$src"
orig_size=$(wc -c <"$src")
[[ $orig_size -gt 0 ]] || fail "fixture JPEG has content"

"$helper" "$src"
identify_out=$(magick identify -format '%wx%h' "$src")
[[ $identify_out == 16x32 ]] || fail "rotate swaps dimensions" "$identify_out"
magick identify "$src" >/dev/null || fail "rotated JPEG still decodes"
pass "successful rotate replaces the original with a valid image"

src2="$test_tmp/photo2.jpg"
magick -size 48x24 xc:blue "$src2"
before=$(wc -c <"$src2")
PATH="/usr/bin:/bin" command -v true >/dev/null
# Simulate interrupted mogrify by replacing mogrify with a truncating stub
stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"
cat >"$stub_bin/mogrify" <<'SH'
#!/bin/bash
# Truncate the target like an interrupted in-place write, then fail.
target=${!#}
: >"$target"
exit 1
SH
chmod +x "$stub_bin/mogrify"
if PATH="$stub_bin:$PATH" "$helper" "$src2"; then
  fail "helper should fail when mogrify fails"
fi
after=$(wc -c <"$src2")
[[ $after == "$before" ]] || fail "failed rotate leaves the original intact" "before=$before after=$after"
magick identify "$src2" >/dev/null || fail "original still decodes after failed rotate"
pass "failed rotate does not truncate the original"
