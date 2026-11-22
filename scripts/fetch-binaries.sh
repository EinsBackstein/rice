#!/usr/bin/env bash
# Downloads pinned prebuilt tools that are not in Ubuntu's repos into ~/.local (no root, no Rust toolchain).
# Every download is verified against a pinned SHA-256; bump version+hash together to upgrade.
set -euo pipefail

BIN="$HOME/.local/bin"
FONTS="$HOME/.local/share/fonts"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN" "$FONTS"

[[ "$(uname -m)" == "x86_64" ]] || { echo "fetch-binaries: only x86_64 hashes are pinned, skipping"; exit 0; }

fetch() { # name url sha256
  local out="$TMP/$1"
  curl -fsSL --retry 3 -o "$out" "$2"
  echo "$3  $out" | sha256sum -c --quiet - || { echo "checksum mismatch for $1" >&2; exit 1; }
}

want() { [[ -x "$BIN/$1" ]] && return 1 || return 0; }

if want termscp; then
  echo "• termscp 1.2.2"
  fetch termscp.tgz https://github.com/veeso/termscp/releases/download/v1.2.2/termscp-v1.2.2-x86_64-unknown-linux-musl.tar.gz \
    4090063a276f697bb90c6090e7c1d7f50c4a1bce37ec8a98b206f81103f2be32
  tar -xzf "$TMP/termscp.tgz" -C "$TMP" termscp && install -m755 "$TMP/termscp" "$BIN/termscp"
fi

if want yazi; then
  echo "• yazi 26.9.1"
  fetch yazi.zip https://github.com/sxyazi/yazi/releases/download/v26.9.1/yazi-x86_64-unknown-linux-gnu.zip \
    a02fe91d3304294048c681f010f1100856872a4e98ecf6927328e888d40a6ad2
  unzip -q -o "$TMP/yazi.zip" -d "$TMP/yazi"
  install -m755 "$TMP"/yazi/*/yazi "$TMP"/yazi/*/ya "$BIN/"
fi

if want xremap; then
  echo "• xremap 0.15.18 (KDE build)"
  fetch xremap.zip https://github.com/xremap/xremap/releases/download/v0.15.18/xremap-linux-x86_64-kde.zip \
    89a4ab4bf4d158723b9b8c5e9230d46b2ed8ee96c29d6780f38c9928a6df29da
  unzip -q -o "$TMP/xremap.zip" -d "$TMP/xremap" && install -m755 "$TMP/xremap/xremap" "$BIN/xremap"
fi

fonts_now="$(fc-list : family 2>/dev/null || true)"
if [[ "$fonts_now" != *"SpaceMono Nerd Font"* ]]; then
  echo "• SpaceMono Nerd Font 3.5.1"
  fetch spacemono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/SpaceMono.zip \
    975ad5965fadf3c82c34e93d7d9ae139534d1f6ec38b388e7b36e6e6414901e3
  mkdir -p "$FONTS/SpaceMonoNF"
  unzip -q -o "$TMP/spacemono.zip" '*.ttf' -d "$FONTS/SpaceMonoNF"
  fc-cache -f "$FONTS" >/dev/null 2>&1 || true
fi
echo "binaries: done"
