# Create Feature Spec

Use this prompt only to create product feature specifications: a `feature`, an `executable`, or a `subcomponent`. The goal is to create draft SDD specs from repository templates, not to invent implementation details.

This prompt is for product behavior only. It must not change build-system behavior.

## Out Of Scope

Do not use this prompt for build, CI/CD, release, toolchain, local development, generated artifacts, containers, or packaging changes. Do not edit build scripts, GitHub Actions workflows, `.vscode/` tasks, `tools/`, `build/`, or any file owned by a `specs/build/` spec.

If the request is about build-system behavior, stop and route the user to `/update-build-spec`.

## Required Workflow

1. Read `AGENTS.md`, `specs/product/requirements/sdd-template-repository.spec.md`, and the relevant existing specs under `specs/`.
2. Classify the request as one of:
   - `feature`: user-visible behavior without a new executable or component boundary.
   - `executable`: a new command, binary, script entry point, CLI, service executable, or named runnable artifact.
   - `subcomponent`: a new internal component or subcomponent boundary.
3. If the request is about build, CI/CD, release, toolchain, local development, artifacts, containers, or packaging, stop and tell the user to use `/update-build-spec`.
4. If the classification, name, parent component, interface boundary, or observable behavior is unclear, ask the user for confirmation before creating files.
5. Search existing specs for conflicting names, overlapping ownership, or duplicate behavior. If a conflict exists, stop and ask the user whether to update the existing spec or create a new one.
6. Create specs by copying from `build/templates/specs/` through `tools/sdd/new-spec-set.ps1`; do not hand-author a new structure from scratch.
7. Replace generated draft content only with facts from the user request or existing specs. Keep unknown details explicit and ask before continuing to implementation.
8. Run validation and fix structural issues before reporting completion.

## Command Patterns

For a simple feature:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind feature -Name "<name>" -Summary "<what it shall do>"
```

For a request like `/create-feature-spec - create a new executable named xxx doing xxx`:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind executable -Name "xxx" -Summary "xxx does ..."
```

For a request like `/create-feature-spec - add a subcomponent named xxx to yyy doing xxx`:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind subcomponent -Name "xxx" -ParentComponent "yyy" -Summary "xxx does ..."
```

## Generated Spec Sets

- `feature` creates a product feature spec and an acceptance spec.
- `executable` creates a product feature spec, architecture component spec, CLI interface spec, and acceptance spec.
- `subcomponent` creates an architecture component spec, interface spec, and acceptance spec.

## Confirmation Rules

Ask the user before continuing when:

- More than one feature spec type could apply.
- The requested name is already used by an existing spec or owned path.
- A parent component is implied but not named.
- Inputs, outputs, command names, protocol names, persistence, security behavior, or error behavior are not specified.
- The request would change build, CI, release, local development, or generated-file behavior. In that case, route to `/update-build-spec`.
- The request cannot be scoped to one spec or a single-objective spec group.

## Required Validation

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1
```

See docs/examples/ for executable and subcomponent request examples. See docs/github-branch-protection.md for required GitHub checks. Report the created spec paths, any open questions left in the draft specs, and the validation results.
