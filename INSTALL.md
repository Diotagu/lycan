# Installing this Lycan fork on Arch Linux

This fork of [tutkuofnight/lycan](https://github.com/tutkuofnight/lycan) adds
**multi-window support**: `window.open()`, `target="_blank"` links and OAuth popups now open
real windows (related to the opener, so `window.opener` and `postMessage` work).

## Quick install

```bash
# 1. Get the code (the repo is private, so authenticate: `gh auth login` or an SSH key / token)
sudo pacman -S --needed github-cli git
gh auth login
gh repo clone Diotagu/lycan
cd lycan

# 2. Dependencies + build + install (to ~/.local)
bash install.sh
```

Then run `lycan` (TUI) or `lycan open <app-name>`.
If `~/.local/bin` is not in your `PATH`, the script tells you what to add.

Other options:

```bash
bash install.sh --no-deps      # skip the pacman step
PREFIX=/usr/local bash install.sh   # system-wide install (uses sudo for the copy)
bash install.sh --uninstall    # remove binary, desktop entry, icon (your PWAs are kept)
```

## Manual install (what the script does)

```bash
sudo pacman -S --needed base-devel git rust pkgconf gtk3 glib2 webkit2gtk-4.1
cargo build --release
install -Dm755 target/release/lycan ~/.local/bin/lycan
```

`Cargo.lock` is included, so builds use exactly the dependency versions this fork was tested with.
(`install.sh` can also re-download it, plus the logo, from the upstream project at a pinned commit
and verify their SHA-256, in case you copy the sources without them.)

## Updating after a change

```bash
git pull
bash install.sh --no-deps
```

## Test multi-window

Add a PWA with `a` in the TUI, open a page that calls `window.open(...)` or has a
`target="_blank"` link, and click it: a new window should appear. Closing a popup never quits the
app; closing the main window does.
