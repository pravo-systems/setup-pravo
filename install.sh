#!/usr/bin/env bash
# Installs pravo for the runner: resolve the version, download the archive and
# SHA256SUMS from the release, check the digest, unpack, add to PATH.
set -euo pipefail
repo=pravo-systems/pravo
want=${INPUT_VERSION:-latest}
want=${want#v}

case "$RUNNER_OS" in
  Linux) os=linux; ext=tar.gz ;;
  macOS) os=darwin; ext=tar.gz ;;
  Windows) os=windows; ext=zip ;;
  *) echo "::error::Unsupported runner OS $RUNNER_OS"; exit 1 ;;
esac
case "$RUNNER_ARCH" in
  X64) arch=amd64 ;;
  ARM64) arch=arm64 ;;
  *) echo "::error::Unsupported runner architecture $RUNNER_ARCH"; exit 1 ;;
esac

api() { curl -fsSL -H "Authorization: Bearer ${GH_TOKEN:-}" -H "Accept: application/vnd.github+json" "$@"; }

if [ "$want" = latest ]; then
  version=$(api "https://api.github.com/repos/$repo/releases/latest" | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1)
  [ -n "$version" ] || { echo "::error::Could not resolve the latest release of $repo"; exit 1; }
else
  version=$want
fi

name=pravo_${version}_${os}_${arch}
tool_root=${RUNNER_TOOL_CACHE:-${RUNNER_TEMP}}/pravo/$version/${os}_${arch}
if [ -x "$tool_root/$name/pravo" ] || [ -x "$tool_root/$name/pravo.exe" ]; then
  echo "pravo $version is in the tool cache"
else
  tmp=$(mktemp -d)
  base=https://github.com/$repo/releases/download/v$version
  curl -fsSL -o "$tmp/$name.$ext" "$base/$name.$ext"
  curl -fsSL -o "$tmp/SHA256SUMS" "$base/SHA256SUMS"
  want_sum=$(awk -v f="$name.$ext" '$2 == f || $2 == "*" f {print $1}' "$tmp/SHA256SUMS")
  [ -n "$want_sum" ] || { echo "::error::SHA256SUMS has no entry for $name.$ext"; exit 1; }
  if command -v sha256sum >/dev/null 2>&1; then got=$(sha256sum "$tmp/$name.$ext" | awk '{print $1}'); else got=$(shasum -a 256 "$tmp/$name.$ext" | awk '{print $1}'); fi
  [ "$got" = "$want_sum" ] || { echo "::error::Checksum mismatch for $name.$ext"; exit 1; }
  if [ "${VERIFY:-false}" = true ]; then
    gh attestation verify "$tmp/$name.$ext" --repo "$repo"
  fi
  mkdir -p "$tool_root"
  if [ "$ext" = zip ]; then unzip -q "$tmp/$name.$ext" -d "$tool_root"; else tar -xzf "$tmp/$name.$ext" -C "$tool_root"; fi
  rm -rf "$tmp"
fi

dir=$tool_root/$name
if [ "$RUNNER_OS" = Windows ]; then dir=$(cygpath -w "$dir"); fi
echo "$dir" >> "$GITHUB_PATH"
echo "version=$version" >> "$GITHUB_OUTPUT"
echo "path=$dir" >> "$GITHUB_OUTPUT"
