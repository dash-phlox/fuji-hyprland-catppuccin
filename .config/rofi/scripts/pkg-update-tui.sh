#!/usr/bin/env bash
#
# System Update - Arrow key selection TUI
#

LOG="/tmp/apk-update-tui.log"

RESET='\033[0m'
BOLD='\033[1m'
BG_SEL='\033[48;5;34m'
FG_SEL='\033[38;5;15m'
DIM='\033[2m'

# List raw upgrade lines from apk
list_updates_raw() {
  doas apk update >/dev/null 2>&1
  apk upgrade -s 2>/dev/null | grep 'Upgrading'
}

# Extract just the package names
list_update_names() {
  list_updates_raw | awk '{
    for (i = 1; i <= NF; i++)
      if ($i == "Upgrading") { print $(i+1); break }
  }'
}

# Initial update list
ALL_UPDATES=$(list_update_names)
TOTAL=$(echo "$ALL_UPDATES" | grep -c . 2>/dev/null || true)

fzf_args=(
  --multi
  --preview 'apk info {1} 2>/dev/null | head -20'
  --preview-label='alt-p: toggle preview | alt-j/k: scroll | tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:green,marker:green'
  --header 'Tab: multi-select | Enter: confirm | q: quit'
  --prompt '󰑓 Update: '
)

build_items() {
  ITEMS=(
    "  Update all   ($TOTAL available)"
    "  Select packages"
    "  Check available"
    "  Quit"
  )
  COUNT=${#ITEMS[@]}
}

draw_menu() {
  clear
  echo ""
  echo -e "  ${BOLD}󰑓  System Update${RESET}"
  echo "  ──────────────────────────────"
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

do_update_all() {
  clear
  if [[ "$TOTAL" -eq 0 ]]; then
    echo ""; echo "  ✓  System is already up to date!"
    echo ""; echo "  Press any key..."; read -n 1 -s; return
  fi
  read -rp "  Update all $TOTAL packages? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    doas apk upgrade 2>&1 | tee "$LOG"
    echo ""; echo "  ✓  Done! Press any key..."; read -n 1 -s
  fi
}

do_select_update() {
  clear
  if [[ "$TOTAL" -eq 0 ]]; then
    echo ""; echo "  ✓  No updates available!"
    sleep 2; return
  fi

  pkg_names=$(list_update_names | fzf "${fzf_args[@]}")
  if [[ -n "$pkg_names" ]]; then
    echo ""; echo "  Packages to update:"; echo "$pkg_names" | sed 's/^/    /'; echo ""
    read -rp "  Confirm update? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo ""
      echo "$pkg_names" | tr '\n' ' ' | xargs doas apk add -u 2>&1 | tee "$LOG"
      echo ""; echo "  ✓  Done! Press any key..."; read -n 1 -s
    fi
  fi
}

do_check() {
  clear; echo ""
  if [[ "$TOTAL" -eq 0 ]]; then
    echo "  ✓  System is already up to date!"
  else
    echo "  Available updates ($TOTAL):"; echo ""
    list_updates_raw | sed 's/^/  /'
  fi
  echo ""; echo "  Press any key..."; read -n 1 -s

  # Refresh counts after check
  ALL_UPDATES=$(list_update_names)
  TOTAL=$(echo "$ALL_UPDATES" | grep -c . 2>/dev/null || true)
  build_items
}

run_selection() {
  case $SELECTED in
    0) do_update_all ;;
    1) do_select_update ;;
    2) do_check ;;
    3) clear; exit 0 ;;
  esac
}

SELECTED=0
build_items

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
