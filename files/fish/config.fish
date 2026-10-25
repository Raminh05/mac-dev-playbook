# Managed by mac-dev-playbook (files/fish/config.fish).

set -g fish_greeting
set -gx CARGO_INCREMENTAL 0

# Cyclone data on the portable dev drive.
set -gx CYCLONE_CATALOG /Volumes/secrets/NTP/cyclone-data/cyclone.sqlite
set -gx CYCLONE_ZARR_ROOT /Volumes/secrets/NTP/cyclone-data/zarr

# cargo-installed binaries; appended so Homebrew's rustup proxies win.
fish_add_path --path --append --move $HOME/.cargo/bin
fish_add_path --path --append /opt/homebrew/opt/libpq/bin
# uv-installed Pythons and tools.
fish_add_path --path --append $HOME/.local/bin

# SSH keys come from Bitwarden's SSH agent (also set in ~/.ssh/config).
set -gx SSH_AUTH_SOCK $HOME/.bitwarden-ssh-agent.sock

if status is-interactive
    command -q starship; and starship init fish | source
end

# OrbStack: command-line tools and integration
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
