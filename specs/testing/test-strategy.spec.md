---
id: testing.test-strategy
domain: testing
status: active
owns:
  - tests/**
  - specs/testing/test-strategy.spec.md
---
# Test Strategy Spec

## Purpose

Define repository-wide testing strategy for SDD-governed template and product code.

## Scope

This spec covers unit, integration, end-to-end, contract, acceptance, regression, and validator tests introduced by repositories created from this template.

## Inputs

- Controlling specs and acceptance criteria
- Implementation code added by derived repositories
- Build and validation scripts
- Generated or derived artifacts

## Outputs

- Tests mapped to acceptance criteria
- Contract checks for public interfaces
- Regression coverage for fixed defects
- Validation evidence for pull requests

## Acceptance Criteria

- New behavior includes tests or an explicit spec-backed reason tests are not applicable.
- Interface changes include contract or compatibility checks when feasible.
- Generated artifacts identify their source spec or generator.
- Validator behavior is covered by deterministic local or CI checks.
- Pull requests summarize the validation performed.

## Validation

- Reviewed during SDD planning and pull request review.
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1`