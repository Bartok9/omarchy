#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test "tray model helpers" <<'JS'
const tray = requireFromRoot('shell/plugins/bar/widgets/TrayModel.js')

assert(tray.itemNamed({ id: 'dropbox-client' }, 'dropbox'), 'tray matches item ids')
assert(tray.itemNamed({ title: 'Dropbox' }, 'dropbox'), 'tray matches item titles')
assert(tray.itemNamed({ tooltipTitle: 'LocalSend' }, 'localsend'), 'tray matches item tooltips')
assert(!tray.itemNamed({ id: 'nextcloud' }, 'dropbox'), 'tray ignores items named for something else')

const layout = {
  left: [{ id: 'omarchy.menu' }],
  center: [],
  right: [{ id: 'omarchy.dropbox' }, { id: 'omarchy.tray' }]
}

assert(tray.layoutHasWidget(layout, 'omarchy.dropbox'), 'tray finds dedicated dropbox widget in layout')
assert(tray.ownedByOmarchy({ id: 'dropbox' }, layout), 'tray suppresses dropbox when dedicated widget is in bar')
assert(!tray.ownedByOmarchy({ id: 'dropbox' }, { left: [], center: [], right: [] }), 'tray keeps dropbox when dedicated widget is absent')
assert(tray.ownedByOmarchy({ id: 'qlBCprNUqU', title: 'localsend' }, { left: [], center: [], right: [] }), 'tray suppresses localsend regardless of layout')
assert(!tray.ownedByOmarchy({ id: 'nextcloud' }, layout), 'tray keeps unrelated tray items')

const chromeA = { id: 'chrome_status_icon_1', title: '', tooltipTitle: 'LM Studio' }
const chromeB = { id: 'chrome_status_icon_1', title: '', tooltipTitle: 'ChatGPT' }
const dropbox = { id: 'dropbox', title: 'Dropbox', tooltipTitle: 'Dropbox' }

assertEqual(tray.stateKey(chromeA), 'chrome_status_icon_1\nLM Studio', 'tray keys a colliding electron icon by tooltip')
assert(tray.stateKey(chromeA) !== tray.stateKey(chromeB), 'tray gives colliding electron icons different keys')
assertEqual(tray.stateKey(dropbox), 'dropbox\nDropbox', 'tray keeps a label on a unique id')
assertEqual(tray.stateKey({ id: 'solo' }), 'solo', 'tray keeps a bare id when the icon has no label')
assert(tray.appliesStored(['chrome_status_icon_1'], chromeA, false), 'tray still honors a stored bare id when the id is unique')
assert(!tray.appliesStored(['chrome_status_icon_1'], chromeA, true), 'tray does not apply a shared bare id to every colliding icon')
assert(tray.appliesStored([tray.stateKey(chromeB)], chromeB, true), 'tray applies a stored per-icon key while the id is shared')
assert(!tray.appliesStored([tray.stateKey(chromeA)], chromeB, true), 'tray does not pin the other colliding icon')
JS