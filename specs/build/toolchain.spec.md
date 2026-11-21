---
id: build.toolchain
domain: build
status: active
owns:
  - .vscode/extensions.json
  - .devcontainer/**
---
# Toolchain Spec

## Purpose

Define required tools and version expectations.

## Scope

This spec covers tools required for repository validation, local development, and CI/CD.

## Inputs

- Repository checkout
- Git
- Windows PowerShell 5 or PowerShell 7 compatible shell
- GitHub Actions Ubuntu runner with `pwsh`

## Outputs

- Deterministic local and CI validation commands
- Actionable toolchain diagnostics
- Recommended editor extensions
- A reproducible container-based development environment with PowerShell through `.devcontainer/`

## Acceptance Criteria

- Local diagnostics verify Git and PowerShell availability.
- CI workflows use `pwsh` for PowerShell script parity.
- Recommended editor extensions are documented where applicable.
- A dev container provides PowerShell and recommended extensions for contributors without local PowerShell.
- Toolchain changes update local development and CI specs when they affect workflows.

## Validation

- `powershell -ExecutionPolicy Bypass -File ./tools/dev/doctor.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`
