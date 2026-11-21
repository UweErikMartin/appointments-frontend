# Security Policy

## Supported Scope

This template governs repository structure, SDD workflow, validation scripts, and agent-facing instructions. Derived repositories must add product-specific security support windows, threat models, and vulnerability handling rules before shipping production behavior.

## Reporting A Vulnerability

Report suspected vulnerabilities privately to the repository maintainers. Do not disclose exploitable details in public issues or pull requests.

## SDD Security Expectations

- Security-sensitive behavior must have explicit acceptance criteria in a controlling spec before implementation.
- Secrets, credentials, tokens, and private keys must not be committed.
- Dependency, workflow, and generated-file changes must remain traceable to their controlling specs.
- Derived repositories must document product-specific security controls under `specs/architecture/security/`.

## Validation

Run the repository validation commands before requesting review:

```powershell
powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1
powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1
```