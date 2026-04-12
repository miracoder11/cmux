---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Sidebar Files and Git
status: Complete
last_updated: "2026-04-12T13:28:54Z"
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 4
  completed_plans: 4
---

# Project State

## Current Status

- **Phase**: 04-visual-refresh-and-validation
- **Status**: Complete; CI build, smoke launch, and screenshot verification passed
- **Last Updated**: 2026-04-12T13:28:54Z

## Completed

- Fork build verification workflow runs on GitHub-hosted macOS.
- CI builds `cmux DEV.app`, creates a virtual display, launches the app, verifies socket ping/send, captures screenshot, and uploads artifacts.
- Left sidebar now has Workspaces, Files, and Git activities.
- Files activity embeds the existing file explorer tree for the selected workspace directory.
- Git activity summarizes branch/dirty state, directories, pull requests, and file status counts.
- Sidebar activity shortcuts are registered for Workspaces, Files, and Git.
- Default file explorer flag is on, and the accent color has moved away from the harsh blue.
- Fork Build Verify run `24307730233` passed on head `b99f59e300821018ddf05d6184b6e349a9098195`.

## Decisions

- Keep local setup light and use CI for Xcode validation.
- Build on top of the upstream file explorer PR branch for low-cost reuse.
- Keep the file explorer core but move product integration toward left-sidebar activity sections.
- Preserve the upstream right-side file explorer panel for now, but route the old file explorer shortcut and titlebar button into the new left Files activity.

## Local Caveat

- Local machine has no full Xcode, so local app build is intentionally unavailable.
