---
id: architecture.system-context
domain: architecture
status: active
owns:
  - specs/architecture/system-context.md
---
# System Context

## Purpose

Describe the SDD template repository boundary and external dependencies.

## Scope

This spec covers repository-level context for the template. Product-specific component internals belong in `specs/architecture/components/` after a derived repository defines them.

## Inputs

- Specifications under `specs/`
- Contributor and agent instructions
- Local and CI validation entry points

## Outputs

- A governed repository structure for SDD work
- Traceability between specs, generated files, implementation, and validation
- Clear boundaries for product-specific additions in derived repositories

## Acceptance Criteria

- The spec is understandable to a new contributor.
- Related implementation links back to this spec when added.
- Product-specific architecture is added through new or updated specs before implementation.

## Validation

- Reviewed during SDD planning and pull request review.