# Specifications

This directory is the source of truth for repository behavior.

## Layout

- `product/` describes user-facing goals, requirements, features, and ADRs.
- `architecture/` describes system structure, interfaces, data, and security.
- `build/` describes local builds, CI/CD, release gates, tools, and artifacts.
- `testing/` describes test strategy and acceptance coverage.
- `operations/` describes deployment, observability, and rollback behavior.

## Spec Rules

Every behavior-changing pull request should identify the controlling spec, acceptance criteria, tests or checks, and build-system impact.
