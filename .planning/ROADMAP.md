# Roadmap

## Milestone v1.0: Sidebar Files and Git

- [x] **Phase 1: Fork Build Verify** (completed 2026-04-12)
- [x] **Phase 2: Sidebar Activity Switcher and File Explorer** (completed 2026-04-12)
- [x] **Phase 3: Git Sidebar Status** (completed 2026-04-12)
- [x] **Phase 4: Visual Refresh and Validation** (completed 2026-04-12)

### Phase 1: Fork Build Verify
**Goal**: Establish a light build, launch, and screenshot verification path that does not require local Xcode.
**Requirements**: FR-01, FR-06
**Plans:** 1/1 plans complete

Plans:
- [x] 01-PLAN.md - Add fork build workflow, smoke launch, screenshot artifacts

**Success Criteria**:
1. GitHub Actions builds the app on macOS.
2. CI launches the app and verifies socket responsiveness.
3. CI uploads app and screenshot artifacts.

### Phase 2: Sidebar Activity Switcher and File Explorer
**Goal**: Add Workspaces, Files, and Git activity switching to the left sidebar, with Files showing the current workspace file tree.
**Requirements**: FR-02, FR-03, FR-05
**Plans:** 1/1 plans complete

Plans:
- [x] 02-PLAN.md - Add sidebar activity switcher and embed FileExplorerPanelView in the Files activity

**Success Criteria**:
1. Sidebar exposes Workspaces, Files, and Git activity controls.
2. Files activity renders the selected workspace directory tree.
3. Existing workspace list remains available as the default activity.
4. Keyboard shortcut can open the Files activity.

### Phase 3: Git Sidebar Status
**Goal**: Add a Git activity section that summarizes branch, dirty state, current directories, pull requests, and file status counts.
**Requirements**: FR-04, FR-05
**Plans:** 1/1 plans complete

Plans:
- [x] 03-PLAN.md - Build Git sidebar status view from Workspace and FileExplorerStore state

**Success Criteria**:
1. Git activity displays the selected workspace.
2. Git activity shows branches and dirty status.
3. Git activity shows file status counts from the file explorer Git scan.
4. Keyboard shortcut can open the Git activity.

### Phase 4: Visual Refresh and Validation
**Goal**: Improve default sidebar visual tone and verify build, launch, and screenshot output on the fork.
**Requirements**: FR-06, NFR-02
**Plans:** 1/1 plans complete

Plans:
- [x] 04-PLAN.md - Tune default accent/sidebar styling and run fork verification

**Success Criteria**:
1. Default accent is less harsh than the current bright blue.
2. Sidebar activity controls are stable and legible.
3. Fork Build Verify workflow passes after implementation.
4. Smoke screenshot artifact shows the app rendering.

## Progress Tracking

| Phase | Plans | Status | Completed |
|-------|-------|--------|-----------|
| 1 | 1/1 | Complete | 2026-04-12 |
| 2 | 1/1 | Complete | 2026-04-12 |
| 3 | 1/1 | Complete | 2026-04-12 |
| 4 | 1/1 | Complete | 2026-04-12 |

**Last Updated**: 2026-04-12
