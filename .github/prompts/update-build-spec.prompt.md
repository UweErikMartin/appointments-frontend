# Update Build Spec

Use this prompt only for build-system work: local builds, CI/CD, release, toolchain, local development, generated artifacts, containers, and packaging. It governs `specs/build/` and the build-system files those specs own.

This prompt is for build-system behavior only. It must not change product behavior.

## Out Of Scope

Do not use this prompt to create or edit product feature, executable, subcomponent, component, interface, or acceptance specs. Do not edit files under `specs/product/`, `specs/architecture/`, or `specs/testing/`.

If the request is about user-visible product behavior, a new executable's behavior, or a component boundary, stop and route the user to `/create-feature-spec`.

## Update Or Create Decision

- Update an existing `specs/build/` spec in place when the change touches files already owned by `build-system`, `ci-cd`, `local-dev`, `toolchain`, `quality-gates`, or `release`. This is the common case.
- Create a new build spec only when introducing a genuinely new, separately owned build capability with its own owned-path set. Use `tools/sdd/new-spec-set.ps1 -Kind build-system`.
- Never create a new build spec that owns files already owned by an existing `specs/build/` spec.

## Required Workflow

1. Read `AGENTS.md`, `specs/product/requirements/sdd-template-repository.spec.md`, and every existing spec under `specs/build/`.
2. Confirm the request is build-system work. If it is product behavior, stop and tell the user to use `/create-feature-spec`.
3. Identify the controlling build spec by matching the changed files to the `owns` metadata of the existing `specs/build/` specs.
4. Apply the update-or-create decision above.
5. Ask the user for confirmation before selecting tools, file names, commands, container engines, base images, image names, registries, workflow events, cache paths, artifact paths, or release targets that the request did not state.
6. Update the controlling build spec before changing any build script, workflow, task, or generated artifact.
7. Run validation and fix structural issues before reporting completion.

## Command Pattern

To scaffold a new, separately owned build spec:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind build-system -Name "<name>" -Summary "<what build behavior it governs>"
```

For example, `/update-build-spec - improve the build-system by adding container builds`:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind build-system -Name "container-builds" -Summary "add SDD-managed container build behavior"
```

## Confirmation Rules

Ask the user before continuing when:

- It is unclear whether to update an existing build spec or create a new one.
- The requested capability maps onto files already owned by an existing `specs/build/` spec.
- Build tools, container engines, base images, image names, registries, workflow events, artifact paths, release targets, or local command names are not specified.
- The change would affect product behavior. In that case, route to `/create-feature-spec`.
- The request cannot be scoped to one build spec or a single-objective build spec group.

## Required Validation

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1
```

See docs/examples/update-build-spec.md for a build-system request example. See docs/github-branch-protection.md for required GitHub checks. Report the controlling build spec, the created or updated spec paths, any open questions left in draft specs, and the validation results.

