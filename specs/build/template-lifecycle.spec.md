---
id: build.template-lifecycle
domain: build
status: active
owns:
  - tools/template/**
---
# Template Lifecycle Spec

## Purpose

Define how a repository created from this template personalizes itself, preserves usable validation and update tooling, and later adopts template-only infrastructure updates.

## Scope

This spec governs template lifecycle tooling under `tools/template/`, including one-time bootstrap personalization and template-only update preparation. The GitHub Actions workflow that invokes first-use cleanup remains governed by `specs/build/ci-cd.spec.md`.

## Inputs

- A repository newly created from this template
- A repository previously created from this template
- A configured read-only template Git remote
- The new repository owner and repository name from the GitHub Actions context
- Governance files that contain template placeholders, such as `CODEOWNERS`

## Outputs

- Personalized governance files for the new repository
- A dry-run report of planned personalization changes when run without `-Apply`
- Retained lifecycle tooling and specifications after personalization
- A dry-run report of template-only paths that would be updated from the template remote
- An optional upgrade branch containing only allowlisted template infrastructure updates

## Behavior Contract

- `tools/template/bootstrap.ps1` replaces the `@repo-owners` placeholder in `CODEOWNERS` with the new repository owner.
- The bootstrap script is idempotent: re-running it makes no further changes once personalization is applied.
- Without `-Apply`, lifecycle scripts report planned changes and write nothing.
- The bootstrap workflow never runs when GitHub marks the repository as a template; the invoking workflow guards on github.event.repository.is_template rather than a hard-coded repository name.
- Personalization retains `tools/template/`, this spec, and `.github/workflows/template-cleanup.yml` because validation, VS Code tasks, and the generated ownership manifest depend on them.
- `tools/template/update-from-template.ps1` fetches a configured template remote and reports template-only infrastructure changes without writing by default.
- With `-Apply`, `tools/template/update-from-template.ps1` creates or switches to an upgrade branch and restores only allowlisted template-owned paths from the template remote.
- Template update tooling does not restore product-owned specs or personalized files such as `CODEOWNERS`, `README.md`, `SECURITY.md`, or `LICENSE`.

## Acceptance Criteria

- Personalization changes are reported before they are written.
- Re-running bootstrap after personalization reports no changes.
- The CODEOWNERS placeholder is replaced with a concrete owner reference.
- A personalized repository passes spec, traceability, build-system, validator-test, and generated ownership-manifest checks without missing lifecycle artifacts.
- Template-only update dry runs do not modify the working tree.
- Template-only update applies fail when the working tree is dirty unless explicitly allowed.
- Template-only update applies exclude product specs and personalized governance files.
- Bootstrap and template-only update behavior are covered by deterministic validator tests.

## Validation

- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1`
- `powershell -ExecutionPolicy Bypass -File ./tools/template/bootstrap.ps1 -RepositoryOwner example -RepositoryName demo`
- `powershell -ExecutionPolicy Bypass -File ./tools/template/update-from-template.ps1 -SkipFetch`
