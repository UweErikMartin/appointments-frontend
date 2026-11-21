# Template Upgrade Procedure

This procedure lets a repository created from the SDD template adopt later improvements to the template itself.

## Versioning

The template version is recorded in `SDD_TEMPLATE_VERSION`. Compare your repository's value with the latest template release before upgrading, and record the new value in `CHANGELOG.md` after upgrading.

## One-Time Setup

Add the template repository as a read-only Git remote:

```sh
git remote add template https://github.com/UweErikMartin/spec-driven-development.git
git remote set-url --push template DISABLED
```


## Assisted Template-Only Update

Use the helper when you want to inspect or apply only allowlisted template infrastructure paths.

Dry run from a derived repository:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/template/update-from-template.ps1 -TemplateRemote template -TemplateRef main
```

Apply on a dedicated branch:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/template/update-from-template.ps1 -TemplateRemote template -TemplateRef main -Apply
```

The helper restores only template infrastructure paths such as `tools/sdd/`, `build/templates/`, `.github/workflows/`, `.github/prompts/`, `.github/instructions/`, shared build specs, and shared template docs. It deliberately excludes product specs and personalized files such as `CODEOWNERS`, `README.md`, `SECURITY.md`, and `LICENSE`.
## Upgrade Steps

1. Fetch the latest template history:

   ```sh
   git fetch template
   ```

2. Review what changed in template-owned infrastructure since your current version:

   ```sh
   git diff "$(cat SDD_TEMPLATE_VERSION)"..template/main -- tools/ build/ .github/ specs/build/ specs/testing/test-strategy.spec.md
   ```

3. Apply only template-infrastructure changes, not product specs. Prefer cherry-picking focused commits:

   ```sh
   git checkout -b chore/template-upgrade
   git cherry-pick <commit-range>
   ```

   Do not overwrite product specs under `specs/product/`, `specs/architecture/`, or product-specific `specs/operations/` content. Keep your own `CODEOWNERS`, `README.md`, `SECURITY.md`, and `LICENSE`.

4. Resolve conflicts in favor of your product specs for product behavior and in favor of the template for validators, workflows, and spec templates.

5. Update `SDD_TEMPLATE_VERSION` to the adopted template version and add a `CHANGELOG.md` entry.

6. Run the required validation and fix any failures:

   ```sh
   pwsh ./tools/sdd/validate-specs.ps1
   pwsh ./tools/sdd/check-traceability.ps1
   pwsh ./tools/sdd/verify-build-spec.ps1
   pwsh ./tools/sdd/test-validators.ps1
   ```

   On Windows, use `powershell -ExecutionPolicy Bypass -File ...` instead of `pwsh`.

7. Open a pull request that identifies the controlling specs affected by the upgrade and records the template version change.

## What Not To Upgrade

- Product specs that describe your application's behavior.
- Personalized governance files (`CODEOWNERS`, `README.md`, `SECURITY.md`, `LICENSE`).
- Any file your repository has intentionally diverged from the template.
