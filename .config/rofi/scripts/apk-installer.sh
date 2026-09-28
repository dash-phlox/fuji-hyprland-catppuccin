#!/bin/bash
# Fuzzy-finder for installing packages from Alpine APK repos

fzf_args=(
  --multi
  --preview 'apk info {1} 2>/dev/null'
  --preview-label='alt-p: toggle preview, alt-j/k: scroll, tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:green,marker:green'
  --header 'Package Installer - Select with Tab, Enter to install'
  --prompt 'Package: '
)

pkg_names=$(apk search -q | fzf "${fzf_args[@]}")

if [[ -n "$pkg_names" ]]; then
  echo "$pkg_names" | tr '\n' ' ' | xargs doas apk add

  # Update package index in the background
  if command -v apk &>/dev/null; then
    doas apk update &
  fi

  echo
  gum spin --spinner "globe" --title "Done! Press any key to close..." -- bash -c 'read -n 1 -s'
fi
