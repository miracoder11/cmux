# Phase 4 Plan

## Tasks

- Replace the default bright blue accent with a calmer green-teal accent.
- Keep activity controls small and layout-stable inside the sidebar.
- Run low-cost local validation.
- Push and wait for the fork build workflow.

## Verification

- `git diff --check`
- `bash -n scripts/fork-build-verify.sh scripts/smoke-test-ci.sh`
- GitHub Actions `Fork Build Verify`
