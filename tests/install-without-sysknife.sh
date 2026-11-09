#!/usr/bin/env bash
# Regression for #207: install.sh must install a checkout whose profiles/ holds
# no `sysknife` directory. It used to test for that one profile by name after
# copying, and exit 1 with "profiles did not land where run.sh expects".
#
# Runs install.sh from a scratch copy of the repository with only the magent
# profile present, into a scratch HOME. Offline; touches nothing outside the
# scratch directory.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

src="$scratch/repo"
home="$scratch/home"
mkdir -p "$src" "$home"
cp -r "$root/." "$src/"
rm -rf "$src/.git"
rm -rf "$src/profiles/sysknife"

out="$(HOME="$home" bash "$src/install.sh" 2>&1)"; rc=$?
if [ "$rc" != 0 ]; then
    echo "FAIL: install.sh exited $rc (expected 0)" >&2
    printf '%s\n' "$out" | tail -n 5 >&2
    exit 1
fi

deployed="$home/.local/share/maintainer/profiles/magent/profile.env"
if [ ! -f "$deployed" ]; then
    echo "FAIL: the magent profile was not deployed to $deployed" >&2
    exit 1
fi

if [ "$(uname -s)" = Linux ]; then
    units="$home/.config/systemd/user"
    if ! ls "$units"/maintainer@*.service >/dev/null 2>&1; then
        echo "FAIL: no systemd units were copied to $units" >&2
        exit 1
    fi
fi

echo "PASS: install.sh installs a checkout without a sysknife profile"
