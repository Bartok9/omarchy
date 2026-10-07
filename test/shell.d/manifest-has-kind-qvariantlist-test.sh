#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')

const qml = fs.readFileSync(path.join(root, 'shell/shell.qml'), 'utf8')

assert(
  /function kindsHas\(kinds, kind\)/.test(qml),
  'shell.qml defines kindsHas for duck-typed kind lists'
)
assert(
  /typeof kinds\.indexOf === "function"/.test(qml),
  'kindsHas accepts QVariantList-like objects that expose indexOf'
)
assert(
  /function manifestHasKind\(manifest, kind\) \{\s*return !!manifest && shell\.kindsHas\(manifest\.kinds, kind\)/.test(qml),
  'manifestHasKind delegates to kindsHas instead of Array.isArray'
)

function kindsHas(kinds, kind) {
  return !!kinds && typeof kinds.indexOf === 'function'
    && kinds.indexOf(kind) !== -1
}

function manifestHasKind(manifest, kind) {
  return !!manifest && kindsHas(manifest.kinds, kind)
}

assert(manifestHasKind({ kinds: ['menu', 'bar-widget'] }, 'menu'), 'plain JS array kinds still match')
assert(!manifestHasKind({ kinds: ['menu'] }, 'service'), 'plain JS array kinds still reject')

const qvariantList = {
  0: 'menu',
  1: 'bar-widget',
  length: 2,
  indexOf(kind) {
    for (let i = 0; i < this.length; i++) {
      if (this[i] === kind) return i
    }
    return -1
  }
}

assert(!Array.isArray(qvariantList), 'QVariantList stand-in is not a JS array')
assert(manifestHasKind({ kinds: qvariantList }, 'menu'), 'QVariantList-like kinds still match')
assert(!manifestHasKind({ kinds: qvariantList }, 'service'), 'QVariantList-like kinds still reject')
assert(!manifestHasKind(null, 'menu'), 'null manifest is not a match')
assert(!manifestHasKind({}, 'menu'), 'missing kinds is not a match')
JS
