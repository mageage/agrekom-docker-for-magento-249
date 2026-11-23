# Project rules

## Two repositories

| Repository | What | Who commits |
|------------|------|-------------|
| **github.com/mageage/agrekom-docker-for-magento-249** (this repo) | local Docker environment, our scripts, the `deployer` container, documentation | we do |
| **github.com/jarekherisz/agrekom**, branch `agrekom_249` – submodule [`agrekom/`](agrekom) | Deployer (`deploy.php`, `recipe/`), `magento/before_build/` (composer.json/lock, Adobe patches, server `disabled-modules.txt`), their `dev/` | DevOps |

- Our changes go to this repo only.
- **Never commit or push in `agrekom/` (git@github.com:jarekherisz/agrekom.git) unless the user explicitly asks.**
  A change we need there (e.g. `composer.lock` after a new package tag) is prepared in the submodule working tree and
  handed to DevOps as a diff or branch.
- DevOps changes reach us with `git submodule update --remote agrekom`; commit the new submodule pointer here
  (`git add agrekom && git commit`), so every commit of this repo names the Deployer/composer version it works with.
- Deployer runs only in the `deployer` container (`./scripts/deployer.sh …`), not with the host PHP.

## Git / merge requests

- Do not add `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (or any other AI attribution line) to commit
  messages, code comments, or MR/PR descriptions.
- Agrekom packages (`src/vendor/agrekom/*`, `e-warsztat/*`, both child themes): work on a branch off `2.x`,
  merge into `2.x`, tag `v2.x.x`. See [migration/README.md](migration/README.md#working-on-a-package).
- `src/` is git-ignored – nothing under it is committed here.

## Third-party code

- Do not edit `creativestyle/theme-creativeshop` or other vendor packages we have no repository access to.
  Fix in our own packages instead (e.g. a plugin in `agrekom/core-module`, an override in a child theme).
