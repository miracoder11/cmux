# Requirements

## Functional Requirements

- FR-01: Fork build verification must run on GitHub-hosted macOS without local Xcode.
- FR-02: The left sidebar must expose first-class activity sections for Workspaces, Files, and Git.
- FR-03: The Files section must show the current workspace directory as a navigable tree.
- FR-04: The Git section must show current branch, dirty state, directories, pull requests when available, and file status counts.
- FR-05: Keyboard shortcuts must provide low-friction access to sidebar activity sections.
- FR-06: The app must continue to build and launch in CI, with screenshot artifacts for visual review.

## Non-Functional Requirements

- NFR-01: Implementation must reuse existing FileExplorerStore/FileExplorerPanelView where practical.
- NFR-02: UI changes must be layout-stable inside narrow sidebar widths.
- NFR-03: Generated build artifacts must stay in ignored locations.

