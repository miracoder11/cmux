# Phase 3 Context

## Goal

Add a Git sidebar activity that gives a quick summary of the selected workspace's repository state.

## Inputs

- Workspace metadata already exposes branch, directory, and pull request summaries.
- `FileExplorerStore` already maintains `gitStatusByPath` from the file explorer's Git scan.

## Constraints

- Do not add a second Git scanner when the file explorer store already has status data.
- Keep the Git view compact enough for the existing sidebar width.
