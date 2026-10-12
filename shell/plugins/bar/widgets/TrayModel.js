function text(value) {
  return String(value || "").toLowerCase()
}

function itemNamed(item, name) {
  if (!item) return false
  return text(item.id).indexOf(name) !== -1
    || text(item.title).indexOf(name) !== -1
    || text(item.tooltipTitle).indexOf(name) !== -1
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (entry && typeof entry === "object") {
    var id = entry.id
    if (id !== undefined && id !== null && String(id) !== "") return String(id)
  }
  return ""
}

function layoutHasWidget(layout, id) {
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var entries = layout && layout[sections[s]]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      if (entryId(entries[i]) === id) return true
    }
  }
  return false
}

// LocalSend's item shows no state, offers only Open and Quit, and its primary
// click is a no-op, so Share > Receive is the whole surface. Hiding it by hand
// doesn't stick either: LocalSend picks a fresh tray id every launch.
function ownedByOmarchy(item, layout) {
  return itemNamed(item, "localsend")
    || (layoutHasWidget(layout, "omarchy.dropbox") && itemNamed(item, "dropbox"))
}

// Electron apps often share one StatusNotifier id (chrome_status_icon_1). Pin and
// hide must follow the icon the user clicked, so a label is part of the key when
// the title or tooltip distinguishes it. A stored bare id still matches when that
// id is not shared with another live item.
function itemLabel(item) {
  if (!item) return ""
  var title = String(item.title || "").replace(/[\r\n]/g, " ").trim()
  if (title) return title
  return String(item.tooltipTitle || "").replace(/[\r\n]/g, " ").trim()
}

function stateKey(item) {
  var id = String(item && item.id || "")
  var label = itemLabel(item)
  if (!id) return label
  if (!label || label === id) return id
  return id + "\n" + label
}

function appliesStored(keys, item, shared) {
  if (!Array.isArray(keys) || !item) return false
  var key = stateKey(item)
  if (keys.indexOf(key) !== -1) return true
  var id = String(item.id || "")
  return !shared && !!id && id !== key && keys.indexOf(id) !== -1
}

if (typeof module !== "undefined") {
  module.exports = {
    itemNamed: itemNamed,
    entryId: entryId,
    layoutHasWidget: layoutHasWidget,
    ownedByOmarchy: ownedByOmarchy,
    itemLabel: itemLabel,
    stateKey: stateKey,
    appliesStored: appliesStored
  }
}
