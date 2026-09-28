#!/usr/bin/env bash

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/apk-install.log"
CACHE="/tmp/apk-pkg-cache.txt"
ASKPASS="$HOME/.config/rofi/scripts/rofi-askpass.sh"

rofi_menu() {
    rofi -dmenu -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-dialog-information}"
}

if doas -n true 2>/dev/null; then
    PRIV=(doas -n)
elif [ -x "$ASKPASS" ] && command -v sudo >/dev/null 2>&1; then
    PRIV=(env SUDO_ASKPASS="$ASKPASS" sudo -A)
else
    notify "󰌆  Auth Failed" \
        "Neither passwordless doas nor sudo+askpass is available" \
        "dialog-error"
    exit 1
fi

priv() { "${PRIV[@]}" "$@"; }

build_cache() {
    if [ ! -f "$CACHE" ] || [ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) )) -gt 600 ]; then
        apk search -q 2>/dev/null > "$CACHE" &
    fi
}

pkg_info() {
    apk info "$1" 2>/dev/null | head -20
}

main_menu() {
    printf '%s\n' "Search & Install" "Install from list" "Install multiple" "Reinstall package" "View install log" \
    | rofi_menu "󰄠  Install"
}

do_search_install() {
    QUERY=$(rofi -dmenu -p "Search package" -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$QUERY" ] && return
    notify "󰄠  Searching" "$QUERY ..."
    RESULTS=$(apk search "$QUERY" 2>/dev/null | awk '{print $1}')
    [ -z "$RESULTS" ] && notify "󰅙 Not found" "No packages found for: $QUERY" "dialog-warning" && return
    PKG=$(echo "$RESULTS" | rofi_menu "Select package")
    [ -z "$PKG" ] && return
    INFO=$(pkg_info "$PKG")
    CONFIRM=$(printf '%s\n' "Install $PKG" "--- Info ---" "$INFO" "Cancel" | rofi_menu "󰄠  $PKG")
    [ "$CONFIRM" != "Install $PKG" ] && return
    _install "$PKG"
}

do_list_install() {
    build_cache
    if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
        notify "󰔟  Loading" "Building package list, try again in a moment..."
        apk search -q 2>/dev/null > "$CACHE"
    fi
    PKG=$(cat "$CACHE" | rofi_menu "󰄠  Choose package")
    [ -z "$PKG" ] && return
    INFO=$(pkg_info "$PKG")
    CONFIRM=$(printf '%s\n' "Install $PKG" "Cancel" | rofi -dmenu -p "󰄠  $PKG" -mesg "$INFO" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Install $PKG" ] && return
    _install "$PKG"
}

do_multi_install() {
    PKGS=$(rofi -dmenu -p "Packages (space separated)" -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$PKGS" ] && return
    COUNT=$(echo "$PKGS" | wc -w)
    CONFIRM=$(printf 'Yes, install %s packages\nNo, cancel' "$COUNT" | rofi_menu "󰄠  Install: $PKGS")
    [[ "$CONFIRM" != Yes* ]] && return
    notify "󰄠  Installing" "$COUNT packages in background..."
    (
        priv apk add $PKGS >"$LOG" 2>&1
        [ $? -eq 0 ] && notify "✓  Done" "$COUNT packages installed" "dialog-ok" \
                      || notify "✗  Failed" "$(tail -3 $LOG)" "dialog-error"
    ) &
}

do_reinstall() {
    PKG=$(apk info -q | rofi_menu "󰑓  Reinstall")
    [ -z "$PKG" ] && return
    notify "󰑓  Reinstalling" "$PKG ..."
    ( priv apk add "$PKG" >"$LOG" 2>&1
      [ $? -eq 0 ] && notify "✓  Reinstalled" "$PKG" "dialog-ok" \
                    || notify "✗  Failed" "$(tail -3 $LOG)" "dialog-error" ) &
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No install log found" && return
    tail -30 "$LOG" | rofi -dmenu -p "󰋽  Install Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

_install() {
    notify "󰄠  Installing" "$1 ..."
    ( priv apk add "$1" >"$LOG" 2>&1
      [ $? -eq 0 ] && notify "✓  Installed" "$1 installed successfully" "dialog-ok" \
                    || notify "✗  Failed" "$(tail -3 $LOG)" "dialog-error" ) &
}

build_cache

CHOICE=$(main_menu)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "Search & Install")  do_search_install ;;
    "Install from list") do_list_install   ;;
    "Install multiple")  do_multi_install  ;;
    "Reinstall package") do_reinstall      ;;
    "View install log")  do_view_log       ;;
esac
