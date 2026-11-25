# docs/

Project documentation that doesn't belong in the root README or the
Flutter-specific `mobile/` docs.

## Structure

- `testing/manual-test-checklist.md` — template for manual testing passes.
  Copy its sections into the PR description, release PR, or a pinned issue
  when a change needs hands-on verification that automated tests cannot
  cover (real email delivery, platform UI behavior, CI workflow behavior).
- `testing/manual-test-run.md` — a completed checklist from a previous pass.
- `testing/manual-test-playbook.md` — playbook for running device/emulator passes:
  launch commands, adb/Maestro/simctl tooling, and gotchas.

## Conventions

- Do not commit per-run result files. Record outcomes in the relevant PR
  description, release notes, or `CHANGELOG.md` instead.
- Keep files flat and few; prefer updating an existing document over adding
  new ones.
