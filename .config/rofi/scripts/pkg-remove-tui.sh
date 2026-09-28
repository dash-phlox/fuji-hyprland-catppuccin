#!/usr/bin/env bash
#
# Package Removal - Arrow key selection TUI
#

LOG="/tmp/apk-remove-tui.log"

RESET='\033[0m'
BOLD='\033[1m'
BG_SEL='\033[48;5;160m'
FG_SEL='\033[38;5;15m'

ITEMS=(
  "  Remove package"
  "  Remove multiple"
  "  Quit"
)
SELECTED=0
COUNT=${#ITEMS[@]}

fzf_args=(
  --multi
  --preview 'apk info {1} 2>/dev/null | head -20'
  --preview-label='alt-p: toggle preview | alt-j/k: scroll | tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:red,marker:red'
  --header 'Tab: multi-select | Enter: confirm | q: quit'
  --prompt '󰗼 Remove: '
)

draw_menu() {
  clear
  echo ""
  echo -e "  ${BOLD}󰗼  Package Removal${RESET}"
  echo "  ──────────────────────────────"
  echo ""
  for i in "${!ITEMS[@]}"; do
    if [[ $i -eq $SELECTED ]]; then
      echo -e "  ${BG_SEL}${FG_SEL}  ${ITEMS[$i]}  ${RESET}"
    else
      echo "     ${ITEMS[$i]}"
    fi
  done
  echo ""
  echo "  ──────────────────────────────"
  echo "  ↑↓ Navigate   Enter Select   q Quit"
}

read_key() {
  IFS= read -rsn1 key
  if [[ $key == $'\x1b' ]]; then
    read -rsn2 -t 0.1 seq
    key+="$seq"
  fi
  echo "$key"
}

do_remove() {
  clear
  pkg_names=$(apk info -q | fzf "${fzf_args[@]}")
  if [[ -n "$pkg_names" ]]; then
    echo ""
    echo "  Packages to remove:"
    echo "$pkg_names" | sed 's/^/    /'
    echo ""
    read -rp "  Confirm removal? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo ""
      echo "$pkg_names" | tr '\n' ' ' | xargs doas apk del 2>&1 | tee "$LOG"
      echo ""
      echo "  ✓  Done! Press any key to continue..."
      read -n 1 -s
    fi
  fi
}

do_remove_multi() {
  clear
  fzf_multi_args=("${fzf_args[@]}")
  fzf_multi_args+=(--header 'Multi-select packages | Tab: select | Enter: confirm')
  pkg_names=$(apk info -q | fzf "${fzf_multi_args[@]}")
  if [[ -n "$pkg_names" ]]; then
    echo ""
    echo "  Packages to remove:"
    echo "$pkg_names" | sed 's/^/    /'
    echo ""
    read -rp "  Confirm removal? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo ""
      echo "$pkg_names" | tr '\n' ' ' | xargs doas apk del 2>&1 | tee "$LOG"
      echo ""
      echo "  ✓  Done! Press any key to continue..."
      read -n 1 -s
    fi
  fi
}

run_selection() {
  case $SELECTED in
    0) do_remove ;;
    1) do_remove_multi ;;
    2) clear; exit 0 ;;
  esac
}

while true; do
  draw_menu
  KEY=$(read_key)
  case "$KEY" in
    $'\x1b[A'|k)
      (( SELECTED = (SELECTED - 1 + COUNT) % COUNT )) ;;
    $'\x1b[B'|j)
      (( SELECTED = (SELECTED + 1) % COUNT )) ;;
    '')
      run_selection ;;
    q|Q)
      clear; exit 0 ;;
  esac
done
