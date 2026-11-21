---
id: build.local-dev
domain: build
status: active
owns:
  - .vscode/tasks.json
  - .vscode/settings.json
  - .vscode/mcp.json
  - .gitignore
  - .editorconfig
  - .githooks/**
  - tools/dev/**
---
# Local Development Spec

## Purpose

Define the local developer workflow for VS Code and command-line usage.

## Scope

This spec controls `.vscode/tasks.json`, developer scripts under `tools/dev/`, and local validation commands.

## Inputs

- Repository checkout
- Windows PowerShell 5 or PowerShell 7 compatible shell
- Git
- VS Code with recommended extensions

## Outputs

- Repeatable local validation
- Local environment diagnostics
- VS Code tasks
- A VS Code task for dry-running template-only update checks
- Consistent editor and line-ending configuration through `.editorconfig` and `.gitignore`
- An optional pre-commit validation hook under `.githooks/`
- Cross-platform Bash launchers (`tools/sdd/*.sh`, `tools/dev/doctor.sh`) for Linux and macOS contributors

## Required Commands

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/dev/doctor.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1
```

## Acceptance Criteria

- A new developer can discover validation tasks through VS Code.
- A developer can dry-run a template-only update from VS Code without modifying the working tree.
- Local validation commands match CI script entry points.
- VS Code tasks launch PowerShell directly as process tasks from `${workspaceFolder}`, using `pwsh` by default on all platforms and `powershell` on Windows for Windows PowerShell compatibility.
- VS Code validation tasks and CI run the same `.ps1` entry points with `-NoProfile -ExecutionPolicy Bypass -File`, without relying on the user's default terminal shell or current directory.
- Environment diagnostics fail with actionable messages.
- Traceability checks can run locally without GitHub-only context.
- Validator tests can run locally without network access.
- Editor configuration enforces UTF-8 and LF line endings.
- A pre-commit hook can run spec and build-system validation before each commit when enabled with `git config core.hooksPath .githooks`.

## Validation

- Run the required commands from the repository root.
