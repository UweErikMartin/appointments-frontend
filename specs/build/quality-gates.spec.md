---
id: build.quality-gates
domain: build
status: active
owns:
  - .github/pull_request_template.md
  - CODEOWNERS
  - docs/github-branch-protection.md
---
# Quality Gates Spec

## Purpose

Define the quality gates required before merging SDD-governed changes.

## Scope

This spec covers repository-wide gates for specs, implementation changes, generated files, pull request metadata, and ownership review.

## Inputs

- Pull request changes
- Controlling specs and spec metadata
- Validation results from `tools/sdd/`
- Pull request traceability fields

## Outputs

- Merge readiness decision
- Branch protection guidance for required SDD checks
- Required check status
- Traceability record for reviewers and agents

## Acceptance Criteria

- Every behavior-changing pull request identifies a controlling spec or single-objective spec group.
- Spec files contain unique metadata identifiers.
- Owned path declarations do not conflict across specs, including wildcard containment overlaps.
- Implementation changes are accompanied by a non-draft controlling spec change or an explicit controlling-spec reference in pull request metadata.
- Pull requests do not implement behavior from specs that remain status: draft.
- Required local validation commands are listed in the pull request template.
- Ownership and security review expectations are discoverable from repository-root files.
- `CODEOWNERS` defines at least one owner reference and may be personalized per repository.
- Required SDD checks are documented for GitHub branch protection or rulesets.

## Validation

- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1`
