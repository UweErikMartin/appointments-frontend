# Example: New Executable Spec Request

## Request

`/create-feature-spec - create a new executable named report-export doing export validated reports as JSON`

## Agent Behavior

The agent should classify this as `executable`, search for existing `report-export` specs, and ask before choosing command arguments, output file names, exit codes, or persistence behavior that the request did not state.

## Command

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind executable -Name "report-export" -Summary "export validated reports as JSON"
```

## Expected Specs

- `specs/product/features/report-export.spec.md`
- `specs/architecture/components/report-export.spec.md`
- `specs/architecture/interfaces/report-export-cli.spec.md`
- `specs/testing/acceptance/report-export.spec.md`