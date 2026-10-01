# Fuji - Hyprland Catppuccin

![Screenshot](Pictures/Screenshots/1.png)

A Hyprland configuration for Fuji Linux with a Catppuccin-based theme system and integrations tailored for Fuji Linux.

## 🖥️ Components

| Component | Tool |
|-----------|------|
| Compositor | Hyprland |
| Bar | Waybar |
| Launcher | Rofi (wayland) |
| Terminal | Kitty |
| Notifications | SwayNC |
| Wallpaper | awww |
| Lock Screen | Hyprlock + Hypridle |
| File Manager | Nautilus |
| Clipboard | cliphist |
| Image Viewer | qView |

## ✨ Features

### 🎨 Theme System
Change the theme with one click from **Menu → Style** — applies instantly to:
- btop
- Hyprland
- Kitty
- Rofi
- SwayNC
- Waybar

**Available themes:**
- Catppuccin Mocha
- Catppuccin Frappe
- Catppuccin Macchiato
- Catppuccin Latte

### 󰸉 Wallpaper Menu (`Super + I`)

| Option | Function |
|--------|----------|
| 󰸉 Desktop Wallpaper | Change desktop wallpaper + lock screen together |
| 󰷛 Lock Screen Wallpaper | Change lock screen wallpaper only |
| 󰑓 Random Wallpaper | Set a random wallpaper |
| 󰹑 Set per Monitor | Set different wallpaper per monitor |
| 󰋩 Open Wallpaper Folder | Open wallpapers folder |

> Wallpapers are read from `~/Pictures/Wallpapers` with thumbnail previews.

### 󰅍 Clipboard (`Super + V`)

- **Text** → Classic rofi interface
- **Images** → Shown as thumbnails with preview
- **Mixed** → Asks first: text or images?

### 󰷛 Lock Screen (`Super + Shift + Backspace`)

- Uses your last selected wallpaper as the background
- Time and date displayed in the middle
- Bullet-masked password prompt
- Mouse cursor remains visible

### 󰀻 Rofi Main Menu

| Option | Function |
|--------|----------|
| 󰕰 Apps | Full app launcher with icons |
| 󰒓 Style | Change theme for all apps |
| 󰄠 Install | Install packages |
| 󰗼 Remove | Remove packages |
| 󰑓 Update | Update system |
| ⏻ System | Lock · Logout · Suspend · Reboot · Shutdown |

## ⚙️ Installation

### Fuji Linux

On Fuji Linux, this configuration can be installed directly through the desktop selection during system setup.

Select:

```
hyprland-catppuccin
```

from the `Desktop Environment / Window Manager` selection.

Fuji Linux will automatically install the required packages, configuration files, themes, fonts, and supporting components needed for the Catppuccin-themed Hyprland desktop.

### Alpine Linux

The configuration can also be installed on Alpine Linux.

However, some of its dependencies are not available in Alpine's standard repositories, including packages such as:
```
grimblast
hyprland-guiutils
qview
```

Alpine users should therefore **enable the [Fuji Linux repository](https://github.com/dash-phlox/fuji-repo) first** so that all required dependencies can be installed.

Once the Fuji repository is enabled, follow the manual installation instructions below.

### Manual

If you are installing the configuration outside of Fuji Linux, clone the repository and copy the configuration files manually:

```sh
git clone https://github.com/dash-phlox/fuji-hyprland-catppuccin config

cp -r config/.config/* ~/.config
cp -r config/.local/* ~/.local
cp -r config/Pictures/Wallpapers ~/Pictures

rm -rf config
```

> Manual installation does not automatically install the required dependencies. See the [Dependencies](#-dependencies) section above and make sure the required packages are installed before starting Hyprland.

## 📦 Dependencies

### Core
```
hyprland hyprlock hypridle hyprsunset hyprpicker
xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
xwayland wayland-protocols grim slurp awww swaync
wl-clipboard cliphist imagemagick polkit-gnome dbus
udiskie
```

### Audio
```
pipewire pipewire-pulse pipewire-alsa wireplumber
pamixer pavucontrol playerctl python-gobject
```

### Network
```
networkmanager nm-connection-editor bluez bluez-utils rfkill
```

### UI
```
waybar rofi-wayland rofi-calc rofi-emoji
brightnessctl upower jq curl fzf libnotify
```

### Applications
```
kitty neovim nautilus firefox btop
```

### Fonts & Icons
```
font-jetbrains-mono-nerd font-commit-mono-nerd
font-noto font-noto-emoji otf-font-awesome
papirus-icon-theme simp1e-cursors-catppuccin-mocha
```

## ⌨️ Keybindings

> `$mod` = Super

### Menus

| Shortcut | Action |
|----------|--------|
| `Super + A` | App launcher |
| `Super + V` | Clipboard |
| `Super + X` | Calculator |
| `Super + M` | Emoji picker |
| `Super + W` | Window switcher |
| `Super + I` | Wallpaper menu |
| `Super + P` | Now Playing |

### Applications

| Shortcut | Action |
|----------|--------|
| `Super + T` | Terminal (Kitty) |
| `Super + C` | Code editor (Neovim) |
| `Super + E` | File manager (Nautilus) |
| `Super + F` | Browser (Firefox) |
| `Super + Shift + F` | Browser private window |
| `Super + Shift + N` | Toggle notifications |

### Screenshots

| Shortcut | Action |
|----------|--------|
| `Print` | Selected area |
| `Super + Print` | Full screen |
| `Super + Alt + Print` | Active window |

### Audio

| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute |
| `XF86AudioMicMute` | Mute microphone |
| `Super + Alt + R/L` | Volume up/down |
| `Super + Alt + M` | Mute |
| `XF86AudioPlay/Next/Prev` | Media control |

### Brightness

| Shortcut | Action |
|----------|--------|
| `XF86MonBrightnessUp/Down` | Brightness up/down |
| `Super + Alt + U/D` | Brightness up/down |

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + Q` | Close window |
| `Super + Return` | Fullscreen |
| `Super + Shift + W` | Float window |
| `Super + \` | Next window |
| `Super + H/J/K/L` | Move focus |
| `Super + Arrows` | Move focus |
| `Super + Shift + H/J/K/L` | Resize |
| `Super + S` | Special workspace |
| `Super + Shift + Drag` | Drag window |
| `Super + Right Click` | Resize with mouse |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Alt + 1-0` | Silent move |
| `Super + Ctrl + Left/Right` | Previous/Next workspace |
| `Super + Ctrl + H/L` | Previous/Next workspace |
| `Super + Ctrl + Down/J` | First empty workspace |

### System

| Shortcut | Action |
|----------|--------|
| `Super + Shift + Backspace` | Lock screen |
| `Super + Ctrl + W` | Restart Waybar |
| `Super + Alt + B` | Toggle Bluetooth |
| `Super + Alt + N` | Toggle Wi-Fi |

## 📁 File Structure

```
~/.config/
├── hypr/
│   ├── hyprland.conf
│   ├── hyprlock.conf
│   ├── hypridle.conf
│   ├── theme.conf              # ← active border colors (copied from themes/)
│   ├── themes/                 # border color per theme
│   ├── custom/
│   │   ├── binds.conf          # keybindings
│   │   ├── exec.conf           # autostart apps
│   │   ├── monitors.conf       # ← edit this
│   │   ├── devices.conf        # ← edit this
│   │   ├── rules.conf
│   │   └── variables.conf
│   ├── scripts/
│   │   ├── set-theme           # theme switcher
│   │   ├── lock.sh
│   │   └── screenshot.sh
│   └── nowplaying/
│
├── waybar/
│   ├── config.jsonc
│   ├── style.css
│   ├── theme.css               # ← copied from themes/
│   └── themes/
│
├── rofi/
│   ├── theme.rasi
│   └── scripts/
│       ├── wallpaper-menu.sh
│       └── launcher-menu.sh
│
├── swaync/
├── kitty/
└── btop/
```

## ⚠️ Manual Configuration After Install

| File | What to Edit |
|------|-------------|
| `~/.config/hypr/custom/monitors.conf` | Monitor name and resolution |
| `~/.config/hypr/custom/devices.conf` | Keyboard and mouse names |
| `~/.config/waybar/scripts/weather.sh` | Set LAT and LON coordinates |

## 📝 Notes

- Default wallpaper: `MistyTrees.jpg`
- Changing wallpaper from the menu also updates the lock screen automatically
- This repository is intended for Fuji Linux, the configuration has been adapted and maintained for Fuji Linux

## 🤝 Contributing

Suggestions, improvements, and fixes are welcome, feel free to open an Issue or submit a Pull Request.
