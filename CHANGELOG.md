# Changelog

## Unreleased

- Separates spec-creation prompts by domain: `/create-feature-spec` creates product specs only and `/update-build-spec` governs build-system specs only, with cross-domain edits disallowed.
- Adds an MIT `LICENSE`, `CONTRIBUTING.md`, `.editorconfig`, `.gitignore`, an opt-in pre-commit hook under `.githooks/`, and a `.devcontainer/` for non-Windows contributors.
- Adds one-time template personalization through `tools/template/bootstrap.ps1` and the `template-cleanup` workflow.
- Implements `tools/sdd/generate-build-files.ps1` to generate and check a spec-ownership manifest.
- Adds least-privilege `permissions` to validation workflows and relaxes the `CODEOWNERS` gate so adopters can personalize ownership.
- Expands `tools/sdd/test-validators.ps1` with positive and additional negative validator cases.

## 0.1.0

- Establishes the repository as a production-oriented SDD template.
- Adds spec metadata, governance files, traceability validation, and template adoption guidance.
- Documents required SDD validation commands for local and CI use.
