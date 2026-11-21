---
id: operations.deployment
domain: operations
status: active
owns:
  - specs/operations/deployment.spec.md
---
# Deployment Spec

## Purpose

Define deployment behavior expectations for repositories created from this SDD template.

## Scope

This spec covers template expectations for documenting deployment targets, deployment process, and required gates. Concrete deployment behavior belongs to derived repositories.

## Inputs

- Product-specific deployment targets added by a derived repository
- Build and release specs
- CI validation results

## Outputs

- A required location for deployment contracts
- Traceable deployment gates before product release automation is added
- Product-neutral placeholder guidance for repositories that do not deploy yet

## Acceptance Criteria

- The spec is understandable to a new contributor.
- Related implementation links back to this spec when added.
- Derived repositories replace placeholder deployment guidance before introducing deployment automation.
- Repositories with no deployment target state that deployment is not applicable before adding release automation.

## Validation

- Reviewed during SDD planning and pull request review.