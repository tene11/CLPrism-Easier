#!/usr/bin/env bash
# Tries the patches on a Prism Launcher release.
#
# Inputs (environment):
#   TARGET_TAG  Prism Launcher tag to try. Empty: the latest release.
#   FORCE       "true" to try even if the tag is current or was already handled.
#   WORK_DIR    Scratch folder (default: .work next to this repository).
# Outputs (stdout, and $GITHUB_OUTPUT when set):
#   tag, current, base and result = up-to-date | already-handled | applied | apply-failed
# On "applied", patches/ and PRISM_VERSION are rewritten for the new tag and the patched
# source is left in $WORK_DIR/upstream for a build check.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
work="${WORK_DIR:-$root/.work}"
current="$(tr -d '[:space:]' < "$root/PRISM_VERSION")"
tag="${TARGET_TAG:-}"
force="${FORCE:-false}"

out() {
    echo "$1=$2"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "$1=$2" >> "$GITHUB_OUTPUT"; fi
}

if [ -z "$tag" ]; then
    tag="$(gh api repos/PrismLauncher/PrismLauncher/releases/latest --jq .tag_name)"
fi
out tag "$tag"
out current "$current"

if [ "$force" != "true" ]; then
    if [ "$tag" = "$current" ]; then
        out result up-to-date
        exit 0
    fi
    # a pull request branch or an open issue for this tag means it was handled before
    if git -C "$root" ls-remote --exit-code --heads origin "prism-$tag" > /dev/null 2>&1; then
        out result already-handled
        exit 0
    fi
    if [ -n "${GITHUB_REPOSITORY:-}" ] &&
        [ -n "$(gh issue list --repo "$GITHUB_REPOSITORY" --state open --search "\"Prism Launcher $tag\" in:title" --json number --jq '.[].number')" ]; then
        out result already-handled
        exit 0
    fi
fi

rm -rf "$work/upstream"
mkdir -p "$work"
git clone --quiet --depth 1 --branch "$tag" --recurse-submodules --shallow-submodules \
    https://github.com/PrismLauncher/PrismLauncher.git "$work/upstream"
cd "$work/upstream"
# the old version's files let "git am --3way" merge patches whose context moved a little
git fetch --quiet --depth 1 origin tag "$current" || true
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config core.autocrlf false
base="$(git rev-parse HEAD)"
out base "$base"

if git am --3way "$root"/patches/*.patch > "$work/am.log" 2>&1; then
    cat "$work/am.log"
    rm -f "$root"/patches/*.patch
    git format-patch "$base..HEAD" --zero-commit --no-signature --quiet -o "$root/patches"
    echo "$tag" > "$root/PRISM_VERSION"
    out result applied
else
    cat "$work/am.log"
    git am --abort > /dev/null 2>&1 || true
    out result apply-failed
fi
