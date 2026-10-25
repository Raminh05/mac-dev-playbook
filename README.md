# Mac Development Ansible Playbook

This playbook installs and configures the software and macOS settings I use for development on my Mac.

## Installation

On a fresh Mac, open Terminal and run these in order:

  1. Install Apple's Command Line Tools (provides `git`), and wait for the installer to finish:

         xcode-select --install

  2. Install [Homebrew](https://brew.sh), then add it to this Terminal session's `PATH`:

         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
         eval "$(/opt/homebrew/bin/brew shellenv)"

  3. Install Ansible with Homebrew. (Don't use `pip3`: on a fresh Mac it's Apple's Python 3.9, which can only install an Ansible too old for this playbook's collections.)

         brew install ansible

  4. Clone this repository over HTTPS (SSH keys aren't available until Bitwarden is set up):

         git clone https://github.com/Raminh05/mac-dev-playbook.git ~/Developer/mac-dev-playbook
         cd ~/Developer/mac-dev-playbook

  5. Install the required Ansible roles and collections:

         ansible-galaxy install -r requirements.yml

  6. Plug in the `secrets` dev drive (so Spotlight indexing gets turned off on it), then run the playbook. It asks for your macOS account password once at the start (used for `sudo`, including app installers that need it):

         ansible-playbook main.yml

  7. Do the [manual steps after setup](#manual-steps-after-setup), then log out and back in.

> Note: If some Homebrew commands fail, you might need to agree to Xcode's license or fix some other Brew issue. Run `brew doctor` to see if this is the case.

### Use with a remote Mac

To manage another Mac over SSH, enable Remote Login on it (System Settings > Sharing, or `sudo systemsetup -setremotelogin on`), then edit the `inventory` file and change the line that starts with `127.0.0.1` to:

```
[ip address or hostname of mac]  ansible_user=[mac ssh username]
```

If you need to supply an SSH password (if you don't use SSH keys), pass `--ask-pass` to `ansible-playbook`.

### Running a specific set of tagged tasks

You can run only part of the playbook with `--tags`. The tags available are:

  - `homebrew`: Homebrew itself plus every app and package category below
  - `macos`: Dock, appearance, developer-friendly settings and removing Apple's preinstalled apps
  - `fish`, `zed`, `rust`, `python`, `git`, `ssh`, `touchid`, `timemachine`, `spotlight`
  - `mas`, `dock` (Dock items via dockutil, off by default), `sudoers`, `extra-packages` and `post`

Each tag can run on its own, even as the first run on a fresh Mac: any tag that needs Homebrew installs it first, and `fish`, `rust`, `python` and `timemachine` install the tool they need themselves. For example:

    ansible-playbook main.yml --tags "macos,fish"

## Overriding Defaults

You can override any of the defaults in `default.config.yml` by creating a `config.yml` file and setting the overrides there. For example:

```yaml
# Replace a whole category (both its packages and casks).
brew_media:
  packages:
    - ffmpeg
  casks:
    - vlc

# Skip a category entirely.
brew_personal: {}

# Add a new category: any variable named brew_<name> is installed automatically.
brew_fonts:
  casks:
    - font-jetbrains-mono

dock_magnification_size: 80
dark_mode: false
```

Skipping `brew_media` or `brew_gaming` doesn't skip the apps that come from their developers rather than Homebrew, or Rosetta 2; set `direct_app_makemkv: {}`, `direct_app_melonds: {}` or `install_rosetta: false` for those.

See the [geerlingguy.mac](https://github.com/geerlingguy/ansible-collection-mac) collection's documentation for the Homebrew, Mac App Store and Dock role variables.

## What gets set up (default)

Everything is installed with Homebrew (`--tags homebrew`), grouped into `brew_<category>` variables in `default.config.yml` (see [Overriding Defaults](#overriding-defaults) to change, skip or add categories).

| Category | Packages | Apps |
|---|---|---|
| `dev` | bun, cmake, gh, git, hidapi, libpq, opencode, python@3.15, rustup, uv | Bruno, Claude Code, .NET SDK 10 (includes ASP.NET Core), OrbStack, Rider, WebStorm, XQuartz, Zed |
| `shell` | bat, btop, fastfetch, fish, starship | JetBrains Mono Nerd Font, Stats |
| `networking` | iperf3, nmap | Tailscale |
| `media` | ffmpeg, yt-dlp | HandBrake, MakeMKV (from makemkv.com, not Homebrew), Music Presence, VLC |
| `photography` | | Adobe Creative Cloud (install Lightroom Classic from it after signing in) |
| `office` | | Excel, Outlook, PowerPoint, Teams, Word |
| `gaming` | | CrossOver, Dolphin, melonDS (from GitHub, not Homebrew), Steam, Virtual Desktop Streamer (Rosetta 2 is installed first on Apple silicon) |
| `maker` | | ElegooSlicer, Raspberry Pi Imager |
| `personal` | | Bitwarden, Claude, Discord, Ungoogled Chromium |

Shell: fish is set as the login shell, and its config and functions are installed from `files/fish`. The prompt is [starship](https://starship.rs).

Git: identity and settings (`main` default branch, `push.autoSetupRemote`, `pull.rebase`, `fetch.prune`, `rerere`, histogram diffs) are set in `~/.gitconfig`, and a global ignore file is installed from `files/git/ignore`.

SSH: `~/.ssh/config` is installed from `files/ssh/config` and points every host at Bitwarden's SSH agent, so keys live in your Bitwarden vault instead of on disk.

Rust and Python: Homebrew's rustup installs the stable Rust toolchain with `rust-analyzer` and `rust-src`, and sets stable as the default on every run (change `rust_default_toolchain` to keep another default). uv installs Python 3.15 into `~/.local/bin`, which comes first in the fish `PATH`, so `python3.15` is uv's copy rather than Homebrew's. Homebrew's own tools come before Apple's (`/usr/bin`), so `git` is Homebrew's.

Zed: settings are installed from `files/zed/settings.json`: format on save (ESLint fixes then Prettier for TypeScript/JavaScript; ruff for Python), basedpyright and ruff for Python, clippy for Rust, JetBrains Mono Nerd Font in the editor and a fish terminal, and the C#, Docker, Docker Compose, fish, HTML, SQL, TOML and XML extensions.

> These files are managed by the playbook: `~/.config/fish/config.fish` and `functions/`, Zed's `settings.json`, `~/.ssh/config` and `~/.config/git/ignore` (from `files/`), plus the generated `~/.config/fish/conf.d/homebrew-rustup.fish`. When their tag runs (`fish`, `zed`, `ssh`, `git`, `rust`) and the content differs, they're replaced, with a timestamped backup kept next to each copied file. Make changes in `files/` in this repo, not in the apps, or turn the matching `configure_*` setting off.

macOS and system settings (`macos` tag, plus `touchid`, `timemachine` and `spotlight`):

  - Dock auto-hides with no delay and a fast animation
  - Dock icons magnify slightly on hover
  - Dark mode, with automatic Light/Dark switching disabled
  - Telemetry off for Homebrew (`brew analytics off`) and the .NET CLI (via `config.fish`), as well as Zed
  - Fast key repeat (and no accent popup on hold); smart quotes, smart dashes and autocorrect off
  - Finder shows file extensions, hidden files, the path bar and the status bar; uses list view by default; searches the current folder by default; empties Trash items after 30 days; no `.DS_Store` files on network or USB volumes
  - Touch ID for `sudo` (via `/etc/pam.d/sudo_local`, which survives macOS updates)
  - Time Machine skips rebuildable files: [asimov](https://github.com/AsimovMac/asimov) excludes project folders (`node_modules`, Rust `target`, `.venv`, .NET `bin`/`obj`) and common caches daily, and Rust/bun/uv toolchain folders are excluded directly
  - Spotlight doesn't index `/Volumes/secrets` (the setting is stored on the drive; only applied while it's mounted)
  - Removes Apple's GarageBand (and its sound library), iMovie, Keynote, Numbers and Pages if present. Built-in apps in `/System/Applications` (Safari, Music, News, etc.) are protected by macOS and can't be removed.

## Manual steps after setup

Some things can't be automated reliably, so do these by hand after the playbook runs:

  - **Finder sidebar:** open Finder > Settings > Sidebar and make sure **AirDrop** (under Favorites) and your **Mac's name** (under Locations; this is the "Computer" item) are checked. The sidebar item list lives in binary files whose format changes between macOS versions, so the playbook doesn't touch it.
  - **Bitwarden SSH agent:** sign in to Bitwarden, then turn on Settings > **Enable SSH agent**. Your SSH keys need to be in the vault (as SSH key items).
  - **Push access to this repo:** once the Bitwarden SSH agent is on, switch the clone from HTTPS to SSH: `git -C ~/Developer/mac-dev-playbook remote set-url origin git@github.com:Raminh05/mac-dev-playbook.git`
  - **Keyboard settings:** log out and back in for the key repeat settings to take effect.
  - **Terminal font:** in Terminal > Settings > Profiles > Text, set the font to **JetBrainsMono Nerd Font Mono** so starship's prompt icons don't show as boxes (Zed is already set up).
  - **Open at login:** turn on launch at login for Stats, Bitwarden, Tailscale and OrbStack (in each app's settings, or System Settings > General > Login Items).
  - **Sign in:** Steam, Discord, Tailscale, and JetBrains (Rider and WebStorm; turn on Settings Sync to restore IDE settings).
  - **Time Machine:** System Settings > General > Time Machine > Add Backup Disk.
  - **Spotlight on the dev drive:** if `/Volumes/secrets` wasn't plugged in during setup, plug it in and run `ansible-playbook main.yml --tags spotlight` once.
  - **Lightroom Classic:** sign in to Adobe Creative Cloud and install it from there.
  - **Microsoft Office:** open Word (or any Office app) and sign in with your Microsoft 365 account to activate the suite.

## Credits

Forked from [geerlingguy/mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook) by [Jeff Geerling](https://www.jeffgeerling.com/), originally inspired by [MWGriffin/ansible-playbooks](https://github.com/MWGriffin/ansible-playbooks).
