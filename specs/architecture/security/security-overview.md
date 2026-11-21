---
id: architecture.security-overview
domain: architecture
status: active
owns:
  - specs/architecture/security/**
  - SECURITY.md
---
# Security Overview

## Purpose

Define repository-wide security expectations for the SDD template repository.

## Scope

This document covers template-level security assumptions and links to detailed security specs added by derived repositories.

## Inputs

- Contributor changes
- Generated or derived files
- CI and local validation outputs
- Product-specific security requirements added after template adoption

## Outputs

- Security expectations that are visible before implementation
- A place to link product-specific threat models and controls
- Review prompts for secrets, dependency, and generated-file traceability

## Acceptance Criteria

- The spec is understandable to a new contributor.
- Related implementation links back to this spec when added.
- Derived repositories define product-specific security controls before shipping product behavior.
- Security reporting expectations are documented at the repository root.

## Validation

- Reviewed during SDD planning and pull request review.
