# 🏠 Karan's Dotfiles

Arch Linux + Hyprland rice — one command to set up a fresh system.

Everything is **symlinked**, so editing your live configs (`~/.config/...`) directly edits the repo. No manual copying needed.

---

## 📸 Stack

| Component | Tool |
|-----------|------|
| **OS** | Arch Linux |
| **WM** | [Hyprland](https://hyprland.org/) (Wayland) |
| **Bar, launcher, notifications, quick settings, lock** | [glyph shell](glyph/README.md) (quickshell) |
| **Terminal** | WezTerm |
| **Shell** | Zsh (Oh My Zsh) |
| **Prompt** | [Starship](https://starship.rs/) |
| **File Manager** | Nautilus |
| **Login screen** | SDDM with the glyph theme (`glyph/sddm/`, installed by `scripts/06c-system.sh`; pick the **Hyprland** session, not the uwsm one). GDM stays installed as a fallback |
| **Theme** | glyph (black, white, one red accent); colors in `.config/hypr/palette.lua` |
| **Icons** | Numix Circle / Humanity / Yaru |
| **Cursor** | Bibata Modern Classic |
| **Fonts** | JetBrains Mono Nerd Font |
| **GTK** | adw-gtk3-dark |

---

## 🚀 Fresh Install

> **Requirements:** A fresh Arch Linux install with a non-root user that has `sudo` access.

```bash
# 1. Clone the repo
git clone https://github.com/krotrn/dotfiles.git ~/dotfiles

# 2. Run the installer
cd ~/dotfiles
bash install.sh
```

That's it. The installer runs 10 scripts in order and handles everything:

| Step | Script | What it does |
|------|--------|-------------|
| 01 | `01-system.sh` | System update, installs `git` and `base-devel` |
| 02 | `02-yay.sh` | Installs [yay](https://github.com/Jguer/yay) (AUR helper) |
| 03 | `03-chaotic-aur.sh` | Sets up [Chaotic-AUR](https://aur.chaotic.cx/) repository |
| 04 | `04-packages.sh` | Installs all packages (official + AUR + auto-detected hardware) |
| 05 | `05-omz.sh` | Installs [Oh My Zsh](https://ohmyz.sh/) and plugins |
| 06 | `06-configs.sh` | **Symlinks** all configs from the repo into `~/.config/` and `~/` |
| 07 | `07-services.sh` | Enables systemd services (NetworkManager, Bluetooth, Pipewire, Docker, UFW, etc.) |
| 08 | `08-hyprpm.sh` | Installs Hyprland plugins ([hyprgrass](https://github.com/horriblename/hyprgrass), [hymission](https://github.com/gfhdhytghd/hymission)) |
| 09 | `09-shell.sh` | Sets Zsh as the default shell |
| 10 | `10-finish.sh` | Reloads Hyprland and prints completion message |

After install, **reboot** for everything to take effect.

---

## 🔧 The `dotfiles` Command

After install, a `dotfiles` helper is available in your `PATH` (`~/.local/bin/dotfiles`). This is the main way to manage your dotfiles.

### Commands

```bash
dotfiles status          # Show what files changed since last commit
dotfiles save            # Stage + commit + push (auto-generated message)
dotfiles save "message"  # Same, with a custom commit message
dotfiles diff            # Show the actual content changes (git diff)
dotfiles packages        # Re-export installed packages to packages.txt / aur-packages.txt
dotfiles link            # Re-create all symlinks (run after adding new configs)
dotfiles edit            # Open the dotfiles directory in $EDITOR
dotfiles cd              # Print the dotfiles repo path (use: cd $(dotfiles cd))
```

### Typical Workflow

```bash
# You just tweaked your Hyprland keybinds
nvim ~/.config/hypr/keybinds.conf    # this edits the repo file directly (symlink)

# Check what changed
dotfiles status

# Save it
dotfiles save "updated hyprland keybinds"
```

### After Installing New Packages

```bash
# You installed some new packages with pacman/yay
yay -S some-new-package

# Update the package lists in the repo
dotfiles packages

# Commit the updated lists
dotfiles save "added some-new-package"
```

---

## 📁 Repo Structure

```
dotfiles/
├── install.sh                 # Entry point — runs all scripts in order
├── packages.txt               # Official Arch repo packages
├── aur-packages.txt           # AUR packages
├── .gitignore                 # Ignores editor junk, VS Code cache, etc.
│
├── hardware/                  # Auto-detected hardware packages
│   ├── asus.txt               #   ASUS laptop tools (asusctl, rog-control-center)
│   └── nvidia.txt             #   NVIDIA GPU drivers
│
├── bin/                       # Helper scripts, each symlinked into ~/.local/bin/
│   └── dotfiles, touchpad-reset, claude-split, git-changes-pane, hyprcapture-*
│
├── system/                    # Root-owned files, COPIED by 06c-system.sh (not symlinked)
│   └── etc/                   #   sysctl, iwlwifi options, ASUS battery-limit udev rule
│
├── scripts/                   # Install pipeline (01–10 and 06b, run in order)
│   ├── 01-system.sh
│   ├── 02-yay.sh
│   ├── 03-chaotic-aur.sh
│   ├── 04-packages.sh
│   ├── 05-omz.sh
│   ├── 06-configs.sh          # Creates all symlinks
│   ├── 06b-glyph.sh           # Links the glyph shell and its settings
│   ├── 06c-system.sh          # Copies the /etc tuning (sudo); ASUS-only parts run only on ASUS
│   ├── 07-services.sh
│   ├── 08-hyprpm.sh
│   ├── 09-shell.sh
│   └── 10-finish.sh
│
├── glyph/                     # The glyph desktop shell (quickshell) + its settings — see glyph/README.md
│
├── .bashrc                    # Bash config (symlinked to ~/.bashrc)
├── .zshrc                     # Zsh config (symlinked to ~/.zshrc)
├── .gitconfig                 # Git config (symlinked to ~/.gitconfig)
│
└── .config/                   # All app configs (each dir/file symlinked into ~/.config/)
    ├── hypr/                  #   Hyprland (modular: keybinds, monitors, themes, etc.)
    ├── kitty/                 #   Kitty terminal
    ├── wezterm/               #   WezTerm terminal
    ├── fish/                  #   Fish shell
    ├── waybar/                #   (if present) Waybar
    ├── btop/                  #   System monitor
    ├── cava/                  #   Audio visualizer
    ├── fastfetch/             #   System info (with custom logos)
    ├── lazygit/               #   Git TUI
    ├── yazi/                  #   File manager TUI
    ├── starship.toml          #   Starship prompt config
    ├── gtk-3.0/               #   GTK3 theme
    ├── gtk-4.0/               #   GTK4 theme
    ├── qt5ct/                 #   Qt5 theme
    ├── qt6ct/                 #   Qt6 theme
    ├── Code/User/             #   VS Code settings
    ├── vlc/                   #   VLC preferences
    ├── Thunar/                #   Thunar file manager
    ├── nwg-displays/          #   Display configuration
    ├── nwg-look/              #   GTK look config
    └── ...
```

---

## 🔗 How Symlinks Work

The installer creates symlinks so your live system points to the repo:

```
~/.config/hypr       →  ~/dotfiles/.config/hypr/
~/.config/kitty      →  ~/dotfiles/.config/kitty/
~/.config/starship.toml → ~/dotfiles/.config/starship.toml
~/.zshrc             →  ~/dotfiles/.zshrc
~/.bashrc            →  ~/dotfiles/.bashrc
~/.gitconfig         →  ~/dotfiles/.gitconfig
~/.local/bin/dotfiles → ~/dotfiles/bin/dotfiles
```

**This means:** editing `~/.config/hypr/keybinds.conf` directly edits `~/dotfiles/.config/hypr/keybinds.conf`. The file is the same — no copying, no syncing. Just `dotfiles save` when you're ready to commit.

If you add a **new config directory** to the repo (e.g., `.config/neofetch/`), run `dotfiles link` to create its symlink.

---

## 📦 Package Lists

| File | Installed with | Contents |
|------|---------------|----------|
| `packages.txt` | `pacman` | Official Arch repo packages (categorized with comments) |
| `aur-packages.txt` | `yay` | AUR packages |
| `hardware/nvidia.txt` | `yay` | NVIDIA drivers — **auto-detected** (only installed if NVIDIA GPU found) |
| `hardware/asus.txt` | `yay` | ASUS tools — **auto-detected** (only installed if ASUS hardware found) |

### Updating Package Lists

To sync the repo with what's currently installed on your system:

```bash
dotfiles packages       # exports pacman -Qqen → packages.txt, pacman -Qqem → aur-packages.txt
dotfiles save "updated packages"
```

> **Note:** `dotfiles packages` overwrites the categorized comments in the package files with a plain sorted list. This is expected — it's a snapshot of your current system.

---

## 🎨 Hyprland Config (Modular)

The Hyprland config is split into multiple files for clarity:

```
.config/hypr/
├── hyprland.conf          # Main config — sources all other files
├── monitors.conf          # Display setup
├── startup.conf           # Autostart apps & environment variables
├── keybinds.conf          # All keybindings
├── inputs.conf            # Keyboard, mouse, touchpad settings
├── windowrules.conf       # Per-app window rules
├── animations.conf        # Animation settings
├── hypridle.conf          # Idle/lock behavior
├── hyprtoolkit.conf       # Hypr toolkit config
├── themes/theme.conf      # Theme (gaps, borders, blur, cursor)
├── palette.lua            # Static colors: borders, groups, overview, hyprbars, hyprlock
├── Scripts/               # Helper scripts
├── lua/                   # Lua config alternatives
└── animations/            # Animation presets
```

Edit any of these directly — they're symlinked to the repo.

---

## 🖥️ NVIDIA Users

NVIDIA packages are auto-detected during install. If you have an NVIDIA GPU, the installer will install `nvidia-open`, `lib32-nvidia-utils`, and `libva-nvidia-driver`.

To enable NVIDIA environment variables in Hyprland, uncomment the NVIDIA section in `.config/hypr/startup.conf`:

```conf
# Uncomment these lines:
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
```

---

## 🐚 Shell Setup

### Zsh (Default)

- **Framework:** Oh My Zsh
- **Theme:** robbyrussell (with Starship prompt override)
- **Plugins:** git, sudo, npm, zsh-autosuggestions, zsh-syntax-highlighting, docker, docker-compose, extract, colored-man-pages
- **Tools:** fzf (fuzzy finder), zoxide (smart cd), eza (modern ls), bat (cat with syntax highlighting), ripgrep (fast grep)

### Fish (Alternative)

Fish config is also included at `.config/fish/config.fish` with Starship, zoxide, fnm, and eza aliases.

### Useful Aliases & Functions (Zsh)

| Command | Description |
|---------|-------------|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza -la --icons --group-directories-first --git` |
| `lt` | `eza --tree --icons --level=2` |
| `fcd` | Fuzzy `cd` — search directories with fzf |
| `fo` | Fuzzy open — find and open files in `$EDITOR` |
| `fsearch <term>` | Search file contents with rg + fzf |
| `flive [dir]` | Live interactive grep with preview |
| `serve [port]` | Quick HTTP server in current directory |
| `mkcd <dir>` | Create directory and cd into it |

---

## 🛠️ Adding New Configs

1. Put the config in the repo:
   ```bash
   # Example: adding neofetch config
   mkdir -p ~/dotfiles/.config/neofetch
   cp ~/.config/neofetch/config.conf ~/dotfiles/.config/neofetch/
   ```

2. Re-link:
   ```bash
   dotfiles link
   ```

3. Save:
   ```bash
   dotfiles save "added neofetch config"
   ```

---

## ⚠️ Notes

- **Backups:** The first time `dotfiles link` runs, existing non-symlink configs are renamed with a `.bak` extension. Check `~/.config/*.bak` if something goes wrong.
- **VS Code:** Only `User/settings.json` is tracked. Cache, sessions, extensions storage, and other runtime data are gitignored.
- **Chaotic-AUR:** The installer sets up Chaotic-AUR automatically. Some packages (like `brave-bin`) may be available from Chaotic-AUR instead of building from source.
- **Hardware detection:** NVIDIA and ASUS packages are only installed when the hardware is detected. No manual toggling needed.

---

## 📄 License

Personal dotfiles — use as inspiration, fork freely.


---

## ⚠️ Not covered by the install (do these by hand on a new machine)

- **Packages from private repos** (`twinfi`, `unpakt`, `chatgpt-bin`): their repos are not configured by the scripts, so they are left out of `packages.txt`.
- **Tools installed outside pacman:** the `agy` CLI, `oh-my-posh`, `hymission-search-input`.
- **Hyprland plugins:** step 08 runs `hyprpm update`; after a big Hyprland upgrade run `hyprpm update && hyprpm reload -n` again, or the plugin binds (Super+Tab overview, split tiles) do nothing.
- **Logins and app data:** browser profiles, `gh auth login`, Docker/registry logins, SSH keys.
- **Wallpapers:** put pictures in `~/Pictures/Wallpapers` (the shell's picker looks there).
- **Brave theme lock:** a leftover `/etc/brave/policies/managed/*.json` from an old shell locks Brave's theme; delete it if you see "Theme is set by your organisation".

Refresh the package lists any time with `dotfiles packages`.
