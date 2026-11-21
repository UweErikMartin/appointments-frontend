# GitHub Branch Protection

Configure the default branch so SDD checks are required before merge.

## Required Status Checks

- `ci / SDD validation`
- `spec-validation / Validate specs`
- `build-system-validation / Verify build-system specs`

## Recommended Rules

- Require pull requests before merging.
- Require the required status checks to pass before merging.
- Require branches to be up to date before merging when the repository uses merge queues or long-lived branches.
- Require review from `CODEOWNERS` for files covered by ownership rules.
- Restrict direct pushes to the default branch.
- Do not allow bypassing required checks except for documented emergency hotfixes in `AGENTS.md`.

## SDD Review Expectations

Reviewers should confirm that the pull request names the controlling spec, updates non-draft specs before implementation, and records generated or derived files.