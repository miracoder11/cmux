# Project: cmux Fork Customization

## Vision

Turn the cmux fork into a developer workspace shell with a left sidebar that switches between workspace tasks, a filesystem tree, and Git state.

## Current User Goals

- Keep local setup light; avoid requiring local Xcode for daily iteration.
- Use fork-side GitHub Actions for build, launch smoke, and screenshot verification.
- Move file explorer access into the left sidebar as a functional activity area.
- Add a Git-focused sidebar area for branch and working tree state.
- Improve the default visual feel without broad redesign churn.

## Constraints

- Do not depend on local Xcode for validation.
- Preserve upstream cmux patterns and avoid broad refactors.
- Keep changes scoped to the fork branch until the direction is validated.

