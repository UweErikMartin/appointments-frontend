---
id: product.requirements.sdd-template-repository
domain: product
status: active
owns:
  - README.md
  - AGENTS.md
  - LICENSE
  - CONTRIBUTING.md
  - .github/copilot-instructions.md
  - .github/instructions/**
  - .github/prompts/**
  - docs/examples/**
  - docs/template-upgrade.md
---
# SDD Template Repository Spec

## Purpose

Define the product contract for this repository as a reusable Spec-Driven Design template.

## Scope

This spec covers repository identity, template adoption guidance, contributor workflow expectations, baseline SDD traceability, governance files, and agent-facing repository instructions. Build-system behavior remains governed by `specs/build/`.

## Inputs

- A newly created repository based on this template
- Product, architecture, build, testing, and operations specs under `specs/`
- Agent and contributor instructions in `AGENTS.md` and `.github/`
- Validation scripts under `tools/sdd/`
- Pull request metadata supplied through `.github/pull_request_template.md`

## Outputs

- A repository structure ready for SDD-based product development
- Clear onboarding guidance for humans and coding agents
- Pull request metadata that records controlling specs, validation, and traceability
- Placeholder specs that are safe to refine for a concrete product
- Governance files for ownership, security reporting, and template lifecycle decisions
- A repository license and contribution guidelines at the repository root
- A documented procedure for adopting later template versions
- Prompt-driven draft spec creation for features, executables, subcomponents, and build-system changes
- Example request-to-spec workflows for common SDD coding tasks

## Definition Of Ready

A behavior-changing request is ready for implementation when it has one controlling spec or a single-objective spec group, measurable acceptance criteria, known build impact, and a validation plan.

## Definition Of Done

A change is done when controlling specs are updated, implementation and generated files are traceable to those specs, required validation passes, and pull request metadata records the spec-to-code relationship.

## Acceptance Criteria

- The repository name and documentation describe an SDD template, not a domain-specific product.
- No template-owned documentation refers to the previous product name.
- A new contributor can identify the controlling spec before implementation.
- Pull requests provide fields for controlling specs, changes, validation, and build impact.
- Required validation commands remain documented and runnable from the repository root.
- Agent instructions define ready/done expectations that discourage implementation from vague specs.
- Governance files define code ownership and security reporting expectations.
- A repository license and contribution guide are present at the repository root.
- A documented template-upgrade procedure lets adopters pull later template improvements without overwriting product specs.
- Agent prompts require template-based spec creation and user confirmation for ambiguity, build-system choices, or conflicts.
- The feature-spec prompt creates only product feature, executable, and subcomponent specs and routes build-system requests to the build-spec prompt.
- The build-spec prompt governs only build-system specs and routes product-behavior requests to the feature-spec prompt.
- Neither prompt edits files outside its domain: the feature-spec prompt does not change build-system files, and the build-spec prompt does not change product, architecture, or testing specs.
- Example workflows show when agents should proceed and when they should ask for confirmation.

## Validation

- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1`
