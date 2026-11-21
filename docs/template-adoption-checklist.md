# Template Adoption Checklist

Use this checklist when creating a product repository from this SDD template.

## First 30 Minutes

- Rename the repository and README for the product.
- Replace product-neutral specs with product-specific specs before adding implementation code.
- Confirm `CODEOWNERS` owners (the `template-cleanup` workflow replaces the `@repo-owners` placeholder with the new repository owner on first push).
- Enable the pre-commit hook with `git config core.hooksPath .githooks`.
- Update `SECURITY.md` with product-specific reporting and support expectations.
- Run all required validation commands from the repository root.

## Before First Feature PR

- Add or update the controlling feature, interface, data, testing, and operations specs.
- Ensure each controlling spec has unique metadata and clear owned paths.
- Define measurable acceptance criteria and validation evidence.
- Confirm build, CI, release, and local development behavior are covered by `specs/build/`.

## Before Production Use

- Configure branch protection for required SDD checks.
- Replace placeholder operational specs with product-specific deployment, observability, and rollback behavior.
- Add threat model and dependency policy specs where applicable.
- Document template version adoption in `CHANGELOG.md`.
- Establish a template-upgrade cadence using `docs/template-upgrade.md`.
