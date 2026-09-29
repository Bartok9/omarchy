echo "Restore missing mise stubs from the canonical install list"

# 1784909971.sh rewrote wrappers by walking ~/.local/bin. Once that directory
# is empty the glob matches nothing, so later updates never recreate gh and
# the other documented lazy stubs.

mise_leaf="${OMARCHY_PATH:-/usr/share/omarchy}/install/user/mise.sh"
[[ -f $mise_leaf ]] || return 0

mise() { :; }

omarchy-mise-install() {
  local command=${2:-$1}

  if [[ -f $HOME/.local/state/omarchy/preinstalls-removed ]]; then
    case "$command" in
      hey | basecamp | cf)
        return 0
        ;;
    esac
  fi

  command omarchy-mise-install "$@"
}

# shellcheck disable=SC1090
source "$mise_leaf"
