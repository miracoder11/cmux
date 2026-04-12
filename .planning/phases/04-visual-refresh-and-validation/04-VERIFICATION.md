# Phase 4 Verification

## Local Checks

- `git diff --check` passed.
- `bash -n scripts/fork-build-verify.sh scripts/smoke-test-ci.sh` passed.

## CI

- Fork Build Verify run `24307730233` passed.
- Head SHA: `b99f59e300821018ddf05d6184b6e349a9098195`.
- Run URL: https://github.com/miracoder11/cmux/actions/runs/24307730233
- Xcode 16.4 on GitHub-hosted macOS built `cmux DEV.app`.
- Smoke launch created a virtual 1920x1080 display, received `PONG`, sent the `time` command with `OK`, received final `PONG`, and uploaded `cmux-smoke.png`.
