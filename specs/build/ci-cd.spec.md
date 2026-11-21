---
id: build.ci-cd
domain: build
status: active
owns:
  - .github/workflows/**
  - .github/dependabot.yml
---
# CI/CD Spec

## Purpose

Define continuous integration and delivery behavior.

## Scope

This spec controls GitHub Actions workflows under `.github/workflows/` and dependency update automation that affects CI behavior. It includes the one-time template-cleanup workflow that personalizes repositories created from this template.

## Inputs

- Pull requests
- Pushes to `main`
- Repository specifications
- Build-system validation scripts
- Traceability validation scripts

## Outputs

- Spec validation result
- Traceability validation result
- Validator test result
- Generated ownership manifest freshness result
- Build-system traceability result
- Future implementation build and test results

## Required Workflows

- `.github/workflows/spec-validation.yml`
- `.github/workflows/build-system-validation.yml`
- `.github/workflows/ci.yml`

## Required Jobs

- Validate specs
- Check SDD traceability
- Verify build-system traceability
- Test SDD validators
- Check generated ownership manifest

## Acceptance Criteria

- CI runs on pull requests.
- CI runs on pushes to `main`.
- Spec validation is required before implementation validation.
- Traceability validation runs in CI for pull requests and local validation.
- Validator tests run in CI before merge.
- Generated ownership manifest freshness is checked in CI before merge.
- Build-system validation checks that local and CI entry points are documented.
- GitHub Actions dependencies are covered by Dependabot.
- Validation workflows declare least-privilege `permissions` (read-only content access).
- Every workflow runs PowerShell commands with `shell: pwsh` and invokes script entry points with `pwsh -NoProfile -ExecutionPolicy Bypass -File`, matching local VS Code task arguments.
- The build-system validation workflow validates specs before build-system checks.
- A one-time `.github/workflows/template-cleanup.yml` personalizes repositories created from the template through `tools/template/bootstrap.ps1` and does not run on the template repository.
- Template personalization retains lifecycle scripts, their controlling spec, and the cleanup workflow so local tasks, validator tests, and generated ownership-manifest checks remain valid. Subsequent runs make no further personalization changes.
- Repository metadata used by personalization is passed through environment variables rather than interpolated into PowerShell source.

## Validation

- GitHub Actions executes the required workflows.
- Local equivalent: `pwsh ./tools/sdd/verify-build-spec.ps1`
