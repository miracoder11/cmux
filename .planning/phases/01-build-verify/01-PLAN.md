# Phase 1 Plan: Fork Build Verify

## Objective

Create a fork-side build verification workflow that can build and smoke-launch cmux without local Xcode.

## Tasks

- Add a reusable build script.
- Add a GitHub-hosted macOS workflow.
- Download prebuilt GhosttyKit.
- Build Debug app with Xcode.
- Launch the app in CI with a virtual display.
- Capture screenshot and logs.

