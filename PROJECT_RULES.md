# Project rules

## Git / merge requests

- Do not add `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (or any other AI attribution line) to commit
  messages, code comments, or MR/PR descriptions.
- Agrekom packages (`src/vendor/agrekom/*`, `e-warsztat/*`, both child themes): work on a branch off `2.x`,
  merge into `2.x`, tag `v2.x.x`. See [migration/README.md](migration/README.md#working-on-a-package).
- After a new package tag: update `migration/composer.lock` in **this** repo, commit and push it.
  `src/` is git-ignored – nothing under it is committed here.

## Third-party code

- Do not edit `creativestyle/theme-creativeshop` or other vendor packages we have no repository access to.
  Fix in our own packages instead (e.g. a plugin in `agrekom/core-module`, an override in a child theme).
