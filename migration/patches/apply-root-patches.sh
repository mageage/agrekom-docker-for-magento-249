#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
# Skip a parent Git worktree when Magento is installed in dev/src.
GIT_CEILING_DIRECTORIES=$(cd .. && pwd -P)
export GIT_CEILING_DIRECTORIES

# These Adobe hunks target the assembled Magento installation.
for patch in patches/root/*.patch; do
    if git apply --reverse --check "$patch" 2>/dev/null; then
        continue
    fi
    printf 'Applying %s\n' "$patch"
    git apply --whitespace=nowarn "$patch"
done
