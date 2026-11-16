#!/usr/bin/env bash
# Build and install this Lycan fork (multi-window support) on Arch Linux.
#
#   bash install.sh              install dependencies, build, install to ~/.local
#   bash install.sh --no-deps    skip the pacman step
#   bash install.sh --uninstall  remove the installed files (your PWAs/data are kept)
#   PREFIX=/usr/local bash install.sh   install system-wide (needs sudo for the copy)
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
DEPS=(base-devel git rust pkgconf gtk3 glib2 webkit2gtk-4.1)

# Cargo.lock and the logo are binary/large files that live in the upstream project.
# They are downloaded from a pinned upstream commit and verified by SHA-256.
UPSTREAM_RAW="https://raw.githubusercontent.com/tutkuofnight/lycan/52d1ff318d8802c875aa48de6ff063c9fe293a9e"
LOCK_SHA256="1c3d111a5b0852086f4826334eec85380f8331406909c1f482c690efd942353d"
LOGO_SHA256="cd4191f2807c0fbb7a38f3e804507e273b49711d96501c9d3faa500ed1bbede1"

BIN="$PREFIX/bin/lycan"
DESKTOP="$PREFIX/share/applications/io.github.tutkuofnight.Lycan.desktop"
ICON="$PREFIX/share/pixmaps/io.github.tutkuofnight.Lycan.png"

cd "$(dirname "${BASH_SOURCE[0]}")"

as_owner() { # run a command with sudo only if the target dir is not writable
  local dir=$1; shift
  mkdir -p "$dir" 2>/dev/null || sudo mkdir -p "$dir"
  if [ -w "$dir" ]; then "$@"; else sudo "$@"; fi
}

fetch_verified() { # <relative path> <sha256>
  local path=$1 sha=$2
  mkdir -p "$(dirname "$path")"
  curl -fsSL "$UPSTREAM_RAW/$path" -o "$path.tmp"
  if ! echo "$sha  $path.tmp" | sha256sum -c --quiet -; then
    rm -f "$path.tmp"; echo "Checksum mismatch for $path, aborting." >&2; exit 1
  fi
  mv "$path.tmp" "$path"
}

if [ "${1:-}" = "--uninstall" ]; then
  for f in "$BIN" "$DESKTOP" "$ICON"; do
    [ -e "$f" ] && { as_owner "$(dirname "$f")" rm -f "$f"; echo "removed $f"; }
  done
  echo "Your PWAs and data in ~/.local/share/lycan were left untouched."
  exit 0
fi

if [ "${1:-}" != "--no-deps" ]; then
  if command -v pacman >/dev/null; then
    echo "==> Installing dependencies (pacman)"
    sudo pacman -S --needed "${DEPS[@]}"
  else
    echo "pacman not found: install the equivalents of ${DEPS[*]} yourself (or use --no-deps)." >&2
  fi
fi

echo "==> Fetching Cargo.lock and logo from upstream (verified)"
[ -f Cargo.lock ] || fetch_verified Cargo.lock "$LOCK_SHA256"
[ -f assets/lycan.png ] || fetch_verified assets/lycan.png "$LOGO_SHA256"

echo "==> Building (release)"
cargo build --release --locked

echo "==> Installing to $PREFIX"
as_owner "$(dirname "$BIN")" install -Dm755 "${CARGO_TARGET_DIR:-target}/release/lycan" "$BIN"
as_owner "$(dirname "$ICON")" install -Dm644 assets/lycan.png "$ICON"
tmp=$(mktemp)
sed -e "s|^Exec=.*|Exec=$BIN|" -e "s|^Icon=.*|Icon=$ICON|" \
    data/io.github.tutkuofnight.Lycan.desktop > "$tmp"
as_owner "$(dirname "$DESKTOP")" install -Dm644 "$tmp" "$DESKTOP"
rm -f "$tmp"
command -v update-desktop-database >/dev/null && \
  update-desktop-database "$(dirname "$DESKTOP")" 2>/dev/null || true

echo "==> Done: $BIN"
case ":$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *) echo "NOTE: $PREFIX/bin is not in your PATH. Add this to your shell config:"
     echo "      export PATH=\"$PREFIX/bin:\$PATH\"" ;;
esac
echo "Run it with: lycan"
