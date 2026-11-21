---
id: build.build-system
domain: build
status: active
owns:
  - tools/sdd/**
  - build/**
---
# Build-System Spec

## Purpose

Define the source-of-truth contract for local builds, CI/CD, validation, and release automation.

## Scope

This spec governs files under `.github/workflows/`, `.vscode/`, `build/`, and `tools/` when they affect build, test, validation, artifact, or release behavior.

## Inputs

- Source files
- Specifications under `specs/`
- Toolchain definitions from `specs/build/toolchain.spec.md`
- Local development rules from `specs/build/local-dev.spec.md`
- CI/CD rules from `specs/build/ci-cd.spec.md`
- Quality gate rules from `specs/build/quality-gates.spec.md`

## Outputs

- Local developer commands
- CI/CD workflows
- Validation scripts
- Spec creation templates and generator scripts
- Build artifacts
- Release artifacts
- Traceability and spec metadata validation results
- Validator test results
- Draft spec sets created from repository templates

## Required Commands

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/generate-build-files.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/generate-build-files.ps1 -Check
powershell -ExecutionPolicy Bypass -File ./tools/dev/doctor.ps1
```

## Acceptance Criteria

- Specification validation runs before implementation validation.
- Build-system changes update this spec or a more specific `specs/build/` spec.
- CI and local validation share the same script entry points where possible.
- Required workflows are documented in `specs/build/ci-cd.spec.md`.
- Required local commands are documented in `specs/build/local-dev.spec.md`.
- Spec metadata and changed-file traceability are validated before merge.
- Cross-platform Bash launchers under `tools/sdd/*.sh` and `tools/dev/doctor.sh` delegate to the PowerShell validators without duplicating validation logic.
- Owned path declarations are checked for exact duplicates and wildcard containment overlaps.
- SDD validator behavior is covered by deterministic local tests.
- Validator tests invoke nested PowerShell validation commands through the available PowerShell host, using `pwsh` in CI and falling back to `powershell` where needed locally, while capturing expected child-process failures as test output.
- Validator tests keep temporary Git repository setup deterministic and isolate native Git stderr so benign native-tool output does not fail CI PowerShell steps.
- Validator test subprocesses do not inherit the caller's GitHub pull request event or base ref; tests may explicitly supply their own context to exercise traceability validation.
- Validator tests explicitly exit successfully after all expected failure cases pass so CI shell wrappers do not reuse a stale native-process exit code.
- New feature, executable, subcomponent, and build-system specs are created from `build/templates/specs/` through `tools/sdd/new-spec-set.ps1`.
- Build-system validation checks that required workflow, governance, prompt, generator, and spec-template artifacts exist.
- Build-system validation checks that the feature-spec and build-spec prompts keep product and build-system responsibilities separated.
- A spec-ownership manifest is generated from spec metadata by `tools/sdd/generate-build-files.ps1` and can be checked for staleness with `-Check`.
- Build-system verification checks that each Bash launcher exists and delegates to its PowerShell source of truth.
- Build-system verification checks that generated ownership-manifest validation is wired into CI.
- Build-system verification rejects VS Code tasks that depend on a terminal shell, omit the workspace working directory, or use inconsistent PowerShell hosts or script arguments.
- Build-system verification checks PowerShell workflow shells and script invocation arguments, spec-first build-system validation, and retention of lifecycle artifacts during template personalization.
- Regression tests validate a full personalized template checkout, including the generated ownership manifest, and reject task/workflow shell drift.

## Validation

- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1`
