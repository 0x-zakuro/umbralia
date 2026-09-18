## 1. Archinstall Configuration

| Setting                              | Value                            |
| ------------------------------------ | -------------------------------- |
| Mirrors and Repositories             | Region: India                    |
| Disk Configuration → Partitioning    | Best-effort default partitioning |
| — Filesystem                         | btrfs                            |
| — Btrfs subvolumes                   | Yes                              |
| — Compression                        | Yes                              |
| Disk Configuration → Btrfs snapshots | snapper                          |
| — Swap                               | zram enabled, algorithm: zstd    |
| — Bootloader                         | GRUB                             |
| Hostname                             | arch                             |
| — Root password                      | (set password)                   |
| — User account                       | kuro / (set password)            |
| Profile Type                         | Minimal                          |
| Bluetooth                            | Configure: Yes                   |
| Audio                                | pipewire                         |
| Battery management                   | (upper option)                   |
| Network configuration                | NetworkManager (default backend) |
| Timezone                             | Asia/Kolkata                     |

---

## 2. Connect to WiFi (Post Boot)

```bash
iwctl
station wlan0 connect Airtel_arun_7976
```

---

## 3. Install Core Packages

```bash
sudo pacman -S git zsh udisks2 starship zsh-autosuggestions zsh-syntax-highlighting foot base-devel ntfs-3g gvfs gvfs-mtp amd-ucode mpv gthumb tumbler ffmpegthumbnailer thunar-volman zed nano
```

---

## 4. Configure Zsh

```bash
echo 'export ZDOTDIR=$HOME/.config/zsh' | sudo tee /etc/zsh/zshenv
chsh -s /usr/bin/zsh
```

> Log out and back in (or reboot) for the shell change to take effect.

---

## 5. Enable Services

```bash
sudo systemctl enable --now NetworkManager bluetooth fstrim.timer udisks2
```

> `greeter` (from noctalia-greeter) isn't installed until Section 6 — enable it after that step, not here.

---

## 6. Install Yay (AUR Helper) + AUR Packages

```bash
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd .. && rm -rf yay
rm -rf ~/.cache/go
sudo pacman -Rns go
```

```bash
yay -S umbriel-git noctalia-greeter helium-browser-bin obsidian
```

```bash
sudo systemctl enable --now greeter
```

---

## 7. Write Dotfiles Directly

Text-based configs are written directly with heredocs — paste each file's contents where marked. Only images/fonts at the bottom still need the pendrive.

```bash
# ------------------------------------------------------------
# Polkit rule (system file — needs sudo)
# ------------------------------------------------------------
sudo mkdir -p /etc/polkit-1/rules.d
sudo tee /etc/polkit-1/rules.d/49-noctalia-greeter.rules > /dev/null << 'EOF'
# paste contents of 49-noctalia-greeter.rules here
EOF

# ------------------------------------------------------------
# Umbriel config
# ------------------------------------------------------------
mkdir -p ~/.config/umbriel

cat > ~/.config/umbriel/appearance.toml << 'EOF'
# ───────────────────────────── Appearance ───────────────────────────────────
# Configure window decoration geometry, blur, shadows, and other visual
# effects.
# Documentation: https://docs.noctalia.dev/umbriel/appearance/#window-appearance
# ────────────────────────────────────────────────────────────────────────────

[appearance]
prefer_no_csd = true                            # Prefer Umbriel's border-only decoration
border_width = 2                                # Inner border width, 0-100 logical pixels
outer_border_width = 0                          # Optional outer ring, 0-100 logical pixels
corner_radius = 10                              # Radius of the final decorated edge, 0-100
drag_opacity = 0.75                             # Window opacity during a tiled or floating drag

[appearance.blur]
# This is the global blur engine. A matching window or layer rule must still
# opt a surface into blur.
enabled = true                                  # Disable blur and release per-output effect buffers
optimized = true                                # Reuse one cached background blur per output
passes = 3                                      # Blur passes, 0-8
radius = 2                                      # Blur radius, 0-100
noise = 0.2                                     # Noise overlay, 0.0-1.0
brightness = 0.9                                # 0.0-2.0
contrast = 0.9                                  # 0.0-2.0
saturation = 1.1                                # 0.0-2.0

[appearance.shadow]
# Custom window shaders automatically shape the shadow from their output alpha.
# Shadows stay beneath windows and follow closing snapshots as well.
enabled = true                                  # Draw shadows behind non-fullscreen windows
softness = 10                                   # Gaussian softness, 0-200; 0 is a hard edge
offset_x = 2                                    # Horizontal offset, -200 to 200
offset_y = 2                                    # Vertical offset, -200 to 200

# ─────────────────────────────── Colors ─────────────────────────────────────
# Configure every color Umbriel paints. Values stay commented so an included
# Noctalia-generated palette can supply them without this main file winning.
# Documentation: https://docs.noctalia.dev/umbriel/appearance/#colors
# ────────────────────────────────────────────────────────────────────────────

[colors]
# background = "#141419FF"                      # Internal panels and banners
# text_primary = "#E8E8EAFF"                    # Primary text
# text_muted = "#8A8A92FF"                      # Secondary help and status text
# accent_primary = "#7AA3FFFF"                  # Titles, key chords, and primary emphasis
# accent_secondary = "#F5C96BFF"                # Group headings and secondary emphasis
# warning = "#F5C96BFF"                         # Warning text and warning-only diagnostics
# error = "#FF6B6BFF"                           # Error text, confirmations, and diagnostics
# insert_hint = "#7FC8FF80"                     # Drag-and-drop target preview
# backdrop = "#000000FF"                        # Fullscreen gaps and lock screen
# shadow = "#0000007F"                          # Window shadow

[colors.border]
focused = "#9a9a9a"                         # Focused window border
# unfocused = "#292933FF"                       # Unfocused window border
# scratchpad_focused = "#E5C07BFF"              # Focused scratchpad border
# scratchpad_unfocused = "#5C4A2AFF"            # Unfocused scratchpad border
# outer = "#1A1A1FFF"                           # Outer border ring

[colors.overview]
# background_tint = "#10101430"                 # Tint over the desktop background
# workspace_background = "#00000044"            # Background behind each workspace
# badge = "#7AA3FFFF"                           # Overview shortcut badge

# ─────────────────────────────── Layout ─────────────────────────────────────
# Configure the default tiling mode and shared sizing behavior. Workspace rules
# above can override these values for individual workspaces.
# Documentation: https://docs.noctalia.dev/umbriel/layout/
# ────────────────────────────────────────────────────────────────────────────

[layout]
mode = "dwindle"                              # scrolling, dwindle, or master
gap = 16                                         # Logical pixels between tiles, 0-500
width_presets = [0.333, 0.5, 0.667]             # Width and height cycling fractions

[layout.struts]
# Signed logical pixels reserved after panel exclusive zones. Negative values
# expand the tiled area beyond that edge.
left = 0                                        # -65535 to 65535
right = 0
top = 0
bottom = 0

[layout.scrolling]
# The strip axis is perpendicular to the output's workspace_axis.
default_width_fraction = 0.5                    # Initial width for new columns, 0.1-1.0
center_underfull_strip = true                   # Center a strip narrower than the viewport
center_focused = "never"                        # never, always, or on_overflow

[layout.dwindle]
# preserve_split = false                        # Keep every split direction fixed after creation
new_exits_fullscreen = false                    # Exits fullscreen when a new window is opened in the workspace

[layout.master]
position = "left"                               # left, right, or center master area
default_width_fraction = 0.55                   # Initial master area fraction, 0.1-0.9
new_on_top = true                               # Put new windows at the top of the stack
new_becomes_master = false                      # New windows take the master slot
new_exits_fullscreen = false                    # Exits fullscreen when a new window is opened in the workspace
EOF

cat > ~/.config/umbriel/config.toml << 'EOF'
# Umbriel example configuration

# Distribution packages normally install this file as
# /usr/share/umbriel/config.toml. Copy it to ~/.config/umbriel/config.toml
# before making personal changes. Creating the user file and saving later edits
# both apply live, so a logout is not needed.

# Validate the standard config without starting or disturbing the compositor:
#   umbriel validate
# Use `-c` for a custom config path:
#   umbriel validate -c /path/to/config.toml

# Complete documentation: https://docs.noctalia.dev/umbriel/

# ─────────────────────────────── Includes ───────────────────────────────────
# Split large configurations into smaller files. Required files are applied in
# list order, followed by optional files, then values in this main file.
# Missing optional files are silently ignored and remain watched. Relative
# paths start from the directory containing this file. Rule lists such as
# [[window_rule]] collect entries from every file; any other value is replaced
# by the last file that sets it.
# Documentation: https://docs.noctalia.dev/umbriel/configuration/#include
# ────────────────────────────────────────────────────────────────────────────

[include]
files = [
  "~/.config/umbriel/general.toml",
  "~/.config/umbriel/appearance.toml",
  "~/.config/umbriel/input.toml",
  "~/.config/umbriel/keybinds.toml",
  "~/.config/umbriel/rules.toml",
  "~/.config/umbriel/workspaces.toml",
  "~/.config/umbriel/monolith.toml",
]                                      # Example: ["appearance.toml", "outputs.toml"]

[include.optional]
files = [
    "~/.config/umbriel/noctalia.toml",
]                                      # Example: ["~/.config/umbriel/noctalia.toml"]

# ─────────────────────────────── Outputs ────────────────────────────────────
# Configure monitor identity, mode, logical placement, scaling, HDR, VRR, and
# workspace inventory. Run `umbriel outputs` to list names and available modes.
# Documentation: https://docs.noctalia.dev/umbriel/outputs/
# ────────────────────────────────────────────────────────────────────────────

# Output sections are machine-specific, so this example stays commented.
# Uncomment the complete block below and replace DP-1 with the correct name.
# Use a connector when the rule belongs to a port. To follow one physical
# display between machines or ports, replace the header with its quoted Config
# name, for example [output."Some Make Some Model ABC123"].

[output.eDP-1]
# enabled = true                                # False removes the output but preserves its state
# mode = "2560x1440@144"                        # WIDTHxHEIGHT or WIDTHxHEIGHT@HZ
# position = [0, 0]                             # Logical top-left; omit for automatic placement
# scale = 1.25                                  # Logical size is mode size divided by scale
# transform = "normal"                          # normal, 90, 180, 270, or a flipped variant
# vrr = "fullscreen"                            # disabled, always, or fullscreen
# tearing = true                                # Permit eligible fullscreen asynchronous flips
# direct_scanout = true                         # False forces composition on this output
# hdr = "auto"                                  # off, on, auto, or fullscreen
# sdr_white = 203                               # SDR reference white in cd/m2 during HDR
# workspaces = 5                                # Anonymous fixed positions; omit for dynamic
workspace_axis = "horizontal"                   # vertical or horizontal workspace arrangement

# Replace the count with ["WEB", "CHAT", "MEDIA"] for named static workspaces,
# or with "dynamic" to state the dynamic default explicitly. A dynamic output
# can keep a minimum number of workspaces instead, so a bar always shows them:
# [output.DP-1]
# min_workspaces = 3                            # Dynamic floor; rejected with a static inventory

# New scrolling columns on this output can use a different initial width. This
# affects new columns only; existing columns keep their current size.
# Documentation: https://docs.noctalia.dev/umbriel/outputs/#initial-scrolling-width
# [output.DP-1.layout.scrolling]
# default_width_fraction = 0.4

# ────────────────────────────── Scratchpads ─────────────────────────────────
# With no entries below, Umbriel creates one implicit scratchpad named
# `default`, and bare scratchpad actions select it. Defining any named
# scratchpad disables that implicit default and requires a name suffix on every
# scratchpad action. Names must be unique, and `default` is reserved.
# Documentation: https://docs.noctalia.dev/umbriel/scratchpads/
# ────────────────────────────────────────────────────────────────────────────

# [[scratchpad]]
# name = "terminal"

# [[scratchpad]]
# name = "music"

# A `default_scratchpad` window rule can store new matching windows
# automatically. Use "default" while the definitions above remain commented,
# or an exact configured name after enabling named mode.

# ─────────────────────── Security Context Rules ─────────────────────────────
# Sandboxed clients receive a restricted Wayland global set. Grant extra
# globals only to a narrowly matched application that genuinely needs them.
# Documentation: https://docs.noctalia.dev/umbriel/security/#per-application-grants
# ────────────────────────────────────────────────────────────────────────────

# Grant a sandboxed clipboard manager both data-control protocol variants.
# Uncomment the complete block and replace the example application ID.

# [[security_context_rule]]
# match.sandbox_engine = 'org\.flatpak'
# match.app_id = 'org\.example\.ClipboardManager'
# allow_globals = ["ext_data_control_manager_v1", "zwlr_data_control_manager_v1"]
EOF

cat > ~/.config/umbriel/general.toml << 'EOF'
# ─────────────────────────────── General ────────────────────────────────────
# Configure startup commands, session behavior, environment variables, and
# hardware events.
# Documentation: https://docs.noctalia.dev/umbriel/configuration/#general
# ────────────────────────────────────────────────────────────────────────────

[general]
autostart = ["noctalia", "sh -c 'sleep 1 && noctalia msg session lock'"]      # Commands run once when the session starts
# mod_key = "Super"                                                           # Force Super instead of nested-session Alt
xwayland = false                                                              # Requires xwayland-satellite; restart to change
show_cheatsheet = false                                                       # Show the keybind overlay on startup
focus_on_activate = false                                                     # Do not let unsolicited requests steal focus
honor_restored_maximize = false                                               # Honor restored maximized state

# Native GPU exclusions
# Changes require a restart. Use a PCI address if the GPU may start bound to vfio-pci.
# Device paths must resolve at startup or Umbriel refuses to start.
# Documentation: https://docs.noctalia.dev/umbriel/configuration/#drm-devices
# [drm]
# ignored_devices = ["/dev/dri/by-path/pci-0000:01:00.0-card"]
# ignored_pci_addresses = ["0000:01:00.0"]

# Session environment
# Native launcher sessions first load the user's supported login profile.
# Values here override inherited values and are published to new systemd user
# services. They apply only at session startup. Add or uncomment as needed.
# Documentation: https://docs.noctalia.dev/umbriel/configuration/#environment

[environment]
# ELECTRON_OZONE_PLATFORM_HINT = "auto"
# SDL_VIDEODRIVER = "wayland"

# Hardware events
# These commands run when a laptop lid opens or closes. Uncomment either hook
# to enable it.
# Documentation: https://docs.noctalia.dev/umbriel/configuration/#events

[events]
# lid_close = "notify-send 'The laptop lid is closed'"
# lid_open = "notify-send 'The laptop lid is open'"
EOF

cat > ~/.config/umbriel/input.toml << 'EOF'
# ──────────────────────────────── Input ─────────────────────────────────────
# Configure keyboards, pointers, tablets, cursor behavior, and focus policy.
# Documentation: https://docs.noctalia.dev/umbriel/input/
# ────────────────────────────────────────────────────────────────────────────

[input]
middle_click_paste = true                       # Primary-selection paste; applies on reload
window_drag_toggle = "none"                     # Retarget a window drag: "none", "floating", or "pinned"

[input.keyboard]
# Physical keyboard XKB settings. Virtual keyboards provide their own keymaps.
layout = ""                                     # Example: "us,de"; empty uses the system default
variant = ""                                    # Example: ",nodeadkeys" for two layouts
options = ""                                    # Example: "grp:alt_shift_toggle"
repeat_rate = 25                                # Key repeats per second, 0-1000
repeat_delay = 600                              # Delay before repeating, 0-10000 ms
numlock_toggle = true                           # Enable on connect; false preserves the current state
track_layout = "global"                         # global, or window for per-surface layout memory

[input.touchpad]
tap = true                                      # Tap-to-click
# natural_scroll = true                         # Omit to preserve the libinput default
# accel_profile = "adaptive"                    # flat, adaptive, or custom <step> <points...>
# sensitivity = 0.5                             # Pointer speed, -1.0 to 1.0
# scroll_factor = 1.5                           # Two-finger scroll multiplier, 0.1-10.0
# scroll_factor = { horizontal = 2.0, vertical = 1.5 }   # or per axis instead of the line above, 0.1-10.0
# disable_while_typing = true                   # Omit to preserve the libinput default
# disable_on_external_mouse = true              # Native sessions only
# click_method = "clickfinger"                  # button_areas or clickfinger; omit for the device default

[input.mouse]
# natural_scroll = false                        # Omit to preserve the libinput default
# accel_profile = "flat"                        # Omit to preserve the libinput default
sensitivity = 0.0                               # Pointer speed, -1.0 to 1.0
scroll_wheel_step = 60                          # Logical pixels per layout-scroll action, 1-1000
# scroll_button = "MouseBack"                   # Hold to scroll with pointer motion; omit to leave the device alone
# scroll_button_lock = false                    # One press latches scrolling instead of holding

[input.tablet]
enabled = true                                  # False disables tablet tools and pads
# map_to_output = "DP-1"                        # Connector or monitor Config name
# map_to_focused_output = false
# map_to_focused_window = false                 # Focused-window mapping has highest priority
# left_handed = false
# calibration_matrix = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]

[input.cursor]
theme = ""                                      # Empty uses environment or default Xcursor theme
size = 24                                       # Logical size, 1-512
hardware_cursor = true                          # False forces cursor composition
follows_focus = false                           # Warp to windows selected by focus, output, move, or other activations
hide_when_typing = false                        # Keep visible while typing
hide_timeout_ms = 0                             # Idle hide timeout, 0 disables; maximum is 3600000

[input.focus]
follows_mouse = false                           # Focus on pointer motion and Dwindle/master tiles revealed on close
# Refuse hover focus when revealing a window would scroll farther than this
# many viewport widths. Omit the key for no limit.
# follows_mouse_max_scroll = 0.5

# Exact, case-sensitive per-device overrides inherit their device-kind table.
# Find names with `libinput list-devices`. Uncomment each complete block needed.
# Documentation: https://docs.noctalia.dev/umbriel/input/#per-device-overrides

# [[input.device]]
# name = "Acme Split Keyboard"
# layout = "us"
# variant = "colemak_dh"
# repeat_rate = 40
# repeat_delay = 250

# [[input.device]]
# name = "Acme Precision Touchpad"
# tap = true
# natural_scroll = false
# accel_profile = "flat"
# sensitivity = 0.0
# disable_while_typing = false
# click_method = "clickfinger"

# [[input.device]]
# name = "Acme Gaming Mouse"
# accel_profile = "flat"
# sensitivity = 0.0
# scroll_button = "MouseBack"
# scroll_button_lock = false
EOF

cat > ~/.config/umbriel/keybinds.toml << 'EOF'
# ──────────────────────────────── Input ─────────────────────────────────────
# Configure keyboards, pointers, tablets, cursor behavior, and focus policy.
# Documentation: https://docs.noctalia.dev/umbriel/input/
# ────────────────────────────────────────────────────────────────────────────

[input]
middle_click_paste = true                       # Primary-selection paste; applies on reload
window_drag_toggle = "none"                     # Retarget a window drag: "none", "floating", or "pinned"

[input.keyboard]
# Physical keyboard XKB settings. Virtual keyboards provide their own keymaps.
layout = ""                                     # Example: "us,de"; empty uses the system default
variant = ""                                    # Example: ",nodeadkeys" for two layouts
options = ""                                    # Example: "grp:alt_shift_toggle"
repeat_rate = 25                                # Key repeats per second, 0-1000
repeat_delay = 600                              # Delay before repeating, 0-10000 ms
numlock_toggle = true                           # Enable on connect; false preserves the current state
track_layout = "global"                         # global, or window for per-surface layout memory

[input.touchpad]
tap = true                                      # Tap-to-click
# natural_scroll = true                         # Omit to preserve the libinput default
# accel_profile = "adaptive"                    # flat, adaptive, or custom <step> <points...>
# sensitivity = 0.5                             # Pointer speed, -1.0 to 1.0
# scroll_factor = 1.5                           # Two-finger scroll multiplier, 0.1-10.0
# scroll_factor = { horizontal = 2.0, vertical = 1.5 }   # or per axis instead of the line above, 0.1-10.0
# disable_while_typing = true                   # Omit to preserve the libinput default
# disable_on_external_mouse = true              # Native sessions only
# click_method = "clickfinger"                  # button_areas or clickfinger; omit for the device default

[input.mouse]
# natural_scroll = false                        # Omit to preserve the libinput default
# accel_profile = "flat"                        # Omit to preserve the libinput default
sensitivity = 0.0                               # Pointer speed, -1.0 to 1.0
scroll_wheel_step = 60                          # Logical pixels per layout-scroll action, 1-1000
# scroll_button = "MouseBack"                   # Hold to scroll with pointer motion; omit to leave the device alone
# scroll_button_lock = false                    # One press latches scrolling instead of holding

[input.tablet]
enabled = true                                  # False disables tablet tools and pads
# map_to_output = "DP-1"                        # Connector or monitor Config name
# map_to_focused_output = false
# map_to_focused_window = false                 # Focused-window mapping has highest priority
# left_handed = false
# calibration_matrix = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]

[input.cursor]
theme = ""                                      # Empty uses environment or default Xcursor theme
size = 24                                       # Logical size, 1-512
hardware_cursor = true                          # False forces cursor composition
follows_focus = false                           # Warp to windows selected by focus, output, move, or other activations
hide_when_typing = false                        # Keep visible while typing
hide_timeout_ms = 0                             # Idle hide timeout, 0 disables; maximum is 3600000

[input.focus]
follows_mouse = false                           # Focus on pointer motion and Dwindle/master tiles revealed on close
# Refuse hover focus when revealing a window would scroll farther than this
# many viewport widths. Omit the key for no limit.
# follows_mouse_max_scroll = 0.5

# Exact, case-sensitive per-device overrides inherit their device-kind table.
# Find names with `libinput list-devices`. Uncomment each complete block needed.
# Documentation: https://docs.noctalia.dev/umbriel/input/#per-device-overrides

# [[input.device]]
# name = "Acme Split Keyboard"
# layout = "us"
# variant = "colemak_dh"
# repeat_rate = 40
# repeat_delay = 250

# [[input.device]]
# name = "Acme Precision Touchpad"
# tap = true
# natural_scroll = false
# accel_profile = "flat"
# sensitivity = 0.0
# disable_while_typing = false
# click_method = "clickfinger"

# [[input.device]]
# name = "Acme Gaming Mouse"
# accel_profile = "flat"
# sensitivity = 0.0
# scroll_button = "MouseBack"
# scroll_button_lock = false
EOF

cat > ~/.config/umbriel/monolith.toml << 'EOF'

EOF

cat > ~/.config/umbriel/rules.toml << 'EOF'
# ───────────────────────────── Window Rules ─────────────────────────────────
# Match windows by application ID, title, XDG tag, content type, or focus state.
# Opening settings apply once; effects and output policies update while mapped.
# Documentation: https://docs.noctalia.dev/umbriel/window-rules/
# ────────────────────────────────────────────────────────────────────────────

# Blur every window. Keep this selectorless rule first so later matching rules
# can override individual blur settings.
[[window_rule]]
blur = true
blur_optimized = false

[[window_rule]]
opacity = 0.85

# Noctalia settings
[[window_rule]]
match.app_id = "^dev.noctalia.Noctalia$"
default_floating = true
default_size = [1020, 900]

# Noctalia share picker
[[window_rule]]
match.app_id = "^dev.noctalia.UmbrielSharePicker$"
default_floating = true
default_size = [800, 600]

# Browsers expose no semantic PiP role or global position control.
[[window_rule]]
match.title = "^(Picture-in-Picture|Picture in picture)$"
default_floating = true
default_maximize = false
default_position = { x = 20, y = 20, anchor = "bottom_right" }

# Keep Steam notification toasts in the bottom-right corner without stealing
# focus, and pin them so workspace switches do not hide them.
[[window_rule]]
match.title = "^notificationtoasts_.+_desktop"
default_position = { x = 0, y = 0, anchor = "bottom_right" }
default_focused = false
default_pinned = true

# Optional positional placement recipe. Output names follow the same rules as
# [output.*]. `default_output` scopes the workspace lookup to that output, and
# integer workspace selectors are 1-based positions.

# [[window_rule]]
# match.app_id = "^org[.]example[.]Editor$"
# default_output = "DP-1"
# default_workspace = 2
# default_focused = false

# A string workspace selector is an exact, case-sensitive name, so `"2"`
# selects the workspace named `"2"` instead of position 2. The workspace can
# come from a static name list or a name-based [[workspace]] entry on a dynamic
# output. The window rule itself never creates a workspace.

# [[window_rule]]
# match.app_id = "^org[.]example[.]Chat$"
# default_output = "DP-1"
# default_workspace = "CHAT"
# default_focused = false

# Store a dedicated terminal in the named `terminal` scratchpad. Enable its
# [[scratchpad]] definition above, then launch
# `foot --app-id scratchpad-terminal`. The output and workspace remain
# its restore destination.

# [[window_rule]]
# match.app_id = "^scratchpad-terminal$"
# default_scratchpad = "terminal"
# default_output = "DP-1"
# default_workspace = 2
# default_floating = true
# default_width = 0.6
# default_height = 0.5
# default_position = { x = 0, y = 8, anchor = "top" }

# [[window_rule]]
# match.app_id = "^example-app$"
# default_maximize = true

# Open an application maximized to usable-area edges, without gaps or borders.

# [[window_rule]]
# match.app_id = "^discord$"
# default_maximize_to_edges = true

# Match a standardized surface content hint.

# [[window_rule]]
# match.content_type = "game"
# vrr = "always"

# Match a client-defined XDG toplevel tag, such as Proton-EM's game tag.

# [[window_rule]]
# match.xdg_tag = "^proton-game$"
# default_fullscreen = true

# Seed a new horizontal scrolling column with a pixel width. The layout controls
# its tiled height, and existing named columns keep their established width.

# [[window_rule]]
# match.app_id = "^org[.]example[.]Wide$"
# default_size = [1200, 600]

# Size a floating window as fractions of the usable area. `default_size` wins
# on both axes if it is also present.

# [[window_rule]]
# match.app_id = "^org[.]example[.]Utility$"
# default_floating = true
# default_width = 0.5
# default_height = 0.6

# Dynamic effects and output policies can be combined in one matching rule.

# [[window_rule]]
# match.app_id = "^firefox$"
# match.title = "^Library$"
# default_floating = true
# default_focused = false
# focus_on_activate = true
# opacity = 0.95
# blur_popups = true
# blur_ignore_alpha = 0.1
# vrr = "always"
# tearing = true
# hdr = "fullscreen"

# Keep related tiled windows in one named scrolling column. Lower orders appear
# higher in horizontal scrolling and farther left in vertical scrolling.

# [[window_rule]]
# match.app_id = "^firefox$"
# default_scrolling_column = "browsers"
# default_scrolling_column_order = 10

# State-aware rules update as focus, floating, pinned, and scratchpad state
# change. Pinned and scratchpad windows are floating too.

# [[window_rule]]
# match.is_focused = false
# opacity = 0.85

# [[window_rule]]
# match.is_focused = true
# opacity = 1.0

# [[window_rule]]
# match.is_floating = true
# match.is_scratchpad = false
# blur = false

# Fill the viewport for a workspace's lone tiled column.
# [[window_rule]]
# match.is_alone = true
# default_maximize = true

# 75% width when the window is alone, the default width when another window opens.
# [[window_rule]]
# match.is_alone = true
# default_width = 0.75

# ────────────────────────────── Layer Rules ─────────────────────────────────
# Match layer-shell surfaces such as panels, launchers, notifications, and
# desktop widgets by namespace. Run `umbriel layers` to inspect live names.
# Documentation: https://docs.noctalia.dev/umbriel/layer-rules/
# ────────────────────────────────────────────────────────────────────────────

[[layer_rule]]
match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$"
blur = true
blur_ignore_alpha = 0.5
blur_popups = true
blur_optimized = false

# ────────────────────────────── Animation ───────────────────────────────────
# Parent values provide defaults for every event table. Nested values override
# only that event. Disable one event to make just that transition instant.
# Documentation: https://docs.noctalia.dev/umbriel/animation/
# Every event accepts shader = "path/to/effect.glsl". Inline GLSL is not supported.
# File paths are relative to this config, including configs loaded via include.
# Bundled reveal.glsl and squash.glsl can be referenced by their installed absolute paths.
# Shaders can use umbriel_sample_previous(uv) for target-local feedback.
# umbriel_random_seed is a stable vec4 that changes for each transition.
# Copy examples/shaders beside your config only if you want editable local versions.
# ────────────────────────────────────────────────────────────────────────────

[animation]
enabled = true                                  # Master animation switch
duration_ms = 250                               # Shared duration, 1-10000 ms
curve = "easeout"                               # Built-in or registered bezier/spring curve name

# Window opening
[animation.windows_in]
enabled = true
duration_ms = 150
curve = "easeout"
style = "slide"                                 # popin, zoom, slide, fade, or none
scale = 0.85                                    # Popin start scale, 0.1-1.0
# shader = "shaders/reveal.glsl"      # Replaces the built-in opening style

# Window closing
[animation.windows_out]
enabled = true
duration_ms = 150
curve = "easeout"
style = "fade"                                  # fade or slide
# shader = "shaders/reveal.glsl"

# Window movement, resizing, and floating maximize. Visible scratchpad keybind
# resizing uses this event too.
[animation.windows_move]
enabled = true
duration_ms = 250
curve = "snappy"
# shader = "shaders/squash.glsl"      # Subtle compression and settle during move/resize

# Workspace switching
[animation.workspaces]
enabled = true
duration_ms = 250
curve = "easeout"

# Overview opening and closing
[animation.overview]
enabled = true
duration_ms = 250
curve = "easeout"
# Filmstrip movement between workspace previews: wheel, keyboard, and touchpad
# release alike. A spring curve settles from wherever the previews are and keeps
# the speed a swipe let go with; any other curve runs over duration_ms instead.
workspace_curve = "spring:1,1000"

# Scratchpad show, hide, and backdrop
[animation.scratchpad]
enabled = false
duration_ms = 250
curve = "easeout"
dim = 0.5                                       # Backdrop dim amount, 0.0-1.0
blur = false                                    # Requires appearance.blur.enabled
scale = 0.0                                     # 0 keeps geometry; 0.1-1.0 centers and scales
maximize = false                                # Maximize to usable-area edges while shown
fullscreen = false                              # Make the scratchpad window fullscreen while shown

# Focus border color
[animation.border]
enabled = false
duration_ms = 250
curve = "easeout"

# Unfocused window opacity
[animation.dim_unfocused]
enabled = false
duration_ms = 250
curve = "easeout"
dim = 0.0                                       # 0 disables dimming; maximum is 1.0

# Layer-shell surface mapping and unmapping
[animation.layers]
enabled = false
duration_ms = 250
curve = "easeout"

# Register reusable curves by adding or uncommenting entries below.
# Documentation: https://docs.noctalia.dev/umbriel/animation/#curves

[animation.beziers]
# myBezier = [0.05, 0.9, 0.1, 1.0]

[animation.springs]
# myBounce = { damping = 0.5, stiffness = 200 }

# ─────────────────────── Overview and Hot Corners ───────────────────────────
# Configure the all-workspaces overview and pointer-triggered corner actions.
# Overview: https://docs.noctalia.dev/umbriel/workspaces-overview/
# Hot corners: https://docs.noctalia.dev/umbriel/keybinds/#hot-corners
# Corners pause only while the keyboard-focused window on their output is fullscreen.
# ────────────────────────────────────────────────────────────────────────────

[overview]
zoom = 0.5                                      # Workspace scale in overview, 0.1-0.75
scroll_factor_horizontal = 1.0                  # Overview gesture/wheel multiplier, left and right, 0.1-10.0
scroll_factor_vertical = 1.0                    # Overview gesture/wheel multiplier, up and down, 0.1-10.0
# Pinned windows stay hidden until overview closes; visible scratchpads are dismissed.
# background_blur = true                        # Blur the wallpaper behind overview rows
# workspace_wallpaper = true                    # Mirror wallpapers inside workspace previews
# shortcuts = true                              # Show keyboard shortcut badges on windows
# shortcut_keys = "1234567890"                  # Badge keys in preference order

[hot_corners.top_left]
enabled = true                                  # Open the overview after resting here
delay_ms = 500                                  # 0 activates immediately; maximum is 10000
action = "overview-open"                        # Any normal Umbriel action is accepted

[hot_corners.top_right]
enabled = false
delay_ms = 500
action = "overview-close"

[hot_corners.bottom_left]
enabled = false
delay_ms = 500
action = "overview-toggle"

[hot_corners.bottom_right]
enabled = false
delay_ms = 500
action = "spawn:notify-send 'Bottom right'"
EOF

cat > ~/.config/umbriel/workspaces.toml << 'EOF'
# ────────────────────────────── Workspaces ──────────────────────────────────
# Choose global workspace behavior. Each output uses dynamic workspaces unless
# its output section defines a static count or list of names.
# Documentation: https://docs.noctalia.dev/umbriel/workspaces/
# ────────────────────────────────────────────────────────────────────────────

[workspaces]
# Each output supports at most 64 workspaces, including empty ones.
back_and_forth = false                          # Re-select active workspace to switch back
empty_above = false                             # Keep one empty workspace above active range

# Workspace entries customize layout. An `index` follows the current position
# without creating a workspace. A `name` also materializes a persistent named
# member on matching dynamic outputs. On a static output, the rule applies only
# when that inventory already has the selected member. Select exactly one, and
# optionally scope by `output`.
# Documentation: https://docs.noctalia.dev/umbriel/workspaces/#workspace-rules

# [[workspace]]
# index = 2
# output = "DP-1"
# layout.mode = "dwindle"
# layout.gap = 4
# layout.struts.top = 24
# layout.scrolling.center_underfull_strip = false
# layout.dwindle.preserve_split = true

# Without `output`, every dynamic output gets its own case-sensitive CHAT
# workspace. Add `output = "DP-1"` to materialize it only there. A numeric
# string such as name = "2" remains distinct from index = 2.

# [[workspace]]
# name = "CHAT"
# layout.mode = "master"
EOF

# ------------------------------------------------------------
# Noctalia palettes
# ------------------------------------------------------------
mkdir -p ~/.config/noctalia/palettes

cat > ~/.config/noctalia/palettes/noctalia_blue.json << 'EOF'
{
    "dark": {
        "mPrimary": "#29a3d6",
        "mOnPrimary": "#ffffff",
        "mSecondary": "#ffffff",
        "mOnSecondary": "#ffffff",
        "mTertiary": "#cccccc",
        "mOnTertiary": "#2e3436",
        "mError": "#c01c28",
        "mOnError": "#ffffff",
        "mSurface": "#242424",
        "mOnSurface": "#ffffff",
        "mHover": "#29a3d6",
        "mOnHover": "#ffffff",
        "mSurfaceVariant": "#1e1e1e",
        "mOnSurfaceVariant": "#ffffff",
        "mOutline": "#3d3846",
        "mShadow": "#000000",
        "terminal": {
            "background": "#1e1e1e",
            "foreground": "#ffffff",
            "cursor": "#29a3d6",
            "cursorText": "#ffffff",
            "selectionBg": "#29a3d6",
            "selectionFg": "#ffffff",
            "normal": {
                "black": "#241f31",
                "red": "#c01c28",
                "green": "#2ec27e",
                "yellow": "#f5c211",
                "blue": "#1e78e4",
                "magenta": "#9841bb",
                "cyan": "#0ab9dc",
                "white": "#c0bfbc"
            },
            "bright": {
                "black": "#5e5c64",
                "red": "#ed333b",
                "green": "#57e389",
                "yellow": "#f8e45c",
                "blue": "#51a1ff",
                "magenta": "#c061cb",
                "cyan": "#4fd2fd",
                "white": "#ffffff"
            }
        }
    },
    "light": {
        "mPrimary": "#29a3d6",
        "mOnPrimary": "#ffffff",
        "mSecondary": "#2e3436",
        "mOnSecondary": "#ffffff",
        "mTertiary": "#777777",
        "mOnTertiary": "#ffffff",
        "mError": "#e01b24",
        "mOnError": "#ffffff",
        "mSurface": "#fafafa",
        "mOnSurface": "#2e3436",
        "mHover": "#29a3d6",
        "mOnHover": "#ffffff",
        "mSurfaceVariant": "#dddddd",
        "mOnSurfaceVariant": "#2e3436",
        "mOutline": "#d6d6d6",
        "mShadow": "#000000",
        "terminal": {
            "background": "#ffffff",
            "foreground": "#2e3436",
            "cursor": "#29a3d6",
            "cursorText": "#ffffff",
            "selectionBg": "#29a3d6",
            "selectionFg": "#ffffff",
            "normal": {
                "black": "#171421",
                "red": "#c01c28",
                "green": "#26a269",
                "yellow": "#a2734c",
                "blue": "#12488b",
                "magenta": "#a347ba",
                "cyan": "#2aa1b3",
                "white": "#d0cfcc"
            },
            "bright": {
                "black": "#5e5c64",
                "red": "#f66151",
                "green": "#33d17a",
                "yellow": "#e5a50a",
                "blue": "#29a3d6",
                "magenta": "#c061cb",
                "cyan": "#33c7de",
                "white": "#ffffff"
            }
        }
    }
}
EOF

cat > ~/.config/noctalia/palettes/noctalia_red.json << 'EOF'
{
    "dark": {
        "mPrimary": "#e46767",
        "mOnPrimary": "#ffffff",
        "mSecondary": "#ffffff",
        "mOnSecondary": "#ffffff",
        "mTertiary": "#cccccc",
        "mOnTertiary": "#2e3436",
        "mError": "#c01c28",
        "mOnError": "#ffffff",
        "mSurface": "#242424",
        "mOnSurface": "#ffffff",
        "mHover": "#e46767",
        "mOnHover": "#ffffff",
        "mSurfaceVariant": "#1e1e1e",
        "mOnSurfaceVariant": "#ffffff",
        "mOutline": "#3d3846",
        "mShadow": "#000000",
        "terminal": {
            "background": "#1e1e1e",
            "foreground": "#ffffff",
            "cursor": "#e46767",
            "cursorText": "#ffffff",
            "selectionBg": "#e46767",
            "selectionFg": "#ffffff",
            "normal": {
                "black": "#241f31",
                "red": "#c01c28",
                "green": "#2ec27e",
                "yellow": "#f5c211",
                "blue": "#1e78e4",
                "magenta": "#9841bb",
                "cyan": "#0ab9dc",
                "white": "#c0bfbc"
            },
            "bright": {
                "black": "#5e5c64",
                "red": "#ed333b",
                "green": "#57e389",
                "yellow": "#f8e45c",
                "blue": "#51a1ff",
                "magenta": "#c061cb",
                "cyan": "#4fd2fd",
                "white": "#ffffff"
            }
        }
    },
    "light": {
        "mPrimary": "#e46767",
        "mOnPrimary": "#ffffff",
        "mSecondary": "#2e3436",
        "mOnSecondary": "#ffffff",
        "mTertiary": "#777777",
        "mOnTertiary": "#ffffff",
        "mError": "#e01b24",
        "mOnError": "#ffffff",
        "mSurface": "#fafafa",
        "mOnSurface": "#2e3436",
        "mHover": "#e46767",
        "mOnHover": "#ffffff",
        "mSurfaceVariant": "#dddddd",
        "mOnSurfaceVariant": "#2e3436",
        "mOutline": "#d6d6d6",
        "mShadow": "#000000",
        "terminal": {
            "background": "#ffffff",
            "foreground": "#2e3436",
            "cursor": "#e46767",
            "cursorText": "#ffffff",
            "selectionBg": "#e46767",
            "selectionFg": "#ffffff",
            "normal": {
                "black": "#171421",
                "red": "#c01c28",
                "green": "#26a269",
                "yellow": "#a2734c",
                "blue": "#12488b",
                "magenta": "#a347ba",
                "cyan": "#2aa1b3",
                "white": "#d0cfcc"
            },
            "bright": {
                "black": "#5e5c64",
                "red": "#f66151",
                "green": "#33d17a",
                "yellow": "#e5a50a",
                "blue": "#e46767",
                "magenta": "#c061cb",
                "cyan": "#33c7de",
                "white": "#ffffff"
            }
        }
    }
}
EOF

# ------------------------------------------------------------
# Noctalia state — settings.toml (hand-authored config) plus
# the runtime state files, all originally from the same
# ~/.local/state/noctalia/ pendrive folder
# ------------------------------------------------------------
mkdir -p ~/.local/state/noctalia

cat > ~/.local/state/noctalia/settings.toml << 'EOF'
// Zed settings
//
// For information on how to configure Zed, see the Zed
// documentation: https://zed.dev/docs/configuring-zed
//
// To see all of Zed's default settings without changing your
// custom settings, run `zed: open default settings` from the
// command palette (cmd-shift-p / ctrl-shift-p)
{
  "cli_default_open_behavior": "existing_window",
  "autosave": {
    "after_delay": {
      "milliseconds": 1000
    }
  },
  "project_panel": {
    "dock": "left",
    "auto_fold_dirs": false
  },
  "outline_panel": {
    "dock": "left"
  },
  "collaboration_panel": {
    "dock": "left"
  },
  "agent": {
    "dock": "right",
    "favorite_models": [],
    "model_parameters": []
  },
  "git_panel": {
    "dock": "right"
  },
  "telemetry": {
    "diagnostics": false,
    "metrics": false,
    "anthropic_retention": false
  },
  "session": {
    "trust_all_worktrees": true
  },
  "base_keymap": "VSCode",
  "icon_theme": {
    "mode": "dark",
    "light": "Zed (Default)",
    "dark": "Material Icon Theme"
  },
  "ui_font_size": 16,
  "buffer_font_size": 15,
  "theme": {
    "mode": "dark",
    "light": "Oxocarbon Light",
    "dark": "Onyx Dark",
  },
}
EOF

cat > ~/.local/state/noctalia/state.toml << 'EOF'
[annotate]
advanced_size = "0"
color_arrow = "0.96,0.2,0.28,1"
color_blur = "0.96,0.2,0.28,1"
color_brush = "0.96,0.2,0.28,1"
color_circle = "0.96,0.2,0.28,1"
color_crop = "0.96,0.2,0.28,1"
color_eraser = "0.96,0.2,0.28,1"
color_highlighter = "1,0.91,0.2,1"
color_line = "0.96,0.2,0.28,1"
color_move = "0.96,0.2,0.28,1"
color_numbering = "0.96,0.2,0.28,1"
color_rectangle = "0.96,0.2,0.28,1"
color_text = "0.96,0.2,0.28,1"
fill = "0"
tool = "crop"
toolbar_positions = "{}"
width_arrow = "6"
width_blur = "32"
width_brush = "6"
width_circle = "6"
width_crop = "6"
width_eraser = "28"
width_highlighter = "24"
width_line = "6"
width_move = "6"
width_numbering = "32"
width_rectangle = "6"
width_text = "24"

[screenshot]
last_region = "223,200,801,646"

[security_migrations]
calendar_credentials_v1 = true

[theme_templates]
applied_builtin_ids = ""

[wallpaper_panel]
flatten = false
EOF

cat > ~/.local/state/noctalia/notification_history.json << 'EOF'
{
  "change_serial": 54,
  "entries": [
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 3,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "This is a normal priority message.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462481215,
        "icon": null,
        "id": 5,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462475215,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "normal"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 5,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462486238,
        "icon": null,
        "id": 6,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462480238,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 7,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462492099,
        "icon": "dialog-error",
        "id": 7,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462486099,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 8,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462496593,
        "icon": "dialog-error",
        "id": 8,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462490593,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 12,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462534505,
        "icon": "dialog-error",
        "id": 9,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462528505,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 13,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462537953,
        "icon": "dialog-error",
        "id": 10,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462531953,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 14,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462539904,
        "icon": null,
        "id": 11,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462533904,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "dismissed",
      "event_serial": 16,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462574651,
        "icon": null,
        "id": 12,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462568651,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 18,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462619381,
        "icon": null,
        "id": 13,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462613381,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 20,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462632323,
        "icon": null,
        "id": 14,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462626323,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 22,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462957900,
        "icon": null,
        "id": 15,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462951900,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 24,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789462975131,
        "icon": null,
        "id": 16,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462969131,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 32,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463001909,
        "icon": null,
        "id": 17,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462995909,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 33,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463003214,
        "icon": null,
        "id": 18,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462997214,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 34,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463004534,
        "icon": null,
        "id": 19,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462998534,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 35,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463005862,
        "icon": null,
        "id": 20,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789462999862,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 36,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463007040,
        "icon": null,
        "id": 21,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789463001040,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 37,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463008584,
        "icon": null,
        "id": 22,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789463002584,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 38,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463010044,
        "icon": null,
        "id": 23,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789463004044,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 40,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463021518,
        "icon": "dialog-error",
        "id": 24,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789463015518,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 42,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463036748,
        "icon": "dialog-error",
        "id": 25,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789463030748,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 44,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789463050465,
        "icon": "dialog-error",
        "id": 26,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789463044465,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 46,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789464008106,
        "icon": "dialog-error",
        "id": 27,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789464002106,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 49,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789464015480,
        "icon": "dialog-error",
        "id": 28,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789464009480,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 50,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789464019474,
        "icon": "dialog-error",
        "id": 29,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789464013474,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 53,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Something went wrong!",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789464028900,
        "icon": "dialog-error",
        "id": 30,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789464022900,
        "summary": "System Error",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    },
    {
      "active": false,
      "close_reason": "expired",
      "event_serial": 54,
      "notification": {
        "actions": [],
        "app_name": "notify-send",
        "body": "Danger! This is a critical alert.",
        "category": null,
        "desktop_entry": null,
        "expiry_wall_ms": 1789464033715,
        "icon": null,
        "id": 31,
        "image_data": null,
        "origin": "external",
        "received_wall_ms": 1789464027715,
        "summary": "Test Notification",
        "timeout": 6000,
        "urgency": "critical"
      },
      "seen": true
    }
  ],
  "next_id": 65,
  "version": 2
}
EOF

cat > ~/.local/state/noctalia/recently_used.json << 'EOF'
{
  "Applications": [
    "/usr/share/applications/thunar.desktop",
    "/usr/share/applications/thunar-settings.desktop",
    "/usr/share/applications/dev.zed.Zed.desktop",
    "/usr/share/applications/foot.desktop",
    "/usr/share/applications/kitty.desktop",
    "/usr/share/applications/helium.desktop",
    "/usr/share/applications/obsidian.desktop",
    "/usr/share/applications/virt-manager.desktop",
    "/usr/share/applications/dev.noctalia.Noctalia.desktop",
    "/usr/share/applications/yazi.desktop"
  ]
}
EOF

cat > ~/.local/state/noctalia/usage_counts.json << 'EOF'
{
  "Applications": {
    "/usr/share/applications/dev.noctalia.Noctalia.desktop": 4,
    "/usr/share/applications/dev.zed.Zed.desktop": 19,
    "/usr/share/applications/foot.desktop": 8,
    "/usr/share/applications/helium.desktop": 16,
    "/usr/share/applications/kitty.desktop": 1,
    "/usr/share/applications/obsidian.desktop": 6,
    "/usr/share/applications/thunar-settings.desktop": 1,
    "/usr/share/applications/thunar.desktop": 1,
    "/usr/share/applications/virt-manager.desktop": 3,
    "/usr/share/applications/yazi.desktop": 4
  }
}
EOF

cat > ~/.local/state/noctalia/wallpaper_shuffle.json << 'EOF'
{
  "scopes": {
    "global": {
      "/home/kuro/.config/wallpaper/Dark Mode Wallpaper": [
        "/home/kuro/.config/wallpaper/Dark Mode Wallpaper/Wallpaper.jpg",
        "/home/kuro/.config/wallpaper/Dark Mode Wallpaper/1.png",
        "/home/kuro/.config/wallpaper/Dark Mode Wallpaper/4.png"
      ],
      "/home/kuro/.config/wallpaper/Light Mode Wallpaper": [
        "/home/kuro/.config/wallpaper/Light Mode Wallpaper/2.jpg",
        "/home/kuro/.config/wallpaper/Light Mode Wallpaper/1.jpg",
        "/home/kuro/.config/wallpaper/Light Mode Wallpaper/wp8968733-4k-pc-cool-wallpapers.jpg"
      ]
    }
  },
  "version": 2
}
EOF

# ------------------------------------------------------------
# foot terminal
# ------------------------------------------------------------
mkdir -p ~/.config/foot

cat > ~/.config/foot/foot.ini << 'EOF'
font=DankMono:size=18, Symbols Nerd Font Mono:size=14


[colors-dark]
# Transparency for Foot (0.0 to 1.0)
alpha=0.9

# Oxocarbon Dark Base
background=161616
foreground=f2f4f8

# --- NORMAL COLORS ---
# Note: Color 0 is set to 262626 (base01) so it is visible against the 161616 background
regular0=262626  # black   
regular1=3ddbd9  # red     (Oxocarbon Cyan/Teal)
regular2=33b1ff  # green   (Oxocarbon Blue)
regular3=ee5396  # yellow  (Oxocarbon Pink)
regular4=42be65  # blue    (Oxocarbon Green)
regular5=be95ff  # magenta (Oxocarbon Purple)
regular6=ff7eb6  # cyan    (Oxocarbon Light Pink)
regular7=dadada  # white   (Oxocarbon Foreground)

# --- BRIGHT COLORS ---
# Mapped identically to normal colors as requested
bright0=888888   # bright black 
bright1=3ddbd9   # bright red
bright2=33b1ff   # bright green
bright3=ee5396   # bright yellow
bright4=42be65   # bright blue
bright5=be95ff   # bright magenta
bright6=ff7eb6   # bright cyan
EOF

# ------------------------------------------------------------
# starship prompt
# ------------------------------------------------------------
cat > ~/.config/starship.toml << 'EOF'
# ─────────────────────────────────────────────
#  Starship Prompt — Oxocarbon hex colors
# ─────────────────────────────────────────────

format = """$username$hostname $directory$git_branch$git_status$aws$terraform$kubernetes$docker_context$python$nodejs$fill$cmd_duration $time$line_break$character"""

# #42be65 = Oxocarbon green, #ee5396 = Oxocarbon red/pink
[character]
success_symbol = "[ ](bold #42be65)"
error_symbol   = "[ ](bold #ee5396)"

[fill]
symbol = "─"
style  = "#333333"

[time]
disabled    = false
time_format = "%T "
style       = "#ffffff"
format      = "[$time]($style)"

[username]
show_always = true
style_user  = "#9e9e9e"
style_root  = "bold #ee5396"
format      = "[$user]($style)"

[hostname]
ssh_only = false
style    = "#9e9e9e"
format   = "[@$hostname]($style)"

[directory]
style             = "bold #3ddbd9"
truncation_length = 4
truncate_to_repo  = true
format            = "[$path]($style)[$read_only]($read_only_style) "
read_only         = "󰌾 "
read_only_style   = "#ee5396"

# 󰊢 git — green when clean
[git_branch]
symbol = " "
style  = "bold #42be65"
format = "[$symbol$branch]($style) "

# red when dirty
[git_status]
format     = "([$all_status$ahead_behind]($style) )"
style      = "bold #ee5396"
conflicted = "⚡"
ahead      = "⇡${count}"
behind     = "⇣${count}"
diverged   = "⇕⇡${ahead_count}⇣${behind_count}"
untracked  = "?${count}"
stashed    = "↓"
modified   = "!${count}"
staged     = "+${count}"
deleted    = "-${count}"

# 󰸏 aws
[aws]
symbol = "󰸏 "
style  = "bold #ff7eb6"
format = "[$symbol$profile( \\($region\\))]($style) "

[aws.profile_aliases]
# "prod" = "⚠ PROD"

# 󱁢 terraform
[terraform]
symbol = "󱁢 "
style  = "bold #be95ff"
format = "[$symbol$workspace]($style) "

# 󱃾 kubernetes
[kubernetes]
disabled = false
symbol   = "󱃾 "
style    = "bold #33b1ff"
format   = "[$symbol$context( \\($namespace\\))]($style) "

# 󰡨 docker
[docker_context]
symbol = "󰡨 "
style  = "bold #33b1ff"
format = "[$symbol$context]($style) "

# 󰌠 python
[python]
symbol            = "󰌠 "
style             = "bold #be95ff"
format            = "[$symbol$pyenv_prefix($version)(\\($virtualenv\\))]($style) "
detect_files      = ["*.py", "pyproject.toml", "Pipfile", ".python-version"]
detect_extensions = ["py"]

#  node
[nodejs]
symbol            = "󰎙 "
style             = "bold #42be65"
format            = "[$symbol$version]($style) "
detect_files      = ["package.json", ".node-version"]
detect_extensions = ["js", "ts"]

[cmd_duration]
min_time = 2000
style    = "#888888"
format   = "[$duration]($style) "
EOF

# ------------------------------------------------------------
# zsh
# ------------------------------------------------------------
mkdir -p ~/.config/zsh

cat > ~/.config/zsh/.zshrc << 'EOF'
# --- 1. Basic Options ---
autoload -U compinit; compinit  # Enables the advanced tab completion system
setopt correct                  # Auto-corrects minor spelling mistakes (sl -> ls)

# --- 2. History (The Memory) ---
HISTFILE=~/.zsh_history         # Where to save your command history
HISTSIZE=1000           # How many commands to remember in the current session
SAVEHIST=1000           # How many commands to save to the file
setopt HIST_IGNORE_DUPS         # Don't record the same command twice in a row

# --- 3. The Plugins (Visuals & Speed) ---
# Load the packages we just installed with pacman
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- 6. Visual Tab Completion (The Menu) ---
# This makes the Tab key show a selectable menu with colors
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- 4. Your Visuals ---
eval "$(starship init zsh)"
fastfetch

export EDITOR=nvim

# --- Backup Script for github dotfiles ---
backup() {
    echo "backing up dotfiles..."
    
    # 1. Update the files in the backup folder
    cp ~/.zshrc ~/dotfiles/
    rm -rf ~/dotfiles/hypr && cp -r ~/.config/hypr ~/dotfiles/
    pacman -Qqe > ~/dotfiles/packages.txt
    
    # 2. Send to GitHub
    cd ~/dotfiles
    git add .
    git commit -m "Update: $(date)"
    git push
    
    # 3. Go back to where you were
    cd -
    echo "Backup complete!"
}

clean() {
    clear
    echo -e "\n \e[1;34m◆ SYSTEM PURGE PROTOCOL \e[0m"
    echo -e " \e[1;30m──────────────────────────────────────────\e[0m"
    
    # Authenticate sudo upfront so the script never hangs
    sudo -v

    echo -e "\n \e[1;37m[1/7] \e[1;36mPACKAGES  \e[1;30m▶\e[0m Sweeping orphans & package caches..."
    yay -Yc --noconfirm >/dev/null 2>&1
    # Keeps a 2-version rollback buffer just in case
    if command -v paccache &> /dev/null; then
        sudo paccache -rk2 >/dev/null 2>&1
        sudo paccache -ruk0 >/dev/null 2>&1
    else
        yes | yay -Sc >/dev/null 2>&1
    fi

    echo -e " \e[1;37m[2/7] \e[1;36mFLATPAK   \e[1;30m▶\e[0m Clearing unused runtimes..."
    if command -v flatpak &> /dev/null; then
        flatpak uninstall --unused --noninteractive >/dev/null 2>&1
    else
        echo -e "       \e[1;30m└─ Not installed. Skipping.\e[0m"
    fi

    echo -e " \e[1;37m[3/7] \e[1;36mLOGS      \e[1;30m▶\e[0m Vacuuming system & user journals (3d)..."
    sudo journalctl --vacuum-time=3d >/dev/null 2>&1
    journalctl --user --vacuum-time=3d >/dev/null 2>&1

    echo -e " \e[1;37m[4/7] \e[1;36mTRASH     \e[1;30m▶\e[0m Emptying coredumps & Thunar trash..."
    sudo find /var/lib/systemd/coredump/ -type f -delete 2>/dev/null
    # Safely nuke and recreate Thunar's trash to bypass Zsh errors
    rm -rf ~/.local/share/Trash/files ~/.local/share/Trash/info
    mkdir -p ~/.local/share/Trash/{files,info}

    echo -e " \e[1;37m[5/7] \e[1;36mHOME DIR  \e[1;30m▶\e[0m Evicting loose files & rogue folders..."
    # Keeps your ~ root completely minimal
    rm -rf ~/go ~/yay 2>/dev/null

    echo -e " \e[1;37m[6/7] \e[1;36mDEEP CACHE\e[1;30m▶\e[0m Safely purging old app data..."
    # 1. Nuke thumbnails completely
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    # 2. Smart Purge: Delete any cache file not modified in the last 3 days
    find ~/.cache -mindepth 1 -type f -mtime +3 -delete 2>/dev/null
    # 3. Clean up the empty folders left behind
    find ~/.cache -mindepth 1 -type d -empty -delete 2>/dev/null

    echo -e " \e[1;37m[7/7] \e[1;36mDEV & AUR \e[1;30m▶\e[0m Purging compiler bloat & build caches..."
    # 1. Nuke AUR build cache (Massive space saver)
    rm -rf ~/.cache/yay/* 2>/dev/null
    # 2. Nuke Python Pip cache
    rm -rf ~/.cache/pip/* 2>/dev/null
    # 3. Nuke Node.js cache
    rm -rf ~/.npm/_cacache/* 2>/dev/null
    # 4. Nuke Go cache (if installed)
    if command -v go &> /dev/null; then
        go clean -cache -modcache >/dev/null 2>&1
    fi

    echo -e "\n \e[1;32m✔ AGGRESSIVE OPTIMIZATION COMPLETE \e[1;30m| \e[1;37m$(date +%H:%M:%S)\e[0m"
    echo -e " \e[1;36m⚡ System is lean, refreshed, and stripped of bloat.\e[0m\n"
}
EOF

cat > ~/.config/zsh/.zprofile << 'EOF'

EOF

# .zsh_history is shell history, not a config file — it lives
# directly in $HOME, not ~/.config/zsh/
cat > ~/.zsh_history << 'EOF'
yazi
pkill yazi
hyprctl activewindow -j | jq -r '.class'
echo $TMUX\
echo $ZELLIJ
yazi
pgrep -a yazi
yazi
pkill -9 yazi
fg
sudo systemctl disable docker containerd\
sudo systemctl stop docker containerd
btop
yazi
btop
yazi
btop
sudo pacman -Rns udiskie
pkill -9 udiskie
pacman -Qqen
overskirde
overskride
pacman -Qqen
pacman -Qqem
yay -Syu overskride
yay -Ss overskride-bin
yay -Syu overskride-bin
ps aux | grep -e pacman -e yay\

sudo rm /var/lib/pacman/db.lck\

yay -Syu overskride-bin
overskride
yazi
cd projects
python -m venv venv\
\
source venv/bin/activate   \
\
pip
python -m venv venv
source venv/bin/activate   
pip install pandas pyarrow
cd project_1
cd data/raw
ls
cd ..
ls
python main.py
python
yazi
pkill -9 yazi
fq
yazi
overskride
btop
lsklk
lsblk
udisksctl mount -b /dev/sda1
yazi
nwg-look
yazi
cd projects
nvim .
cd syntax_learning
ls
python 1_pandas.py
source ../venv/bin/activate   
python 1_pandas.py
cd projects
pwd
tree
yazi
source /venv/bin/activate   
source venv/bin/activate   
python main.py
yazi
sudo mkfs.exfat -n "arch" /dev/sdb
mkfs.exfat -n "arch" /dev/sdb
lsblk
sudo pacman -Syu exfatprogs
sudo mkfs.exfat -n "arch" /dev/sdb
udisksctl mount -b /dev/sdb
ysxi
y
yazi
lsblk
sudo mkdir -p /mnt/arch /mnt/yuki /mnt/sawako /mnt/ventoy
yazi
lsblk -no LABEL,UUID,FSTYPE /dev/sdb1
lsblk -no LABEL,UUID,FSTYPE /dev/sdb
lsblk
lsblk -no LABEL,UUID,FSTYPE /dev/sdb
lsblk -no LABEL,UUID,FSTYPE /dev/sda1
sudo mount -a
sudo systemctl daemon-reload
sudo mount -a
udisksctl mount -b /dev/sdb
udisksctl mount -b /dev/sda1
sudo ntfsfix /dev/sda1
sudo mount -t ntfs-3g -o ro /dev/sda1 /mnt/yuki
sudo nvim etc/fstab
sudo nvim ~/etc/fstab
sudo nvim /etc/fstab
udisksctl mount -b /dev/sdb
udisksctl mount -b /dev/sda1
udisksctl umount -b /dev/sda1
sudo umount /dev/sda1
udisksctl umount -b /dev/sda1
udisksctl mount -b /dev/sda1
lsblk
udisksctl mount -b /dev/sda1
yazi
cd projects
git init
cd ..
cd githuub
mkdir -p github
cd github
git clone https://github.com/Mayank-cs-2004/dotfiles.git ~/dotfiles_temp\
cd ~/dotfiles_temp
ssh-keygen -t ed25519 -C "mayank.cs.2004@gmail.com"
cat ~/.ssh/id_ed25519.pub
lsblk
udisksctl mount -b /dev/sdb
lsblk
yazi
sudo nvim /etc/fstab
sudo mount -a
yazi
lsblk
lsblk\
# or\
sudo fdisk -l
sudo pacman -Syu udiskie
sudo pacman -Rns udiskie
sudo pacman -Ss udiskie
sudo pacman -Rns udiskie
sudo pacman -Rns udisks2
lsblk
hwclock --systohc
# To list all available zones\
timedatectl list-timezones\
\
# To set it (e.g., for India)\
sudo timedatectl set-timezone Asia/Kolkata
sudo timedatectl set-timezone Asia/Kolkata
timedatectl status
sudo timedatectl set-ntp true
sudo systemctl enable --now systemd-timesyncd
timedatectl status
lsblk
udisksctl mount -b /dev/sdb1
yazi
udisksctl mount -b /dev/sdb
lsblk
nvim /etc/fstab
sudo nvim /etc/fstab
udisksctl mount -b /dev/sdb
udisksctl mount -b /dev/sdb1
udisksctl umount -b /dev/sdb1
udisksctl umount /dev/sdb1
sudo umount /dev/sdb1
udisksctl umount -b /dev/sdb1
udisksctl mount -b /dev/sdb1
yazi
killall yazi
yazi
fdjadnc
cd projects
cd Downloads
yazi
cd projects
ls
nvim .
ls
cd projects
sudo pacmn - Syu
ls
cd projects
sudo pacmn - Syu
sudo pacman - Syu
sudo pacman -Syu
cd projects
source venv/bin/activate   
cd projects
cd nyc_taxi_pipeline
cd Downloads
ls
cd projects
cd nyc_taxi_pipeline
ls
cd projects
cd nyc_taxi_pipeline
ls
cd projects
ls
sudoids
ls
ls -a
ls
cd
cd projects
sudo pacman -Syu\\

sudo pacman -Syu
cd projects
sudo pacman -Syu
cd projects
cd venv
cd ..
source venv/bin/activate   
rm -rf /run/media/kuro/arch/.Trash-1000
cd Downloads
sudo pacman -Syu
ls
mkdir haha
ls
cd Downloads
ls
sudo pacman -Syu eza
ls
sudo pacman -Syu 
y
rm -rf haah
ls
rm -rf haha
ls
cd projects
ls
cd nyc_taxi_pipeline
ls
cd projects
cd nyc_taxi_pipeline
ls
starship cache clear
sudo pacman -Syu 
ls
cd projects
cd nyc_taxi_pipeline
ls
ls -a
cd projects
ls
;s
ls
cat ~/.config/foot/foot.ini | grep font
echo 'ó°ƒ¦¼'\
echo ''\
echo ''
sudo pacman -S ttf-nerd-fonts-symbols-mono
ls
echo 'ó°ƒ¦¼'\
echo ''\
echo ''
fc-cache -fv
echo 'ó°ƒ¦¼'\
echo ''\
echo ''
echo ''\
echo ''  \
echo 'ó°ƒ¦¼'\
echo 'ó±ƒ‚'
# Test a bunch of common nerd font codepoints\
echo $'\uf81f'   # python (older codepoint)\
echo $'\ue606'   # git alt\
echo $'\uf7a2'   # markdown  \
echo $'\uf489'   # terminal/shell\
echo $'\uf1d3'   # git branch alt\
echo $'\ue725'   # python alt\
echo $'\uf0e4'   # dashboard
# Test a bunch of common nerd font codepoints\
echo $'\uf81f' \
echo $'\ue606'  \
echo $'\uf7a2' \
echo $'\uf489'  \
echo $'\uf1d3'   \
echo $'\ue725'  \
echo $'\uf0e4'   
# Test these â€ƒ´ screenshot what renders\
printf '\uf0c2\n'   # cloud (aws)\
printf '\ue69b\n'   # terraform \
printf '\uf7b8\n'   # kubernetes\
printf '\uf308\n'   # docker whale\
printf '\uf121\n'   # code/node\
printf '\ue28c\n'   # markdown M\
printf '\uf15c\n'   # file/yaml
\
printf '\uf0c2\n'  \
printf '\ue69b\n'  \
printf '\uf7b8\n' \
printf '\uf308\n' \
printf '\uf121\n'  \
printf '\ue28c\n'   \
printf '\uf15c\n'  
ls
cd projects
ls
cd nyc_taxi_pipeline
ls
 sudo pacman -Rns eza
ls
cd projects
printf '\ue0a0\n'  \
printf '\uf418\n'   \
printf '\ue702\n'   \
printf '\uf7a1\n'  
cd projects
ls
cd nyc_taxi_pipeline
cd projects
printf '\uf489\n'  \
printf '\uf7a2\n'   \
printf '\uf308\n'  \
printf '\uf0c2\n' \
printf '\ue69b\n'   \
printf '\uf1d8\n'   \
printf '\ue62e\n'   \
printf '\uf489\n'  \
printf '\uf7a2\n'   \
printf '\ue28c\n'  \
printf '\uf15c\n'   \
printf '\uf017\n'   \
printf '\udb82\udd27\n'
printf '\uf668\n'  \
printf '\uf6d7\n'   \
printf '\udb84\udc82\n'\
printf '\uf77b\n'\
printf '\uf233\n' \
printf '\ue235\n'  \
printf '\uf820\n' 
printf 'ðƒ¿ƒ°ƒ­\n'\
printf 'ðƒ¿ƒ°³\n'  \
printf 'âƒ¸\n'  \
printf 'âƒºƒ¹\n'   \
printf 'ðƒ¿ƒ´·\n'
ðƒ¿ƒ²¨
ls
cd github
cd ..
cd projects
ls
cd projects
ls
ls /nonexistent
ls
source venv/bin/activate   
ls /nonexistent
ls /nonexistent   # => should turn RED\
ls               # => should turn GREEN
ls /nonexistent \
ls               
starship explain
cat ~/.config/starship.toml | head -20
echo $STARSHIP_CONFIG
grep -n "PROMPT\|prompt\|PS1\|starship" ~/.zshrc
echo $TERM\
echo $COLORTERM
print -P "%F{green}hello%f"\
print -P "%F{red}hello%f"
ls /nonexistent \

ls               
cd projects
ls
cd nyc_taxi_pipeline
ls
source ../venv/bin/activate   
cd projects
cd nyc_taxi_pipeline
ls && echo "---" && ls /nonexistent
cd ~/projects/nyc_taxi_pipeline
source ../venv/bin/activate
notacommand\
ls
sleep 3
cd ~/projects && git status
notacommand
cd projects
yazi
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
# 1. Kill any active SSH background memories\
ssh-add -D\
\
# 2. Nuclear option: Delete the entire local SSH folder and all keys inside it\
rm -rf ~/.ssh\
\
# 3. Recreate a clean, empty SSH directory with the correct secure permissions\
mkdir ~/.ssh\
chmod 700 ~/.ssh
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
ssh-keygen -t ed25519 -C "mayank.cs.2004@gmail.com"
eval "$(ssh-agent -s)"\
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
yazi
ls
cd 
[aws]
ó°¸ƒ¯ 
cd projects
[os]
echo "Testing Starship Glyphs:" && echo "  Fill Line:  âƒ´€" && echo "  Lock:       ðƒ¿ƒ´ƒ²" && echo "  Git:        ïƒ°ƒ¸" && echo "  AWS:        ó°¸ƒ¯" && echo "  Terraform:  ó±ƒ‚" && echo "  Kubernetes: ó±ƒ£¾" && echo "  Docker:     ó°ƒ¨" && echo "  Python:     ó°ƒ¬ƒ€" && echo "  NodeJS:     îƒ¼ƒ¸"
echo "Testing Starship Glyphs:" && echo "  Fill Line:  âƒ´€" && echo "  Lock:       ðƒ¿ƒ´ƒ²" && echo "  Git:        ïƒ°ƒ¸" && echo "  AWS:        ó°¸ƒ¯" && echo "  Terraform:  ó±ƒ‚" && echo "  Kubernetes: ó±ƒ£¾" && echo "  Docker:     ó°ƒ¨" && echo "  Python:     ó°ƒ¬ƒ€" && echo "  NodeJS:     ;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~;2;13~\îƒ¼ƒ¸"
ó°ƒ®ƒ¹
ó°ƒ®ƒ¹ 
nwg-look
cd projects
ó±ƒ°ƒ«
âƒ½¯
ïƒ±ƒ€
ó°ƒ¼ƒ®
ó±ƒ¾©
ïƒ¥¸
ïƒ´
îƒ¸‚
cd Downloads
yazi
nvim .config/hypr/color.css
yazi
lsblk
cd projects
source /venv/bin/activate
source venv/bin/activate
yazi
git clone https://github.com/Mayank-cs-2004/dotfiles.git~/dotfiles_temp
git clone https://github.com/Mayank-cs-2004/dotfiles.git~ /dotfiles_temp
mkdir  dotfiles_temp
git clone https://github.com/Mayank-cs-2004/dotfiles.git~ /dotfiles_temp
git clone https://github.com/Mayank-cs-2004/dotfiles.git~ dotfiles_temp
rmdir dotfiles_temp\
\
git clone git@github.com:Mayank-cs-2004/dotfiles.git ~/dotfiles_temp
cd dotfiles_temp
git checkout -b v1
git push origin v1
git checkout -b v2
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} +
cd /mnt/media/kuro/arch
cd /mnt/
cd arch
asujh
ls 
ls
cd /mnt/
ls 
cd arch
ls
yazi
swaync &
btop
p9 kill yazi
killall yazi
btop
yazi
paccache -r    
nwg-look
yazi
sudo pacman -Rns zsh-syntax-highlighting
sudols 
cd projects
cd ..
cd github
cd ..
cd dotfiles_temp
cd ..
cd projects
cd nyc_taxi_pipeline
cd data
cd ..
cd pipeline
cd ..
cd //
ls
cd //
ó°ƒ¬¾
cd /
cd //
cat ~/.config/foot/foot.ini | grep font
cd //
yazi
cd /
cd //
yazi
cd home/kuro/github
git clone https://github.com/Mayank-cs-2004/dotfiles
git clone git@github.com:Mayank-cs-2004/dotfiles.git
cd dotfiles/
ls
git rm -rf .
ls
git add .
git commit -m "v2: replace with new dotfiles"
git config --global user.email "mayank.cs.2004@gmail.com"\
git config --global user.name "Mayank-cs-2004"
git commit -m "v2: replace with new dotfiles"
git push origin main
yazi
nwg-look
hyprctl reload
nwg-look
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'\
gsettings set org.gnome.desktop.interface cursor-size 24\
hyprctl reload
yazi
hyprctl dispatch exit
yazi
yazi
ls
cd projects
cd venv
source venv/bin/activate
sudo pacman -Rns lxqt-policykit
rm /var/lib/pacman/db.lck    &&  sudo pacman -Rns lxqt-policykit 
rm /var/lib/pacman/db.lck
sudo pacman -Rns lxqt-policykit
hyprctl reload
yazi
pgrep -a polkit
/usr/lib/lxqt-policykit-agent &
yazi
pacman -Ql lxqt-policykit | grep bin
which lxqt-policykit-agent
hyprctl reload
/usr/bin/lxqt-policykit-agent &\
pkexec efibootmgr --bootnext 0002
yay -S hyprpolkit
yay -Ss hyprpolkit
yay -Ss hyprpolkitagent
yay -Syu hyprpolkitagent
pkill lxqt-policykit-agent\
hyprpolkit &\
pkexec efibootmgr --bootnext 0002
pacman -Qqem
yay -S hyprpolkitagent
pacman -Qqem
pacman -Qqen
pkill lxqt-policykit-agent\
hyprpolkit &\
pkexec efibootmgr --bootnext 0002
ls
cd projects
source venv/bin/activate
yazi
ls
yazi
cd run/media/arch
cd /run/media/arch
cd run
cd run/
cd ..
cd /
cd run/media/kuro
cd arch/dotfiles
ls
rm -rf .
rm -rf ./
yazi
which hyprpolkitagent\
hyprpolkitagent &\
pkexec efibootmgr --bootnext 0002
pacman -Ql hyprpolkitagent | grep bin
systemctl --user start hyprpolkitagent
systemctl --user start hyprpolkitagent\
pkexec efibootmgr --bootnext 0002
yay -Ss hyprpolkitagent
cd github
cd dotfiles
ls
git add .\
git commit -m "add README and arch install guide"\
git push origin main
git add .\
git commit -m "add README and arch install guidie and screenshots"\
git push origin main
ls
git add .\
git commit -m "updated README.md"\
git push origin main
cd .. && rm -rf dotfiles && mkdir dotfiles && cd dotfiles
ls
ls -a
cd clone https://github.com/Mayank-cs-2004/dotfiles.git
git clone https://github.com/Mayank-cs-2004/dotfiles.git
killall yazi
pkill -9 yazi
yazi
yazi
pkill -9 yazi
killall yazi
fastfetch
cd projects
ls
git init\
git remote add origin https://github.com/Mayank-cs-2004/nyc_taxi_pipeline.git
git checkout -b month-1-basic-pipeline\
git add .\
git commit -m "Month 1: Basic Python ETL pipeline with pandas"\
git push -u origin month-1-basic-pipeline
git remote remove origin\
git remote add origin git@github.com:YOUR_USERNAME/nyc-taxi-pipeline.git\
git push -u origin month-1-basic-pipeline
git remote add origin git@github.com:YOUR_USERNAME/nyc-taxi-pipeline.git\
git branch -M main\
git push -u origin main\
git push -u origin month-1-basic-pipeline
git remote add origin git@github.com:Mayank-cs-2004/nyc-taxi-pipeline.git\
git branch -M main\
git push -u origin main\
git push -u origin month-1-basic-pipeline
git remote remove origin
git remote add origin git@github.com:Mayank-cs-2004/nyc-taxi-pipeline.git
git branch -M main
git push -u origin main
git push -u origin month-1-basic-pipeline
git rm --cached data/raw/*.parquet data/processed/*.parquet 2>/dev/null\
git rm --cached data/processed/*.csv 2>/dev/null
cat > .gitignore << 'EOF'\
data/raw/\
data/processed/\
__pycache__/\
*.pyc\
venv/\
.env\
EOF
git add .gitignore\
git commit -m "Move data to gitignore, add download script"\
git push -u origin month-1-basic-pipeline
cd projects
yazi
sudo pacman -Ss postgre
sudo pacman -S postgresql
sudo -u postgres initdb -D /var/lib/postgres/data
sudo systemctl start postgresql\
sudo systemctl enable postgresql  # auto-start on boot
sudo systemctl start postgresql\
sudo systemctl enable postgresql 
git add .gitignore\
git commit -m "Move data to gitignore, add download script"\
git push -u origin month-1-basic-pipeline
git push -u origin main
git checkout -b month-1-basic-pipeline\
\
git push -u origin month-1-basic-pipeline\
\
git checkout main\
\
git merge month-1-basic-pipeline\
\
git push origin main
sudo -u postgres psql -c "SELECT version();"
_postgresql --verssion
sudo -u postgres createdb nyc_taxi
sudo -u postgres createuser -P nyc_user
sudo -u postgres psql << EOF\
ALTER USER nyc_user WITH CREATEDB;\
GRANT ALL PRIVILEGES ON DATABASE nyc_taxi TO nyc_user;\
EOF
yazi
killall gvfsd
yazi
gvfs-mount -l
sudo pacman -Syu gvfs
sudo pacman -Ss gvfs-mtp 
sudo pacman -Syu gvfs-mtp 
gvfs-mount -l
gvfs-mount mtp://
sudo pacman -Syu gvfs
gvfs-mount -l
gio mount mtp://
gio mount -l
gio mount gproxy+mtp://HFM512GD3JX016N
sudo pacman -Rns gvfs gvfs-mtp  # Remove gvfs first\
sudo pacman -S jmtpfs
sudo pacman -Rns gvfs gvfs-mtp  \
sudo pacman -S jmtpfs
sudo pacman -Ss jmtpfs
sudo pacman -Ss jmtp
yay -Ss jmtpfs
yay -Syu jmtpfs
mkdir -p ~/android\
jmtpfs ~/android\
yazi ~/android
jmtpfs ~/android\
yazi ~/android
jmtpfs ~/android
# Kill any hung jmtpfs processes first\
pkill -9 jmtpfs\
sleep 2\
\
# Replug USB cable, then:\
jmtpfs ~/android
jmtpfs -d 0 ~/android
sudo pacman -Rns jmtpfs
sudo pacman -Ss simple-mtpfs
yay -Ss simple-mtpfs
yay -Syu simple-mtpfs
simple-mtpfs ~/android\
yazi ~/android
yazi
simple-mtpfs ~/android
yazi
simple-mtpfs ~/android
simple-mtpfs ~/android\
yazi ~/android
sudo pacman -Rns simple-mtpfs
which java\
ls -la /usr/lib/jvm/
echo 'export JAVA_HOME=/usr/lib/jvm/default' >> ~/.bashrc\
source ~/.bashrc
echo $JAVA_HOME\
java -version
python main.py
yazi
pkill -9 yazi
pkill -9 nvim
cd projects
cd nyc_taxi_pipeline
python main.py
source venv/bin/activate
source ../venv/bin/activate
pip install -r requirements.txt
python main.py
java -version
sudo pacman -S jdk17-openjdk
pacman -Qqen
sudo pacman -Rns jdk-openjdk
sudo pacman -Syu jdk17-openjdk
python main.py
git checkout -b level-3-spark\
git add pipeline/extract.py pipeline/validate.py pipeline/transform.py requirements.txt\
git commit -m "Level 3: Add Spark for distributed processing"\
git push -u origin level-3-spark
git checkout -b level-3-spark
git add pipeline/extract.py pipeline/validate.py pipeline/transform.py requirements.txt
git commit -m "Level 3: Add Spark for distributed processing"
git push -u origin level-3-spark
which ssh
echo $PATH
source ~/.bashrc\
which ssh\
ssh
which ssh
ls /usr/bin/ssh
echo $SHELL
sudo pacman -S openssh
which ssh
git push -u origin level-3-spark
pip install dbt-postgres
dbt init taxi_dbt\
cd taxi_dbt
cat > taxi_dbt/dbt_project.yml << 'EOF'\
name: 'taxi_dbt'\
version: '1.0.0'\
config-version: 2\
\
profile: 'taxi_dbt'\
\
model-paths: ["models"]\
analysis-paths: ["analyses"]\
test-paths: ["tests"]\
data-paths: ["data"]\
macro-paths: ["macros"]\
snapshot-paths: ["snapshots"]\
\
target-path: "target"\
clean-targets:\
  - "target"\
  - "dbt_packages"\
\
models:\
  taxi_dbt:\
    staging:\
      materialized: view\
    marts:\
      materialized: table\
EOF
ls
cd ..
cat > taxi_dbt/dbt_project.yml << 'EOF'\
name: 'taxi_dbt'\
version: '1.0.0'\
config-version: 2\
\
profile: 'taxi_dbt'\
\
model-paths: ["models"]\
analysis-paths: ["analyses"]\
test-paths: ["tests"]\
data-paths: ["data"]\
macro-paths: ["macros"]\
snapshot-paths: ["snapshots"]\
\
target-path: "target"\
clean-targets:\
  - "target"\
  - "dbt_packages"\
\
models:\
  taxi_dbt:\
    staging:\
      materialized: view\
    marts:\
      materialized: table\
EOF
mkdir -p taxi_dbt/models/staging\
cat > taxi_dbt/models/staging/stg_taxi_trips.sql << 'EOF'\
{{ config(materialized='view') }}\
\
select\
    vendor_id,\
    tpep_pickup_datetime,\
    tpep_dropoff_datetime,\
    passenger_count,\
    trip_distance,\
    fare_amount,\
    extra,\
    mta_tax,\
    tip_amount,\
    tolls_amount,\
    total_amount,\
    payment_type,\
    PULocationID,\
    DOLocationID\
from {{ source('raw', 'taxi_trips_raw') }}\
where \
    trip_distance > 0\
    and fare_amount > 0\
    and passenger_count > 0\
    and PULocationID is not null\
    and DOLocationID is not null\
EOF
mkdir -p taxi_dbt/models/marts\
cat > taxi_dbt/models/marts/fct_taxi_trips.sql << 'EOF'\
{{ config(materialized='table') }}\
\
select\
    vendor_id,\
    tpep_pickup_datetime,\
    tpep_dropoff_datetime,\
    passenger_count,\
    trip_distance,\
    fare_amount,\
    extract(hour from tpep_pickup_datetime) as pickup_hour,\
    to_char(tpep_pickup_datetime, 'Day') as pickup_day_of_week,\
    round((fare_amount / trip_distance)::numeric, 2) as cost_per_mile,\
    round(\
        extract(epoch from (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60::numeric, \
        2\
    ) as trip_duration_minutes,\
    PULocationID,\
    DOLocationID\
from {{ ref('stg_taxi_trips') }}\
where\
    extract(epoch from (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60 between 1 and 300\
EOF
cat > taxi_dbt/models/sources.yml << 'EOF'\
version: 2\
\
sources:\
  - name: raw\
    database: nyc_taxi\
    schema: raw\
    tables:\
      - name: taxi_trips_raw\
        description: "Raw taxi trip data from NYC"\
        columns:\
          - name: vendor_id\
            description: "Taxi vendor ID"\
          - name: trip_distance\
            description: "Trip distance in miles"\
          - name: fare_amount\
            description: "Fare in dollars"\
\
models:\
  - name: stg_taxi_trips\
    description: "Cleaned taxi trips (staging)"\
    \
  - name: fct_taxi_trips\
    description: "Business-ready taxi facts with computed metrics"\
EOF
cat > main.py << 'EOF'\
from pipeline.extract import extract\
from pipeline.validate import validate\
from pipeline.load import load\
import subprocess\
\
RAW_FILE = "data/raw/yellow_tripdata_2026-01.parquet"\
\
if __name__ == "__main__":\
    print("Starting pipeline...\n")\
\
    # Extract & validate with Spark\
    df = extract(RAW_FILE)\
    validate(df)\
    \
    # Load RAW data to Postgres (no transform in Python)\
    print("\n[load] Loading raw data to Postgres...")\
    load(df)\
    \
    # Let dbt handle transformations\
    print("\n[dbt] Running dbt transformations...")\
    result = subprocess.run(\
        ["dbt", "run", "--project-dir", "taxi_dbt"],\
        cwd=".",\
        capture_output=True,\
        text=True\
    )\
    \
    if result.returncode == 0:\
        print("[dbt] âƒ¼ƒ¥ Transformations complete!")\
        print(result.stdout)\
    else:\
        print("[dbt] âƒ½ƒ¬ Error running dbt:")\
        print(result.stderr)\
        raise Exception("dbt run failed")\
\
    print("\nPipeline complete.")\
EOF
cat > pipeline/load.py << 'EOF'\
import psycopg2\
from config import DB_CONFIG\
\
def load(df):\
    """Load Spark DataFrame to raw schema in Postgres"""\
    print("[load] Connecting to Postgres...")\
    \
    try:\
        conn = psycopg2.connect(**DB_CONFIG)\
        cursor = conn.cursor()\
        \
        # Create raw schema\
        cursor.execute("CREATE SCHEMA IF NOT EXISTS raw;")\
        \
        # Drop raw table if exists\
        cursor.execute("DROP TABLE IF EXISTS raw.taxi_trips_raw CASCADE;")\
        \
        # Create raw table\
        cursor.execute("""\
            CREATE TABLE raw.taxi_trips_raw (\
                vendor_id INTEGER,\
                tpep_pickup_datetime TIMESTAMP,\
                tpep_dropoff_datetime TIMESTAMP,\
                passenger_count INTEGER,\
                trip_distance NUMERIC,\
                fare_amount NUMERIC,\
                extra NUMERIC,\
                mta_tax NUMERIC,\
                tip_amount NUMERIC,\
                tolls_amount NUMERIC,\
                total_amount NUMERIC,\
                payment_type INTEGER,\
                PULocationID INTEGER,\
                DOLocationID INTEGER\
            );\
        """)\
        print("[load] Raw table created!")\
        \
        # Convert to pandas and insert\
        print(f"[load] Inserting {df.count():,} rows...")\
        pandas_df = df.select([\
            'VendorID', 'tpep_pickup_datetime', 'tpep_dropoff_datetime',\
            'passenger_count', 'trip_distance', 'fare_amount',\
            'extra', 'mta_tax', 'tip_amount', 'tolls_amount', 'total_amount',\
            'payment_type', 'PULocationID', 'DOLocationID'\
        ]).toPandas()\
        \
        for idx, row in pandas_df.iterrows():\
            cursor.execute("""\
                INSERT INTO raw.taxi_trips_raw VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\
            """, tuple(row))\
        \
        conn.commit()\
        print(f"[load] âƒ¼ƒ¥ {len(pandas_df):,} rows loaded to raw schema!")\
        \
        cursor.close()\
        conn.close()\
        \
    except psycopg2.Error as e:\
        print(f"[load] âƒ½ƒ¬ Error: {e}")\
        raise\
EOF
python main.py
cat > pipeline/load.py << 'EOF'\
from config import DB_CONFIG\
\
def load(df):\
    """Write Spark DataFrame directly to Postgres using JDBC"""\
    print("[load] Writing to Postgres via JDBC...")\
    \
    # Create raw schema first\
    import psycopg2\
    conn = psycopg2.connect(**DB_CONFIG)\
    cursor = conn.cursor()\
    cursor.execute("CREATE SCHEMA IF NOT EXISTS raw;")\
    cursor.execute("DROP TABLE IF EXISTS raw.taxi_trips_raw CASCADE;")\
    conn.commit()\
    conn.close()\
    print("[load] Raw schema ready!")\
    \
    # Write Spark DataFrame directly to Postgres\
    df.write \\
        .format("jdbc") \\
        .mode("overwrite") \\
        .option("url", f"jdbc:postgresql://{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}") \\
        .option("dbtable", "raw.taxi_trips_raw") \\
        .option("user", DB_CONFIG['user']) \\
        .option("password", DB_CONFIG['password']) \\
        .option("driver", "org.postgresql.Driver") \\
        .save()\
    \
    print(f"[load] âƒ¼ƒ¥ Data written to raw.taxi_trips_raw!")\
EOF
cat >> requirements.txt << 'EOF'\
dbt-postgres\
EOF
pip install -r requirements.txt
python main.py
cd projects
ls
cd nyc_taxi_pipeline
cat > pipeline/load.py << 'EOF'\
from config import DB_CONFIG\
\
def load(df):\
    """Write Spark DataFrame directly to Postgres using JDBC"""\
    print("[load] Writing to Postgres via JDBC...")\
    \
    # Create raw schema first\
    import psycopg2\
    conn = psycopg2.connect(**DB_CONFIG)\
    cursor = conn.cursor()\
    cursor.execute("CREATE SCHEMA IF NOT EXISTS raw;")\
    cursor.execute("DROP TABLE IF EXISTS raw.taxi_trips_raw CASCADE;")\
    conn.commit()\
    conn.close()\
    print("[load] Raw schema ready!")\
    \
    # Write Spark DataFrame directly to Postgres\
    df.write \\
        .format("jdbc") \\
        .mode("overwrite") \\
        .option("url", f"jdbc:postgresql://{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}") \\
        .option("dbtable", "raw.taxi_trips_raw") \\
        .option("user", DB_CONFIG['user']) \\
        .option("password", DB_CONFIG['password']) \\
        .option("driver", "org.postgresql.Driver") \\
        .save()\
    \
    print(f"[load] âƒ¼ƒ¥ Data written to raw.taxi_trips_raw!")\
EOF
source ../venv/bin/activate
pip install -r requirements.txt
python main.py
cat > pipeline/extract.py << 'EOF'\
from pyspark.sql import SparkSession\
\
def extract(filepath: str):\
    """Load parquet file as Spark DataFrame"""\
    spark = SparkSession.builder \\
        .appName("nyc_taxi_pipeline") \\
        .config("spark.jars.packages", "org.postgresql:postgresql:42.7.1") \\
        .getOrCreate()\
    \
    print(f"[extract] Loading {filepath} with Spark...")\
    df = spark.read.parquet(filepath)\
    \
    print(f"[extract] Loaded {df.count():,} rows, {len(df.columns)} columns")\
    print(f"[extract] Schema:")\
    df.printSchema()\
    \
    return df\
EOF
python main.py
dbt init taxi_dbt
mkdir -p taxi_dbt/models/staging\
mkdir -p taxi_dbt/models/marts
cat > taxi_dbt/models/staging/stg_taxi_trips.sql << 'EOF'\
{{ config(materialized='view') }}\
\
select\
    vendor_id,\
    tpep_pickup_datetime,\
    tpep_dropoff_datetime,\
    passenger_count,\
    trip_distance,\
    fare_amount,\
    extra,\
    mta_tax,\
    tip_amount,\
    tolls_amount,\
    total_amount,\
    payment_type,\
    PULocationID,\
    DOLocationID\
from {{ source('raw', 'taxi_trips_raw') }}\
where \
    trip_distance > 0\
    and fare_amount > 0\
    and passenger_count > 0\
    and PULocationID is not null\
    and DOLocationID is not null\
EOF
cat > taxi_dbt/models/marts/fct_taxi_trips.sql << 'EOF'\
{{ config(materialized='table') }}\
\
select\
    vendor_id,\
    tpep_pickup_datetime,\
    tpep_dropoff_datetime,\
    passenger_count,\
    trip_distance,\
    fare_amount,\
    extract(hour from tpep_pickup_datetime) as pickup_hour,\
    to_char(tpep_pickup_datetime, 'Day') as pickup_day_of_week,\
    round((fare_amount / trip_distance)::numeric, 2) as cost_per_mile,\
    round(\
        extract(epoch from (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60::numeric, \
        2\
    ) as trip_duration_minutes,\
    PULocationID,\
    DOLocationID\
from {{ ref('stg_taxi_trips') }}\
where\
    extract(epoch from (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60 between 1 and 300\
EOF
cat > taxi_dbt/models/sources.yml << 'EOF'\
version: 2\
\
sources:\
  - name: raw\
    database: nyc_taxi\
    schema: raw\
    tables:\
      - name: taxi_trips_raw\
        description: "Raw taxi trip data from NYC"\
        columns:\
          - name: vendor_id\
            description: "Taxi vendor ID"\
\
models:\
  - name: stg_taxi_trips\
    description: "Cleaned staging table"\
    \
  - name: fct_taxi_trips\
    description: "Business facts with metrics"\
EOF
cd taxi_dbt\
dbt debug
dbt run
cat > ~/.dbt/profiles.yml << 'EOF'\
taxi_dbt:\
  outputs:\
    dev:\
      type: postgres\
      host: localhost\
      user: postgres\
      password: postgres\
      port: 5432\
      dbname: nyc_taxi\
      schema: analytics\
      threads: 1\
      keepalives_idle: 0\
  target: dev\
EOF
cat > taxi_dbt/models/sources.yml << 'EOF'\
version: 2\
\
sources:\
  - name: raw\
    schema: raw\
    tables:\
      - name: taxi_trips_raw\
        description: "Raw taxi trip data"\
\
models:\
  - name: stg_taxi_trips\
    description: "Cleaned staging table"\
    \
  - name: fct_taxi_trips\
    description: "Business facts table"\
EOF
dbt debug\
dbt run
cd ..\
python main.py
cat > main.py << 'EOF'\
from pipeline.extract import extract\
from pipeline.validate import validate\
from pipeline.load import load\
import subprocess\
import os\
\
RAW_FILE = "data/raw/yellow_tripdata_2026-01.parquet"\
\
if __name__ == "__main__":\
    print("Starting pipeline...\n")\
\
    # Extract & validate with Spark\
    df = extract(RAW_FILE)\
    validate(df)\
    \
    # Load RAW data to Postgres\
    print("\n[load] Loading raw data to Postgres...")\
    load(df)\
    \
    # Run dbt transformations\
    print("\n[dbt] Running dbt transformations...")\
    result = subprocess.run(\
        ["dbt", "run"],\
        cwd="taxi_dbt",\
        capture_output=True,\
        text=True\
    )\
    \
    print(result.stdout)\
    if result.stderr:\
        print("STDERR:", result.stderr)\
    \
    if result.returncode != 0:\
        print(f"[dbt] âƒ½ƒ¬ dbt failed with return code {result.returncode}")\
        raise Exception("dbt run failed")\
    else:\
        print("[dbt] âƒ¼ƒ¥ Transformations complete!")\
\
    print("\nPipeline complete.")\
EOF
python main.py
cat > taxi_dbt/models/staging/stg_taxi_trips.sql << 'EOF'\
{{ config(materialized='view') }}\
\
select\
    "VendorID" as vendor_id,\
    tpep_pickup_datetime,\
    tpep_dropoff_datetime,\
    passenger_count,\
    trip_distance,\
    fare_amount,\
    extra,\
    mta_tax,\
    tip_amount,\
    tolls_amount,\
    total_amount,\
    payment_type,\
    "PULocationID",\
    "DOLocationID"\
from {{ source('raw', 'taxi_trips_raw') }}\
where \
    trip_distance > 0\
    and fare_amount > 0\
    and passenger_count > 0\
    and "PULocationID" is not null\
    and "DOLocationID" is not null\
EOF
cat > taxi_dbt/models/marts/fct_taxi_trips.sql << 'EOF'\
{{ config(materialized='table') }}\
\
select\
    vendor_id,\
    tpep_pickup_datetime,\
    tpep_dropoff_datetime,\
    passenger_count,\
    trip_distance,\
    fare_amount,\
    extract(hour from tpep_pickup_datetime) as pickup_hour,\
    to_char(tpep_pickup_datetime, 'Day') as pickup_day_of_week,\
    round((fare_amount / trip_distance)::numeric, 2) as cost_per_mile,\
    round(\
        extract(epoch from (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60::numeric, \
        2\
    ) as trip_duration_minutes,\
    "PULocationID",\
    "DOLocationID"\
from {{ ref('stg_taxi_trips') }}\
where\
    extract(epoch from (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60 between 1 and 300\
EOF
python main.py
cd ..\
git checkout -b level-4-dbt\
git add main.py pipeline/extract.py pipeline/load.py taxi_dbt/\
git commit -m "Level 4: Add dbt for SQL transformations - data transformed inside Postgres with lineage tracking"\
git push -u origin level-4-dbt
brightnessctl set 100%
btop
pkill -9 postgresql
btop
pkill -9 postgres
sudo pkill -9 postgres
btop
yazi
yay -Ss localsend
yay -Syu localsend-bin
cat ~/airflow/simple_auth_manager_passwords.json.generated
cd projects
ls
source /venv/bin/activate
source venv/bin/activate
pip install apache-airflow
airflow db init\
airflow users create \\
    --username admin \\
    --password admin \\
    --firstname Mayank \\
    --lastname Dev \\
    --role Admin \\
    --email admin@example.com
airflow db init\
airflow users create \\
    --username admin \\
    --password admin \\
    --firstname Mayank \\
    --lastname Dev \\
    --role Admin \\
    --email mayank.cs.2004@gmail.com
airflow db migrate
airflow standalone
cd projects
source venv/bin/activate
airflow config get-value core dags_folder
cp ~/projects/nyc_taxi_pipeline/dags/taxi_pipeline_dag.py ~/airflow/dags/
cd ..
cp ~/projects/nyc_taxi_pipeline/dags/taxi_pipeline_dag.py ~/airflow/dags/
cd ..
ls
cd kuro
ls
cp ~/projects/nyc_taxi_pipeline/dags/taxi_pipeline_dag.py ~/airflow/dags/
mkdir -p ~/airflow/dags\
cat > ~/airflow/dags/taxi_pipeline_dag.py << 'EOF'\
from airflow import DAG\
from airflow.operators.python import PythonOperator\
from datetime import datetime, timedelta\
import sys\
\
sys.path.insert(0, '/home/kuro/projects/nyc_taxi_pipeline')\
\
default_args = {\
    'owner': 'mayank',\
    'depends_on_past': False,\
    'start_date': datetime(2026, 1, 1),\
    'retries': 1,\
    'retry_delay': timedelta(minutes=5),\
}\
\
dag = DAG(\
    'nyc_taxi_pipeline',\
    default_args=default_args,\
    description='NYC Taxi: Spark âƒ¦ƒ² Postgres âƒ¦ƒ² dbt',\
    schedule_interval='@daily',\
    catchup=False,\
)\
\
def run_extract_and_load():\
    from pipeline.extract import extract\
    from pipeline.validate import validate\
    from pipeline.load import load\
    RAW_FILE = "/home/kuro/projects/nyc_taxi_pipeline/data/raw/yellow_tripdata_2026-01.parquet"\
    df = extract(RAW_FILE)\
    validate(df)\
    load(df)\
\
def run_dbt():\
    import subprocess\
    result = subprocess.run(\
        ["dbt", "run"],\
        cwd="/home/kuro/projects/nyc_taxi_pipeline/taxi_dbt",\
        capture_output=True,\
        text=True\
    )\
    print(result.stdout)\
    if result.returncode != 0:\
        raise Exception(f"dbt failed: {result.stderr}")\
\
def run_dbt_tests():\
    import subprocess\
    result = subprocess.run(\
        ["dbt", "test"],\
        cwd="/home/kuro/projects/nyc_taxi_pipeline/taxi_dbt",\
        capture_output=True,\
        text=True\
    )\
    print(result.stdout)\
    if result.returncode != 0:\
        raise Exception(f"dbt tests failed: {result.stderr}")\
\
extract_load_task = PythonOperator(\
    task_id='extract_and_load',\
    python_callable=run_extract_and_load,\
    dag=dag,\
)\
\
dbt_run_task = PythonOperator(\
    task_id='dbt_transform',\
    python_callable=run_dbt,\
    dag=dag,\
)\
\
dbt_test_task = PythonOperator(\
    task_id='dbt_test',\
    python_callable=run_dbt_tests,\
    dag=dag,\
)\
\
extract_load_task >> dbt_run_task >> dbt_test_task\
EOF
airflow dags list
ls ~/airflow/dags/
cat > ~/airflow/dags/taxi_pipeline_dag.py << 'EOF'\
from airflow.sdk import dag, task\
from datetime import datetime, timedelta\
import sys\
\
sys.path.insert(0, '/home/kuro/projects/nyc_taxi_pipeline')\
\
@dag(\
    dag_id='nyc_taxi_pipeline',\
    start_date=datetime(2026, 1, 1),\
    schedule='@daily',\
    catchup=False,\
    tags=['nyc', 'taxi', 'spark', 'dbt'],\
)\
def nyc_taxi_pipeline():\
\
    @task()\
    def extract_and_load():\
        from pipeline.extract import extract\
        from pipeline.validate import validate\
        from pipeline.load import load\
        RAW_FILE = "/home/kuro/projects/nyc_taxi_pipeline/data/raw/yellow_tripdata_2026-01.parquet"\
        df = extract(RAW_FILE)\
        validate(df)\
        load(df)\
\
    @task()\
    def dbt_transform():\
        import subprocess\
        result = subprocess.run(\
            ["dbt", "run"],\
            cwd="/home/kuro/projects/nyc_taxi_pipeline/taxi_dbt",\
            capture_output=True,\
            text=True\
        )\
        print(result.stdout)\
        if result.returncode != 0:\
            raise Exception(f"dbt failed: {result.stderr}")\
\
    @task()\
    def dbt_test():\
        import subprocess\
        result = subprocess.run(\
            ["dbt", "test"],\
            cwd="/home/kuro/projects/nyc_taxi_pipeline/taxi_dbt",\
            capture_output=True,\
            text=True\
        )\
        print(result.stdout)\
        if result.returncode != 0:\
            raise Exception(f"dbt tests failed: {result.stderr}")\
\
    extract_and_load() >> dbt_transform() >> dbt_test()\
\
nyc_taxi_pipeline()\
EOF
airflow dags list | grep nyc
python ~/airflow/dags/taxi_pipeline_dag.py
airflow dags list --bundle-name dags-folder | grep nyc
airflow dags list | grep nyc
python ~/airflow/dags/taxi_pipeline_dag.py
airflow dags list | grep nyc
sudo systemctl start postgresql
rm -rf ~/projects/nyc_taxi_pipeline/taxi_dbt/models/example
cd ~/projects/nyc_taxi_pipeline\
source ~/projects/venv/bin/activate
git checkout -b level-5-airflow
git add dags/ main.py\
git commit -m "Level 5: Add Airflow orchestration - pipeline now runs on schedule with monitoring"
git push -u origin level-5-airflow
git checkout main\
git merge level-5-airflow\
git push origin main
cd ..
ls
cd kuro
ls
mkdir ~/.aws/credentials
mkdir .aws/credentials
mkdir -p ~/.aws
ls
cd .aws
cd ..
cat > ~/.aws/credentials << 'EOF'\
[default]\
aws_access_key_id = YOUR_NEW_ACCESS_KEY_ID\
aws_secret_access_key = YOUR_NEW_SECRET_ACCESS_KEY\
EOF
cat > ~/.aws/credentials << 'EOF'\
[default]\
aws_access_key_id = AKIARSTZ2R3WLMHLQLUH\
aws_secret_access_key = 5snfQYaqACLweQ2RTv3D475PqFGMwhbXm1E7uO8u\
EOF
cat ~/.aws/credentials
echo "boto3" >> requirements.txt\
echo "requests" >> requirements.txt\
pip install -r requirements.txt
cat > pipeline/fetch_crypto.py << 'EOF'\
import requests\
import json\
import os\
from datetime import datetime\
\
def fetch_crypto_data():\
    """Fetches top 100 cryptocurrencies by market cap from CoinGecko"""\
    print("[extract] Fetching live crypto data from CoinGecko...")\
    \
    url = "https://api.coingecko.com/api/v3/coins/markets"\
    params = {\
        "vs_currency": "usd",\
        "order": "market_cap_desc",\
        "per_page": 100,\
        "page": 1,\
        "sparkline": "false"\
    }\
    \
    response = requests.get(url, params=params)\
    response.raise_for_status()\
    \
    data = response.json()\
    \
    # Save locally first\
    os.makedirs("data/raw", exist_ok=True)\
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")\
    filepath = f"data/raw/crypto_market_{timestamp}.json"\
    \
    with open(filepath, "w") as f:\
        json.dump(data, f)\
        \
    print(f"[extract] âƒ¼ƒ¥ Saved {len(data)} coins to {filepath}")\
    return filepath\
\
if __name__ == "__main__":\
    fetch_crypto_data()\
EOF
ls
cd projects
ls
cat > pipeline/fetch_crypto.py << 'EOF'\
import requests\
import json\
import os\
from datetime import datetime\
\
def fetch_crypto_data():\
    """Fetches top 100 cryptocurrencies by market cap from CoinGecko"""\
    print("[extract] Fetching live crypto data from CoinGecko...")\
    \
    url = "https://api.coingecko.com/api/v3/coins/markets"\
    params = {\
        "vs_currency": "usd",\
        "order": "market_cap_desc",\
        "per_page": 100,\
        "page": 1,\
        "sparkline": "false"\
    }\
    \
    response = requests.get(url, params=params)\
    response.raise_for_status()\
    \
    data = response.json()\
    \
    # Save locally first\
    os.makedirs("data/raw", exist_ok=True)\
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")\
    filepath = f"data/raw/crypto_market_{timestamp}.json"\
    \
    with open(filepath, "w") as f:\
        json.dump(data, f)\
        \
    print(f"[extract] âƒ¼ƒ¥ Saved {len(data)} coins to {filepath}")\
    return filepath\
\
if __name__ == "__main__":\
    fetch_crypto_data()\
EOF
cd nyc_taxi_pipeline
ls
cat > pipeline/fetch_crypto.py << 'EOF'\
import requests\
import json\
import os\
from datetime import datetime\
\
def fetch_crypto_data():\
    """Fetches top 100 cryptocurrencies by market cap from CoinGecko"""\
    print("[extract] Fetching live crypto data from CoinGecko...")\
    \
    url = "https://api.coingecko.com/api/v3/coins/markets"\
    params = {\
        "vs_currency": "usd",\
        "order": "market_cap_desc",\
        "per_page": 100,\
        "page": 1,\
        "sparkline": "false"\
    }\
    \
    response = requests.get(url, params=params)\
    response.raise_for_status()\
    \
    data = response.json()\
    \
    # Save locally first\
    os.makedirs("data/raw", exist_ok=True)\
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")\
    filepath = f"data/raw/crypto_market_{timestamp}.json"\
    \
    with open(filepath, "w") as f:\
        json.dump(data, f)\
        \
    print(f"[extract] âƒ¼ƒ¥ Saved {len(data)} coins to {filepath}")\
    return filepath\
\
if __name__ == "__main__":\
    fetch_crypto_data()\
EOF
python pipeline/fetch_crypto.py
cat > pipeline/load_s3.py << 'EOF'\
import boto3\
import os\
\
# Your specific bucket name from the screenshot\
BUCKET_NAME = "nyc-taxi-pipeline-kuro-2026"\
\
def upload_to_s3(filepath):\
    """Uploads a local file to the raw/ folder in S3"""\
    print(f"[load_s3] Connecting to AWS S3...")\
    \
    # boto3 automatically uses the ~/.aws/credentials file we made!\
    s3_client = boto3.client('s3')\
    \
    file_name = os.path.basename(filepath)\
    # We organize it into a 'raw/crypto/' folder inside the bucket\
    s3_key = f"raw/crypto/{file_name}"\
    \
    print(f"[load_s3] Uploading {file_name} to s3://{BUCKET_NAME}/{s3_key}...")\
    \
    try:\
        s3_client.upload_file(filepath, BUCKET_NAME, s3_key)\
        print(f"[load_s3] âƒ¼ƒ¥ Successfully uploaded to S3!")\
        return f"s3://{BUCKET_NAME}/{s3_key}"\
    except Exception as e:\
        print(f"[load_s3] âƒ½ƒ¬ Error uploading to S3: {e}")\
        raise\
\
if __name__ == "__main__":\
    print("Run this via the main pipeline!")\
EOF
cat > run_crypto.py << 'EOF'\
from pipeline.fetch_crypto import fetch_crypto_data\
from pipeline.load_s3 import upload_to_s3\
import os\
\
if __name__ == "__main__":\
    print("ðƒ¿ƒº€ Starting Crypto API Pipeline...\n")\
    \
    # 1. Extract\
    filepath = fetch_crypto_data()\
    \
    # 2. Load to S3\
    s3_uri = upload_to_s3(filepath)\
    \
    # 3. Clean up local file (optional, but good practice since it's in the cloud now!)\
    os.remove(filepath)\
    print(f"\n[cleanup] Removed local file {filepath}")\
    \
    print("\nâƒ¼ƒ¥ Crypto Pipeline complete!")\
EOF
python run_crypto.py
cat > ~/airflow/dags/crypto_pipeline_dag.py << 'EOF'\
from airflow.sdk import dag, task\
from datetime import datetime\
import sys\
\
# Tell Airflow where your project is\
sys.path.insert(0, '/home/kuro/projects/nyc_taxi_pipeline')\
\
@dag(\
    dag_id='crypto_s3_pipeline',\
    start_date=datetime(2026, 1, 1),\
    schedule='@hourly', # Let's run this every hour to get fresh prices!\
    catchup=False,\
    tags=['crypto', 's3', 'api'],\
)\
def crypto_s3_pipeline():\
\
    @task()\
    def fetch_and_load_to_s3():\
        from pipeline.fetch_crypto import fetch_crypto_data\
        from pipeline.load_s3 import upload_to_s3\
        import os\
        \
        # 1. Fetch from API\
        filepath = fetch_crypto_data()\
        \
        # 2. Upload to S3\
        s3_uri = upload_to_s3(filepath)\
        \
        # 3. Clean up local runner\
        os.remove(filepath)\
        print(f"[airflow] âƒ¼ƒ¥ Success! Data landed in {s3_uri}")\
\
    fetch_and_load_to_s3()\
\
crypto_s3_pipeline()\
EOF
pip install streamlit pandas psycopg2-binary
cat > dashboard.py << 'EOF'\
import streamlit as st\
import pandas as pd\
import psycopg2\
import boto3\
import json\
from config import DB_CONFIG\
\
st.set_page_config(page_title="NYC Data & Crypto Hub", layout="wide")\
st.title("ðƒ¿ƒ³ƒª Enterprise Data Hub")\
st.markdown("Powered by **Spark, Postgres, dbt, Airflow, and AWS S3**")\
\
# --- TAB 1: NYC TAXI DATA (From Postgres) ---\
st.header("ðƒ¿ƒºƒµ NYC Taxi Analytics (from dbt)")\
\
@st.cache_data(ttl=600)\
def load_taxi_data():\
    conn = psycopg2.connect(**DB_CONFIG)\
    # Query the facts table dbt built for us!\
    query = """\
        SELECT pickup_day_of_week, COUNT(*) as trip_count, AVG(fare_amount) as avg_fare\
        FROM analytics.fct_taxi_trips\
        GROUP BY pickup_day_of_week\
    """\
    df = pd.read_sql(query, conn)\
    conn.close()\
    return df\
\
try:\
    taxi_df = load_taxi_data()\
    col1, col2 = st.columns(2)\
    \
    with col1:\
        st.subheader("Trips by Day")\
        st.bar_chart(taxi_df.set_index('pickup_day_of_week')['trip_count'])\
        \
    with col2:\
        st.subheader("Average Fare by Day")\
        st.line_chart(taxi_df.set_index('pickup_day_of_week')['avg_fare'])\
except Exception as e:\
    st.error(f"Postgres connection error: {e}")\
\
st.divider()\
\
# --- TAB 2: CRYPTO DATA (From AWS S3) ---\
st.header("ðƒ¿ƒ³ƒ¨ Live Crypto Market (from AWS S3)")\
\
@st.cache_data(ttl=60)\
def load_s3_crypto_data():\
    s3 = boto3.client('s3')\
    bucket = "nyc-taxi-pipeline-kuro-2026"\
    \
    # Get the latest file in the raw/crypto/ folder\
    objects = s3.list_objects_v2(Bucket=bucket, Prefix="raw/crypto/")\
    if 'Contents' not in objects:\
        return pd.DataFrame()\
        \
    # Sort by last modified\
    latest_file = sorted(objects['Contents'], key=lambda x: x['LastModified'])[-1]['Key']\
    \
    # Read the JSON directly out of S3 into memory\
    response = s3.get_object(Bucket=bucket, Key=latest_file)\
    data = json.loads(response['Body'].read().decode('utf-8'))\
    \
    df = pd.DataFrame(data)\
    return df[['name', 'symbol', 'current_price', 'market_cap', 'price_change_percentage_24h']]\
\
try:\
    crypto_df = load_s3_crypto_data()\
    if not crypto_df.empty:\
        # Format the numbers to look pretty\
        crypto_df['current_price'] = crypto_df['current_price'].apply(lambda x: f"${x:,.2f}")\
        crypto_df['market_cap'] = crypto_df['market_cap'].apply(lambda x: f"${x:,.0f}")\
        \
        st.dataframe(crypto_df.head(20), use_container_width=True)\
    else:\
        st.info("No crypto data found in S3 yet. Run the Airflow DAG!")\
except Exception as e:\
    st.error(f"S3 connection error: {e}")\
EOF
streamlit run dashboard.py
git checkout -b level-6-production\
git add .\
git commit -m "Level 6: Complete Modern Data Stack - Added AWS S3, CoinGecko API, and Streamlit Dashboard"\
git push -u origin level-6-production\
\
git checkout main\
git merge level-6-production\
git push origin main
yazi
pkill -9 awww
awww
awww-daemon
yazi
awww-daemon &
yazi
airflow scheduler
cd projects
source venv/bin/activate
airflow scheduler
udisksctl mount -b /dev/sdb1
udisksctl mount -b /dev/sda1
udisksctl mount -b /dev/sdb\\

udisksctl mount -b /dev/sdb
lsblk
sudo dmesg -w
lsusb
_lsusb
sudo pacman -S udisks2
lsblk
# Move to a totally clean scratch folder\
cd ~/Desktop\
mkdir de-installer-test && cd de-installer-test\
\
# Create your files here (Makefile, docker-compose.yml, src/ code)\
# Then fire it up:\
make dev-up
cd ~/Desktop\
mkdir de-installer-test && cd de-installer-test\
make dev-up
mkdir -p ~/Desktop
cd ~/Desktop\
mkdir de-installer-test && cd de-installer-test\
make dev-up
yazi
mkdir -p ~/infrastructure
ls
nvim docker-compose.yml
# Start everything\
docker-compose -f infrastructure/docker-compose.yml up -d
cd ..
ls
cd kuro
ls
cd ..
cd kuro/infrastructure
ls
cd ..
ls
mv docker-compose.yml infrastructure/
ls
cd infrastructure
ls
cd ..
# Start everything\
docker-compose -f infrastructure/docker-compose.yml up -d
sudo systemctl start docker
sudo systemctl reset-failed start docker
mkdir -p ~/src
cd src
mkdir -p ~/utils
cd ..
ls
rm -rf utils
ls
cd src
mkdir -p utils
ls
cd utils
touch s3_client.py
nvim s3_client.py
lsbllk
lsblk
udisksctl mount -b /dev/sdb
udisksctl mount -b /dev/sdb1
udisksctl mount -b /dev/sda1
lsblk
sudo modprobe usb_storage\
sudo modprobe uas
lsblk
lsmod | grep usb
sudo modprobe usb_storage\
sudo modprobe uas
sudo reboot
yazi
cd ~/run
cd ..
cd..
cd run/media/kuro/arch/dotfiles
ls
git status
git init
git remote add origin https://github.com/Mayank-cs-2004/dotffiles.git
git pull origin main --allow-unrelated-histories
git add .
git push origin main"
git push origin main
git remote set-url origin git@github.com:Mayank-cs-2004/dotfiles.git
git remote -v
git push -u origin main
git pull origin main --rebase
;9;27~git add .gitignore\
git commit -m "add .gitignore"
git push origin main
git add .gitignore\
git commit -m "add .gitignore"
git push origin main
git pull origin main --rebase
git add .\
git commit -m "Save local changes to readme and gitignore"
git pull origin main --rebase
git push origin main
ls
chmod +x home/
ls -a
cd home
ls -a
./sync-dotfiles.sh
~/sync-dotfiles.sh
/home/kuro/github/dotfiles/home
cd .config/scripts
ls
ls -a
cd ..
cd.. 
cd ..
clean
type clean
unset -f clean
clean
sudo pacman -S virtualbox virtualbox-host-modules-arch
sudo usermod -aG vboxusers $USER
sudo modprobe vboxdrv
sudo systemctl enable vboxservice
sudo journalctl -xeu docker.service --no-pager | tail -30
cd projects
ls -a
yazi
mkdir -p universal_installer
ls
cd universal_installer
mkdir -p infrastructure/terraform\
mkdir -p config\
mkdir -p src/{extract,transform,load}\
mkdir -p tests\
mkdir -p dags
cd infrastructure
nvim docker-compose.yml
yazi
vbox
sudo modprobe vboxdrv\

sudo systemctl enable vboxservice
virtualbox
virtualbox &
cd .config/scripts
cat /tmp/smart-run.log
yazi
cd github/dotfiles/
ls
git add .\
git commit -m "Remove the drun script for rofi"
git push origin main
git add .\
git commit -m "Remove the smart-script.sh from .config/scipts"
git push origin main
sudo systemctl enable vboxsup
sudo systemctl enable --now vboxweb.service\

sudo systemctl start --now vboxweb.service\

sudo pacman -Syu linux-headers
pacman -Qqen
virtualbox-host-dkms
sudo pacman -Ss dkms
sudo pacman -Ss virtualbox-host-dkms
sudo pacman -Syu virtualbox-host-dkms
sudo pacman -Rns virtualbox virtualbox-host-dkms linux-headers
uname -r
sudo pacman -S virtualbox virtualbox-host-modules-arch
sudo reboot
sudo modprobe vboxdrv
lsmod | grep vboxdrv 
sudo pacman -S --needed virtualbox linux-headers
sudo usermod -aG vboxusers $USER
sudo modprobe vboxdrv
sudo systemctl enable systemd-modules-load.service  # usually already enabled\
echo vboxdrv | sudo tee /etc/modules-load.d/virtualbox.conf
sudo systemctl enable systemd-modules-load.service \
echo vboxdrv | sudo tee /etc/modules-load.d/virtualbox.conf
vboxmanage --version
lsmod | grep vbox
virtualbox
virtualbox 2>&1 | tee vbox-crash.log
ssh testing@testing2@127.0.0.1
ssh testing2@127.0.0.1
ssh -p 2222 testing2@127.0.0.1
sudo pacman -Ss openssh
sudo pacman -S openssh
ssh -p 2222 testing2@127.0.0.1
yazi
cd projects/universal_installer
ls -a
git init
yazi
cd ..
cd nyc_taxi_pipeline
ls
ls -a
git status
\
git add .
cd projects
cd nyc_taxi_pipeline
ls -a
git add -A\
\
git commit -m "chore: relocate git repository root to project folder"\
\
git remote -v
git push origin main
cd ..
cd universal_installer
git init
cd remote git@github.com:Mayank-cs-2004/Universal-Installer.git
git remote add origin git@github.com:Mayank-cs-2004/Universal-Installer.git
git add .
git commit -m "Add univeral installer"
git push origin main
git checkout main
git branch -M main
git push -u origin main
yazi
git add .
git push -u origin main
yazi
git add .
\
git commit -m "Add remaining source files, dags, and tests"\
git push origin main
git check-ignore -v src
git push origin main
yazi
rm -rf .git
git init
git remote add origin git@github.com:Mayank-cs-2004/Universal-Installer.git
git add .
git commit -m "Fresh start: tracking all files"
git push -u origin main --force
git push -u origin main 
git branch -m main\
git push -u origin main
rm -rf .git
git status
git init
git branch -m main
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:Mayank-cs-2004/universal-installer.git
git push -u origin main
yazi
git status
yazi
cd ..
ls 
scp -r universal_installer testing2@127.0.0.1
git remote add origin git@github.com:Mayank-cs-2004/universal-installer.git
pacman -Qqen
yazi
overskride
btop
yazi
7zip
pacman -Qqen\\

sudo pacman -Ss unzip
sudo pacman -S unzip
yazi
yazi --config
yazi
cd github
ls
cd ..
cd projects/de-project-template
ls
git init
git add .
git commit -m "feat: initial project template"
git remote add origin git@github.com:Mayank-cs-2004/de-project-template.git
git branch -M main
git push -u origin main
btop
yazi
cd projects/de-project-template
git init
git add .
git commit -m "feat: initial project template"
git remote add origin git@github.com:Mayank-cs-2004/de-project-template.git
git push -f origin main
git branch -m main\
git push -f origin main
yazi
overskride
sudo pacman -Ss xremap
yay -Ss xremap
yay -Syu xremap-hypr-bin
# Run xremap manually to test (requires sudo)\
sudo xremap ~/.config/xremap/config.yml
btop
over
overskride
sudo pacman -Ss mako
sudo pacman -Syu mako
sudo pacman -Rns swaync
yazi
xremap
yay -Syu --needed xremap-hypr-bin
xremap-hypr
xremap-hypr-bin
pacman -Qqem
xremap-hypr-bin
yazi
chmod +x home/.config/scripts/control-centre-tui.sh
chmod +x ~/.config/scripts/control-centre-tui.sh
control-centre-tui.sh
.config/scripts/control-centre-tui.sh
./.config/scripts/control-centre-tui.sh
~/.config/scripts/control-centre-tui.sh
sudo pacman -S gum
~/.config/scripts/control-centre-tui.sh
chmod +x ~/.config/scripts/control-centre-tui.sh
~/.config/scripts/control-centre-tui.sh
logout
exit
sudo pacman -Syu swaync
yazi
swaync &
~/.config/scripts/control-centre-tui.sh
wpctl get-volume @DEFAULT_AUDIO_SINK@
wpctl get-volume @DEFAULT_AUDIO_SOURCE@
wpctl get-volume @DEFAULT_AUDIO_SINK@
rm ~/.cache/tui-caffeine-state
~/.config/scripts/control-centre-tui.sh
yazi
~/.config/scripts/image-search.sh
~/.config/scripts/image_search.sh
# 1. Find where Helium is installed\
which helium-browser\
which helium\
# or search manually:\
find /usr/bin /usr/local/bin ~/.local/bin -name "*helium*" 2>/dev/null\
\
# 2. Check if Helium can be launched from terminal\
helium-browser --version   # try the most likely names\
helium --version\
\
# 3. See what xdg-open thinks is your default browser\
xdg-settings get default-web-browser
helium-browser
helium-browser --version
~/.config/scripts/image_search.sh
yazi
~/.config/scripts/image_search.sh
~/.config/scripts/control-centre-tui.sh
cd github/dotfiles
ls
ls -a
git add .
git commit -m "Add TUI for using scripts directly from terminal"
git push origin main
~/.config/scripts/control-centre-tui.sh
sudo pacman -Rns swaync
sudo systemctl disable --now postgresql
btop
sudo btop
overskride
~/.config/scripts/control-centre-tui.sh
overskride
~/.config/scripts/control-centre-tui.sh
overskride
;5A
~/.config/scripts/control-centre-tui.sh
;5A
~/.config/scripts/control-centre-tui.sh
btop
~/.config/scripts/control-centre-tui.sh
overskride
nmtui
ping x.com
~/.config/scripts/control-centre-tui.sh
btop
~/.config/scripts/control-centre-tui.sh
overskride
~/.config/scripts/control-centre-tui.sh
overskride
overskride
~/.config/scripts/control-centre-tui.sh
overskride
bluetoothctl scan on
overskride
overskride
~/.config/scripts/control-centre-tui.sh
bluetoothctl scan on
~/.config/scripts/control-centre-tui.sh
bluetoothctl scan on
~/.config/scripts/control-centre-tui.sh
;5A
~/.config/scripts/control-centre-tui.sh
;5A
~/.config/scripts/control-centre-tui.sh
yazi
cd github/dotfiles
ls
killall gvfsd
git add .\
git commit -m "Update the tui script to v3"\
git push origin main
yazi
udisksctl mount -b /dev/sda1
udisksctl mount -b /dev/sdb
lsblk
udisksctl mount -b /dev/sda
yazi
~/.config/scripts/sync-dotfiles.sh
yazi
~/.config/scripts/sync-dotfiles.sh
~/.config/scripts/control-centre-tui.sh
hyprctl monitors
hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.width)x\(height)"'
yazi
~/.config/scripts/control-centre-tui.sh
yazi
yay -Syu upscayl-bin
sudo pacman -S vulkan-radeon lib32-vulkan-radeon
sudo pacman -S vulkan-radeon vulkan-icd-loader
vulkaninfo --summary
udisksctl mount -b /dev/sda
lsblk
udisksctl mount -b /dev/sdb
reboot
yazi
reboot
udisksctl mount -b /dev/sdb
yazi
~/.config/scripts/control-centre-tui.sh
udisksctl mount -b /dev/sda1
udisksctl mount -b /dev/sda2
udisksctl mount -b /dev/sdb
lsblk
udisksctl mount -b /dev/sda
~/.config/scripts/control-centre-tui.sh
reboot
yazi
~/.config/scripts/control-centre-tui.sh
awww img ~/.config/wallpaper/home_screen/1.png
~/.config/scripts/control-centre-tui.sh
awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 60 --transition-type wave\

awww img $HOME/.config/wallpaper/home_screen/2.png --transition-fps 60 --transition-type wave\

awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 60 --transition-type grow
awww img $HOME/.config/wallpaper/home_screen/2.png --transition-fps 60 --transition-type centre
awww img $HOME/.config/wallpaper/home_screen/2.png --transition-fps 60 --transition-type center
awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 60 --transition-type grow
awww img $HOME/.config/wallpaper/home_screen/2.png --transition-fps 60 --transition-type outer
awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 120 --transition-type outer
awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 60 --transition-type outer
~/.config/scripts/control-centre-tui.sh
yazi
~/.config/scripts/control-centre-tui.sh
pacman -S hyprpaper
sudo pacman -S hyprpaper
yazi
~/.config/scripts/control-centre-tui.sh
pkill hyprpaper; echo -e "preload = /path/to/your/wallpaper.jpg\nwallpaper = ,/path/to/your/wallpaper.jpg" > /tmp/hyprpaper.conf && hyprpaper -c /tmp/hyprpaper.conf
pkill hyprpaper; echo -e "preload = ~/.config/wallpaper/home_screen/1.png\nwallpaper = ~/.config/wallpaper/home_screen/1.png" > /tmp/hyprpaper.conf && hyprpaper -c /tmp/hyprpaper.conf\

pkill hyprpaper; echo -e "preload = /home/kuro/.config/wallpaper/home_screen/1.png\nwallpaper = ,/home/kuro/.config/wallpaper/home_screen/1.png" > /tmp/hyprpaper.conf && hyprpaper -c /tmp/hyprpaper.conf
pkill hyprpaper; echo -e "preload = ~/.config/wallpaper/home_screen/1.png\nwallpaper = ~/.config/wallpaper/home_screen/1.png" > /tmp/hyprpaper.conf && hyprpaper -c /tmp/hyprpaper.conf
pkill hyprpaper; echo -e "preload = ~/.config/wallpaper/home_screen/1.png\nwallpaper = eDP-1,~/.config/wallpaper/home_screen/1.png" > /tmp/hyprpaper.conf && hyprpaper -c /tmp/hyprpaper.conf
pkill hyprpaper\
cat > /tmp/hyprpaper.conf << EOF\
preload = /home/kuro/.config/wallpaper/home_screen/1.png\
wallpaper = eDP-1,/home/kuro/.config/wallpaper/home_screen/1.png\
EOF\
hyprpaper -c /tmp/hyprpaper.conf
ls -la /home/kuro/.config/wallpaper/home_screen/1.png
hyprctl monitors | grep -i name
echo $HYPRLAND_INSTANCE_SIGNATURE\
echo $WAYLAND_DISPLAY\
echo $XDG_RUNTIME_DIR
hyprctl monitors
sudo pacman -Rns hyprpaper
awww img ~/.config/wallpaper/home_screen/1.jpg --transition-fps 60 --transition-type outer --transition-duration 0.8\

awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 60 --transition-type outer --transition-duration 0.8
sudo pacman -Syu awww
awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 60 --transition-type outer --transition-duration 0.8
awww daemon
awww-daemon
awww img $HOME/.config/wallpaper/home_screen/1.png --transition-fps 60 --transition-type outer --transition-duration 0.8\

~/.config/scripts/control-centre-tui.sh
yazi
~/.config/scripts/control-centre-tui.sh
yazi
~/.config/scripts/control-centre-tui.sh
awww img $HOME/.config/wallpaper/homescreen.png --transition-fps 60 --transition-type outer --transition-duration 0.8
reboot
EOF

# ------------------------------------------------------------
# zed editor
# ------------------------------------------------------------
mkdir -p ~/.config/zed/themes

cat > ~/.config/zed/keymap.json << 'EOF'
# paste keymap.json contents here
EOF

cat > ~/.config/zed/settings.json << 'EOF'
# paste settings.json (zed's) contents here
EOF

cat > ~/.config/zed/themes/onyx-theme.json << 'EOF'
# paste onyx-theme.json contents here
EOF

# ------------------------------------------------------------
# BINARY FILES — can't be written as text, still copied from
# pendrive. Mount it just for this step.
# ------------------------------------------------------------
SRC="/run/media/kuro/Kuro/Work/OS Files/Noctalia_Umbriel_Greeter"
ls "$SRC" || echo "Pendrive not mounted at expected path!"

mkdir -p ~/.config/wallpaper/"Dark Mode Wallpaper"
cp "$SRC"/D-*.png "$SRC"/D-*.jpg ~/.config/wallpaper/"Dark Mode Wallpaper"/ 2>/dev/null

mkdir -p ~/.config/wallpaper/"Light Mode Wallpaper"
cp "$SRC"/L-*.jpg ~/.config/wallpaper/"Light Mode Wallpaper"/

cp "$SRC/homescreen.jpg" "$SRC/lockscreen.png" ~/.config/wallpaper/

mkdir -p ~/.local/share/fonts
cp "$SRC/DankMonoNerdFontMono-Bold.otf" "$SRC/DankMonoNerdFontMono-Italic.otf" "$SRC/DankMonoNerdFontMono-Regular.otf" ~/.local/share/fonts/
fc-cache -fv
```

---

## 8. Configure Snapper

```bash
sudo sed -i \
  -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="4"/' \
  -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="0"/' \
  -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="3"/' \
  -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
  -e 's/^TIMELINE_LIMIT_QUARTERLY=.*/TIMELINE_LIMIT_QUARTERLY="0"/' \
  -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
  /etc/snapper/configs/root

sudo sed -i \
  -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="4"/' \
  -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="0"/' \
  -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="3"/' \
  -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
  -e 's/^TIMELINE_LIMIT_QUARTERLY=.*/TIMELINE_LIMIT_QUARTERLY="0"/' \
  -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
  /etc/snapper/configs/home

sudo mkdir -p /etc/systemd/system/snapper-timeline.timer.d
sudo tee /etc/systemd/system/snapper-timeline.timer.d/override.conf > /dev/null << 'EOF'
[Timer]
OnCalendar=
OnCalendar=00/6:00
EOF

sudo systemctl daemon-reload
sudo systemctl restart snapper-timeline.timer
```

---

## 9. Verify Everything

```bash
echo "=== Services ==="
systemctl is-active NetworkManager bluetooth greeter fstrim.timer udisks2

echo "=== Shell ==="
echo "Current shell: $SHELL"
getent passwd kuro | cut -d: -f7

echo "=== AUR packages ==="
yay -Q umbriel-git noctalia-greeter helium-browser-bin obsidian

echo "=== Polkit rule ==="
ls -l /etc/polkit-1/rules.d/49-noctalia-greeter.rules

echo "=== Umbriel config ==="
ls ~/.config/umbriel/

echo "=== Noctalia palettes ==="
ls ~/.config/noctalia/palettes/

echo "=== Noctalia state (config + runtime files) ==="
ls ~/.local/state/noctalia/

echo "=== foot ==="
ls ~/.config/foot/foot.ini

echo "=== starship ==="
ls ~/.config/starship.toml

echo "=== zsh dotfiles ==="
ls ~/.config/zsh/
ls -l ~/.zsh_history

echo "=== zed ==="
ls ~/.config/zed/
ls ~/.config/zed/themes/

echo "=== Wallpapers ==="
ls ~/.config/wallpaper/"Dark Mode Wallpaper"/
ls ~/.config/wallpaper/"Light Mode Wallpaper"/
ls ~/.config/wallpaper/

echo "=== Fonts ==="
fc-list | grep -i "DankMono"

echo "=== Snapper config values ==="
grep "TIMELINE_LIMIT" /etc/snapper/configs/root
grep "TIMELINE_LIMIT" /etc/snapper/configs/home

echo "=== Snapper timer override ==="
systemctl list-timers snapper-timeline.timer
systemctl cat snapper-timeline.timer | grep -A2 "\[Timer\]"
```
