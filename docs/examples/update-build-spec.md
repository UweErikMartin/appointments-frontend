# Example: Build-System Spec Request

## Request

`/update-build-spec - improve the build-system by adding container builds`

## Agent Behavior

The agent should confirm this is build-system work, apply the update-or-create decision, and ask before selecting a container engine, base image, image name, registry, workflow trigger, cache path, or publication target. Because container builds add a new, separately owned build capability, the agent creates a new build spec rather than editing an existing one.

## Command

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/new-spec-set.ps1 -Kind build-system -Name "container-builds" -Summary "add SDD-managed container build behavior"
```

## Expected Specs

- `specs/build/container-builds.spec.md`

Implementation must wait until this draft is refined and marked ready by changing `status: draft` to a non-draft status such as `active`.
