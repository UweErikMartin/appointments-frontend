# GitHub Copilot Instructions

This repository is governed by Spec-Driven Design.

Before implementing:

1. Identify the controlling spec under `specs/`.
2. Check whether the requested behavior requires a spec update.
3. Refine placeholder specs before implementation; do not implement from vague acceptance criteria.
4. Implement only after the spec is clear enough to validate.
5. Update tests and build validation when behavior changes.
6. Run spec, traceability, and build-system validation.
7. Mention spec-to-code traceability in the pull request summary.

Build-system files are governed by `specs/build/`. Do not treat workflow, task, Docker, or script files as the source of truth when a build spec exists.