# Example: New Subcomponent Spec Request

## Request

`/create-feature-spec - add a subcomponent named schedule-cache to scheduler doing cache computed schedules`

## Agent Behavior

The agent should classify this as `subcomponent`, confirm the parent component if it is unclear, search for overlapping specs, and ask before inventing cache invalidation, storage, or error behavior.

## Command

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind subcomponent -Name "schedule-cache" -ParentComponent "scheduler" -Summary "cache computed schedules"
```

## Expected Specs

- `specs/architecture/components/schedule-cache.spec.md`
- `specs/architecture/interfaces/schedule-cache.spec.md`
- `specs/testing/acceptance/schedule-cache.spec.md`