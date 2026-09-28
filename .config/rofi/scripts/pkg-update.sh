#!/usr/bin/env bash

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/apk-update.log"
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

refresh_index() {
    priv apk update >/dev/null 2>&1
}

list_updates_raw() {
    apk upgrade -s 2>/dev/null
}

list_update_names() {
    apk upgrade -s 2>/dev/null | awk '{
        for (i = 1; i <= NF; i++)
            if ($i == "Upgrading") { print $(i+1); break }
    }'
}

main_menu() {
    refresh_index
    UPDATES=$(list_updates_raw | grep -c '.')
    printf '%s\n' "Update all ($UPDATES available)" "Select packages to update" "Check updates" "View update log" \
    | rofi_menu "󰑓  Update"
}

do_update_all() {
    refresh_index
    UPDATES=$(list_updates_raw)
    COUNT=$(echo "$UPDATES" | grep -c "." 2>/dev/null || echo 0)
    if [ "$COUNT" -eq 0 ] || [ -z "$UPDATES" ]; then
        notify "✓  Up to date" "System is already up to date" "dialog-ok"
        return
    fi
    PREVIEW=$(echo "$UPDATES" | head -8)
    CONFIRM=$(printf '%s\n%s' "Yes, update all" "No, cancel" \
        | rofi -dmenu -p "󰑓  Update $COUNT packages?" -mesg "$PREVIEW" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Yes, update all" ] && return
    notify "󰑓  Updating" "$COUNT packages in background..."
    (
        priv apk upgrade > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  Updated" "$COUNT packages updated" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_select_update() {
    refresh_index
    ALL_UPDATES=$(list_update_names)
    [ -z "$ALL_UPDATES" ] && notify "✓  Up to date" "No updates available" "dialog-ok" && return

    SELECTED=""
    while true; do
        HEADER="Selected: ${SELECTED:-none}   |   Type 'DONE' to update · 'CLEAR' to reset"
        CHOICE=$(echo "$ALL_UPDATES" | rofi -dmenu -p "󰑓  Select updates" \
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
    notify "󰑓  Updating" "$COUNT packages ..."
    (
        priv apk add -u $SELECTED > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  Updated" "$COUNT packages updated" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_check_updates() {
    notify "󰑓  Checking" "Looking for updates..."
    refresh_index
    UPDATES=$(list_updates_raw)
    if [ -z "$UPDATES" ]; then
        notify "✓  Up to date" "No updates available" "dialog-ok"
        return
    fi
    COUNT=$(echo "$UPDATES" | grep -c '.')
    HEADER="Total: $COUNT packages available"
    echo "$UPDATES" | rofi -dmenu -p "󰑓  Available updates" -no-custom -mesg "$HEADER" -config "$ROFI_CONF/launcher-menu.rasi"
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No update log found" && return
    tail -40 "$LOG" | rofi -dmenu -p "󰋽  Update Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

CHOICE=$(main_menu)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    Update\ all*)                do_update_all    ;;
    "Select packages to update") do_select_update ;;
    "Check updates")             do_check_updates ;;
    "View update log")           do_view_log      ;;
esac
