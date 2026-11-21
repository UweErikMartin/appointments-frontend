---
applyTo: ".github/workflows/**,.vscode/**,build/**,tools/**,Makefile,justfile,taskfile.yml,Dockerfile*,compose*.yml"
---

# Build-System Instructions

Build and CI/CD files are implementation artifacts of `specs/build/`.

- Read `specs/build/build-system.spec.md` first.
- Read `specs/build/local-dev.spec.md` for local commands.
- Read `specs/build/ci-cd.spec.md` for CI behavior.
- Keep local and CI behavior equivalent where possible.
- Update validators when changing required build behavior.
- Keep `tools/sdd/check-traceability.ps1` wired into local tasks and CI workflows.