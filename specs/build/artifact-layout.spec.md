---
id: build.artifact-layout
domain: build
status: active
owns:
  - artifacts/**
  - docs/generated/**
---
# Artifact Layout Spec

## Purpose

Define where generated and build artifacts are written.

## Scope

This spec covers repository-local artifact paths, generated documentation paths, and CI artifact publication.

## Inputs

- Build outputs
- Generated documentation
- Validation reports
- Source specs and generators

## Outputs

- Repository-local artifacts under `artifacts/`
- Generated documentation under `docs/generated/`
- Traceability from generated files back to source specs or generators

## Acceptance Criteria

- Generated or derived files have a documented source spec or generator.
- Build outputs do not obscure source-of-truth specs.
- CI artifacts use paths documented by this spec or a more specific build spec.

## Validation

- Reviewed during SDD planning and pull request review.
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1`