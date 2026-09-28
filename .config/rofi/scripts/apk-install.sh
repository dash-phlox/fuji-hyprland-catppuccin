#!/usr/bin/env bash
#
# Fuji APK Installer
#

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/apk-install.log"
CACHE="/tmp/apk-cache.txt"
ASKPASS="$HOME/.config/rofi/scripts/rofi-askpass.sh"

rofi_menu() {
    rofi -dmenu -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-dialog-information}"
}

doas_rofi() {
    SUDO_ASKPASS="$ASKPASS" doas -A "$@"
}

auth_doas() {
    if ! doas -n true 2>/dev/null; then
        SUDO_ASKPASS="$ASKPASS" doas -A true 2>/dev/null
        if [ $? -ne 0 ]; then
            notify "󰌆  Auth Failed" "Wrong password or cancelled" "dialog-error"
            return 1
        fi
    fi
    return 1
}

pkg_info() {
    apk info "$1" 2>/dev/null | head -20
}

build_cache() {
    if [ ! -f "$CACHE" ] || [ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) )) -gt 600 ]; then
        apk search -q 2>/dev/null > "$CACHE"
    fi
}

_install() {
    auth_doas || return
    notify "󰄠  Installing" "$1 ..."
    (
        doas_rofi apk add "$1" > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  Installed" "$1 installed successfully" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_search() {
    QUERY=$(rofi -dmenu -p "󰍉 Search" -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$QUERY" ] && return

    notify "󰄠  Searching" "$QUERY ..."
    RESULTS=$(apk search "$QUERY" 2>/dev/null | awk '{print $1}')

    if [ -z "$RESULTS" ]; then
        notify "󰅙  Not Found" "No packages found for: $QUERY" "dialog-warning"
        return
    fi

    PKG=$(echo "$RESULTS" | rofi_menu "󰄠  Results")
    [ -z "$PKG" ] && return

    INFO=$(pkg_info "$PKG")
    CONFIRM=$(printf '%s\n%s' "Install $PKG" "Cancel" \
        | rofi -dmenu -p "󰄠  $PKG" -mesg "$INFO" -config "$ROFI_CONF/launcher-menu.rasi")

    [ "$CONFIRM" = "Install $PKG" ] && _install "$PKG"
}

do_browse() {
    build_cache

    if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
        notify "󰔟  Loading" "Building package list, please wait..."
        apk search -q 2>/dev/null > "$CACHE"
    fi

    PKG=$(cat "$CACHE" | rofi_menu "󰄠  Browse Packages")
    [ -z "$PKG" ] && return

    INFO=$(pkg_info "$PKG")
    CONFIRM=$(printf '%s\n%s' "Install $PKG" "Cancel" \
        | rofi -dmenu -p "󰄠  $PKG" -mesg "$INFO" -config "$ROFI_CONF/launcher-menu.rasi")

    [ "$CONFIRM" = "Install $PKG" ] && _install "$PKG"
}

do_multi() {
    build_cache

    if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
        notify "󰔟  Loading" "Building package list, please wait..."
        apk search -q 2>/dev/null > "$CACHE"
    fi

    SELECTED=""
    while true; do
        HEADER="Selected: ${SELECTED:-none}   |   Type 'DONE' to install · 'CLEAR' to reset"

        CHOICE=$(cat "$CACHE" | rofi -dmenu -p "󰄠  Multi-Install" \
            -mesg "$HEADER" \
            -config "$ROFI_CONF/launcher-menu.rasi")

        [ -z "$CHOICE" ] && break
        [ "$CHOICE" = "DONE" ]  && break
        [ "$CHOICE" = "CLEAR" ] && SELECTED="" && continue

        if echo "$SELECTED" | grep -qw "$CHOICE"; then
            SELECTED=$(echo "$SELECTED" | tr ' ' '\n' | grep -v "^$CHOICE$" | tr '\n' ' ' | xargs)
        else
            SELECTED=$(echo "$SELECTED $CHOICE" | xargs)
        fi
    done

    [ -z "$SELECTED" ] && return

    COUNT=$(echo "$SELECTED" | wc -w)
    CONFIRM=$(printf '%s\n%s' "Install $COUNT packages" "Cancel" \
        | rofi -dmenu -p "󰄠  Confirm" \
               -mesg "$(echo "$SELECTED" | tr ' ' '\n')" \
               -config "$ROFI_CONF/launcher-menu.rasi")

    if [ "$CONFIRM" = "Install $COUNT packages" ]; then
        auth_doas || return
        notify "󰄠  Installing" "$COUNT packages in background..."
        (
            doas_rofi apk add $SELECTED > "$LOG" 2>&1
            if [ $? -eq 0 ]; then
                notify "✓  Done" "$COUNT packages installed" "dialog-ok"
            else
                notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
            fi
        ) &
    fi
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No install log found" && return
    tail -30 "$LOG" | rofi -dmenu -p "󰋽  Install Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

# --- Main ---
build_cache &

CHOICE=$(printf '%s\n' "󰍉  Search & Install" "󰒿  Browse & Install" "󰏗  Multi Install" "󰋽  View Log" \
    | rofi_menu "󰄠  APK Install")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "󰍉  Search & Install") do_search   ;;
    "󰒿  Browse & Install") do_browse   ;;
    "󰏗  Multi Install")    do_multi    ;;
    "󰋽  View Log")         do_view_log ;;
esac
