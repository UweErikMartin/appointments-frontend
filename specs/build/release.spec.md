---
id: build.release
domain: build
status: active
owns:
  - SDD_TEMPLATE_VERSION
  - CHANGELOG.md
  - docs/template-adoption-checklist.md
---
# Release Spec

## Purpose

Define release readiness and publication behavior for the SDD template.

## Scope

This spec covers template versioning, release gates, migration notes, artifacts, and rollback links for downstream adopters.

## Inputs

- Template version file
- Changelog entries
- Spec and validation changes
- Migration impact for repositories created from this template

## Outputs

- Versioned SDD template releases
- Migration notes for downstream projects
- Release-ready validation status

## Acceptance Criteria

- Template releases update `SDD_TEMPLATE_VERSION` and `CHANGELOG.md` together.
- Breaking SDD workflow changes include migration guidance.
- Release candidates pass spec, traceability, build-system, and local doctor checks.
- Downstream adopters can identify required manual changes from release notes.

## Validation

- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1`