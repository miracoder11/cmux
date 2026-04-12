# Phase 2 Plan

## Tasks

- Extend `SidebarSelection` with `files` and `git` activities.
- Add a compact activity switcher at the top of `VerticalTabsSidebar`.
- Keep the current workspace list under the Workspaces activity.
- Embed `FileExplorerPanelView` in the Files activity using the existing `FileExplorerStore`.
- Persist the new sidebar selections through session restore.
- Add keyboard shortcuts for Workspaces, Files, and Git sidebar activities.

## Verification

- Run low-cost local checks: shell syntax and `git diff --check`.
- Push to the fork branch and validate through the existing fork build workflow.
