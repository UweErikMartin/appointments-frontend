# Agent Operating Contract

This repository follows Spec-Driven Design (SDD).

## Rules

- Read the relevant files under `specs/` before changing implementation.
- If any observable input/output behavior, API contract, or workflow step changes from what the controlling spec currently describes, update that spec in the same pull request.
- If build, CI, release, or local development behavior changes, update `specs/build/` first.
- Treat build-system files as implementation artifacts of `specs/build/`.
- Prefer changes scoped to a single spec file. If a change must touch multiple specs, they must share a single stated objective and be listed together in the pull request description.
- If a request cannot be scoped to a single spec or a single-objective spec group, split it into separate pull requests before proceeding.
- For emergency hotfixes, implementation may precede spec update, but a follow-up pull request updating the controlling spec must be opened within one business day and linked to the hotfix pull request.
- Keep generated or derived files traceable to their controlling spec.
- Do not implement from placeholder-only specs; first refine purpose, inputs, outputs, acceptance criteria, and validation.

## Definition Of Ready

A behavior-changing request is ready for implementation when it has one controlling spec or a single-objective spec group, measurable acceptance criteria, known build impact, and a validation plan.

## Definition Of Done

A change is done when controlling specs are updated, implementation and generated files are traceable to those specs, required validation passes, and pull request metadata records the spec-to-code relationship.

## Standard Workflow

1. Identify the request and controlling spec.
2. If no controlling spec exists, create one in the matching `specs/` domain folder (for example, `specs/build/` for build changes), use a kebab-case filename, and include purpose, behavior contract (inputs/outputs), and acceptance criteria.
3. Update the controlling spec when behavior is unclear or changing.
4. Run spec validation (`validate-specs.ps1`) and fix any failures before implementation.
5. Implement the smallest coherent change.
6. Update tests and build-system artifacts.
7. Run traceability and implementation/build validation (`check-traceability.ps1` and `verify-build-spec.ps1`) and treat any failure as release-blocking until fixed.
8. Summarize spec-to-code traceability in the pull request.

## Required Checks

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1
```