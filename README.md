# SDD Template Repository

This repository is a production-ready template for Spec-Driven Design (SDD) coding. Product code, build behavior, CI/CD behavior, local developer commands, and agent workflows are governed by versioned specifications under `specs/`.

Start here:

- `AGENTS.md` defines the repository operating contract for coding agents.
- `specs/README.md` explains the SDD layout.
- `specs/product/requirements/sdd-template-repository.spec.md` defines the template contract.
- `specs/build/` defines the local and CI build system.
- `docs/template-adoption-checklist.md` defines adoption steps for new product repositories.
- `tools/sdd/validate-specs.ps1` validates required spec structure and metadata.
- `tools/sdd/check-traceability.ps1` validates SDD traceability gates.
- `tools/dev/doctor.ps1` checks the local development environment.

Use this template:

1. Create a new repository from this template.
2. On the first push, the `template-cleanup` workflow personalizes `CODEOWNERS` for the new owner. It retains lifecycle tooling and specs required by validation and future template updates; later runs make no further personalization changes.
3. Replace placeholder specs with product-specific specs before implementation.
4. Keep build, CI, release, and local development changes traceable to `specs/build/`.
5. Run the required validation commands before opening a pull request.

Key repository files:

- `LICENSE` (MIT) and `CONTRIBUTING.md` define usage and contribution terms.
- `.devcontainer/` provides PowerShell and recommended extensions for Linux and macOS contributors.
- `.github/prompts/create-feature-spec.prompt.md` creates product specs only; `.github/prompts/update-build-spec.prompt.md` governs build-system specs only.

Common local commands on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1
powershell -ExecutionPolicy Bypass -File ./tools/dev/doctor.ps1
```

GitHub Actions uses `pwsh` on Ubuntu runners for the same script entry points. On Linux or macOS, run the validators with `pwsh`, for example `pwsh ./tools/sdd/validate-specs.ps1`, or use the Bash launchers, for example `bash ./tools/sdd/validate-specs.sh`.

VS Code tasks run these scripts directly from the workspace root with `-NoProfile -ExecutionPolicy Bypass -File`, using `pwsh` on Linux/macOS and `powershell` on Windows. The default terminal shell does not affect task execution. Install PowerShell 7 (`pwsh`) on Linux/macOS or open the supplied dev container.

To adopt later template improvements, follow `docs/template-upgrade.md`.

Pull requests should identify the controlling spec, summarize spec-to-code traceability, and call out any generated or derived files.
