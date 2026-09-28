#!/usr/bin/env bash

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/apk-remove.log"
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

pkg_info() {
    apk info "$1" 2>/dev/null | head -10
}

main_menu() {
    printf '%s\n' "Remove package" "Remove multiple" "View remove log" \
    | rofi_menu "󰗼  Remove"
}

do_remove() {
    PKG=$(apk info -q | rofi_menu "󰗼  Select package")
    [ -z "$PKG" ] && return
    INFO=$(pkg_info "$PKG")
    CONFIRM=$(printf '%s\n%s' "Remove $PKG" "Cancel" \
        | rofi -dmenu -p "󰗼  $PKG" -mesg "$INFO" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Remove $PKG" ] && return
    _remove "$PKG"
}

do_remove_multi() {
    SELECTED=""
    while true; do
        HEADER="Selected: ${SELECTED:-none}   |   Type 'DONE' to remove · 'CLEAR' to reset"
        CHOICE=$(apk info -q | rofi -dmenu -p "󰗼  Multi-Remove" \
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
    CONFIRM=$(printf '%s\n%s' "Remove $COUNT packages" "Cancel" \
        | rofi -dmenu -p "󰗼  Confirm" \
               -mesg "$(echo "$SELECTED" | tr ' ' '\n')" \
               -config "$ROFI_CONF/launcher-menu.rasi")
    if [ "$CONFIRM" = "Remove $COUNT packages" ]; then
        notify "󰗼  Removing" "$COUNT packages ..."
        (
            priv apk del $SELECTED > "$LOG" 2>&1
            if [ $? -eq 0 ]; then
                notify "✓  Removed" "$COUNT packages removed" "dialog-ok"
            else
                notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
            fi
        ) &
    fi
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No remove log found" && return
    tail -30 "$LOG" | rofi -dmenu -p "󰋽  Remove Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

_remove() {
    notify "󰗼  Removing" "$1 ..."
    (
        priv apk del "$1" > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  Removed" "$1 removed" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

CHOICE=$(main_menu)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "Remove package")  do_remove       ;;
    "Remove multiple") do_remove_multi ;;
    "View remove log") do_view_log     ;;
esac
