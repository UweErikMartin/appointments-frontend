# Contributing

This repository follows Spec-Driven Design (SDD). Read `AGENTS.md` and `specs/README.md` before contributing.

## Workflow

1. Identify the controlling spec under `specs/` for your change.
2. If behavior changes, update the controlling spec in the same pull request.
3. For build, CI, release, toolchain, or local development changes, update `specs/build/` first.
4. Implement the smallest coherent change once the spec is clear enough to validate.
5. Update tests and build-system artifacts.
6. Run all required validation commands and fix failures before opening a pull request.

## Domain Boundaries For Spec Creation

- Use the `/create-feature-spec` prompt only for product features, executables, and subcomponents.
- Use the `/update-build-spec` prompt only for build-system specs under `specs/build/`.
- Do not change build-system files from a product-feature change, and do not change product specs from a build-system change.

## Required Validation

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1
powershell -ExecutionPolicy Bypass -File ./tools/dev/doctor.ps1
```

On Linux or macOS, run the same scripts with `pwsh`, for example `pwsh ./tools/sdd/validate-specs.ps1`, or use the Bash launchers, for example `bash ./tools/sdd/validate-specs.sh`. The repository ships a `.devcontainer` with PowerShell preinstalled.

## Pull Requests

Pull requests must identify the controlling spec, summarize spec-to-code traceability, record validation results, and call out any generated or derived files, using `.github/pull_request_template.md`.

## Local Hooks

Enable the bundled pre-commit hook once per clone:

```powershell
git config core.hooksPath .githooks
```

The hook runs spec and build-system validation before each commit.
