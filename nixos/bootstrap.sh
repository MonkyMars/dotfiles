#!/usr/bin/env bash
set -euo pipefail

CACHE_URL="https://cache.lantian.pub/lantian"
CACHE_KEY="lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
SOPS_KEY_DEST="/var/lib/sops-nix/key.txt"
NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(git -C "$FLAKE_DIR" rev-parse --show-toplevel)"
TARGET_USER="$(id -un)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

confirm_yes() {
  local reply
  read -rp "$1 [Y/n] " reply
  [[ ! "$reply" =~ ^[Nn]$ ]]
}

confirm_no() {
  local reply
  read -rp "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

[[ $EUID -ne 0 ]] || die "run this as your normal user, not root"
[[ -e /etc/NIXOS ]] || die "this script must be run on NixOS"
for cmd in nix git sudo; do
  command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
done

if [[ $# -ge 1 ]]; then
  HOST="$1"
else
  DEFAULT_HOST="$(hostname)"
  read -rp "Hostname [$DEFAULT_HOST]: " HOST
  HOST="${HOST:-$DEFAULT_HOST}"
fi
[[ -n "$HOST" ]] || die "hostname must not be empty"

sudo -v
(
  while true; do
    sudo -n true
    sleep 50
    kill -0 "$$" 2>/dev/null || exit
  done
) &
KEEPALIVE_PID=$!
trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT

install_age_key() {
  local secret tmp expected actual user_key
  user_key="$HOME/.config/sops/age/keys.txt"

  if ! sudo test -s "$SOPS_KEY_DEST"; then
    [[ -f "$FLAKE_DIR/.sops.yaml" ]] || die "missing $FLAKE_DIR/.sops.yaml"
    read -rsp "Paste age secret key (AGE-SECRET-KEY-...): " secret
    echo
    [[ "$secret" == AGE-SECRET-KEY-* ]] || die "that is not an age secret key"

    tmp="$(mktemp)"
    chmod 600 "$tmp"
    printf '%s\n' "$secret" > "$tmp"
    unset secret

    actual="$(nix "${NIX_FLAGS[@]}" shell nixpkgs#age --command age-keygen -y "$tmp")"
    expected="$(grep -o 'age1[0-9a-z]*' "$FLAKE_DIR/.sops.yaml" | head -n 1)"
    if [[ "$actual" != "$expected" ]]; then
      rm -f "$tmp"
      die "key does not match the public key in .sops.yaml"
    fi

    sudo install -D -m 600 -o root -g root "$tmp" "$SOPS_KEY_DEST"
    rm -f "$tmp"
    echo "age key installed"
  else
    echo "age key already installed"
  fi

  if [[ ! -s "$user_key" ]]; then
    mkdir -p "$(dirname "$user_key")"
    sudo cat "$SOPS_KEY_DEST" | install -m 600 /dev/stdin "$user_key"
  fi
}

regen_hardware() {
  local out
  out="$(mktemp)"
  sudo nixos-generate-config --show-hardware-config > "$out"
  install -m 644 "$out" "$FLAKE_DIR/hardware-configuration.nix"
  rm -f "$out"
  echo "hardware-configuration.nix regenerated"
}

set_password() {
  local first second
  while true; do
    read -rsp "New password for $TARGET_USER (empty to skip): " first
    echo
    [[ -n "$first" ]] || return 0
    read -rsp "Repeat password: " second
    echo
    [[ "$first" == "$second" ]] && break
    echo "passwords do not match, try again"
  done
  printf '%s:%s\n' "$TARGET_USER" "$first" | sudo chpasswd
  echo "password set for $TARGET_USER"
}

install_age_key

if confirm_yes "Regenerate hardware-configuration.nix for this machine?"; then
  regen_hardware
fi

git -C "$REPO_DIR" add -A

available="$(nix "${NIX_FLAGS[@]}" eval --raw "$FLAKE_DIR#nixosConfigurations" \
  --apply 'c: builtins.concatStringsSep " " (builtins.attrNames c)')"
[[ " $available " == *" $HOST "* ]] \
  || die "no nixosConfigurations.$HOST in the flake (available: $available)"

sudo git config --global --get-all safe.directory | grep -qxF "$REPO_DIR" \
  || sudo git config --global --add safe.directory "$REPO_DIR"

echo "Building and switching to $HOST"
sudo nixos-rebuild switch --flake "$FLAKE_DIR#$HOST" \
  --option experimental-features "nix-command flakes" \
  --option extra-substituters "$CACHE_URL" \
  --option extra-trusted-public-keys "$CACHE_KEY"

set_password

echo "Done."
if confirm_no "Reboot now?"; then
  systemctl reboot
fi
