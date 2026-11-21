---
id: operations.rollback
domain: operations
status: active
owns:
  - specs/operations/rollback.spec.md
---
# Rollback Spec

## Purpose

Define rollback behavior for failed releases or deployments.

## Scope

This spec covers rollback triggers, responsibilities, and validation for repositories created from this template.

## Inputs

- Release process defined by a derived repository
- Deployment process defined by a derived repository
- Incident or validation failure signals

## Outputs

- Rollback criteria
- Recovery steps
- Links from release and deployment specs to rollback behavior

## Acceptance Criteria

- Repositories with release or deployment automation define rollback criteria before production use.
- Rollback behavior links to release and deployment specs.
- Repositories with no release or deployment target state that rollback is not applicable.

## Validation

- Reviewed during SDD planning and pull request review.