# Phase 2 Context

## Goal

Add first-class sidebar activity switching so the existing workspace list remains available while the file tree can live in the left sidebar.

## Starting Point

- Upstream PR #1963 already provides `FileExplorerStore`, `FileExplorerPanelView`, SSH/local providers, and Git file status parsing.
- The branch previously exposed the file explorer mainly as an optional right-side panel.
- `SidebarSelection` only supported workspace tabs and notifications.

## Constraints

- Reuse the existing file explorer implementation.
- Keep the workspace list as the default activity.
- Avoid requiring local Xcode for validation.
