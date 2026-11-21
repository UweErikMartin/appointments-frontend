$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$errors = New-Object System.Collections.Generic.List[string]
$expectedReferences = @{
    ".github/workflows/ci.yml" = @("tools/sdd/validate-specs.ps1", "tools/sdd/check-traceability.ps1", "tools/sdd/verify-build-spec.ps1", "tools/sdd/test-validators.ps1", "tools/sdd/generate-build-files.ps1 -Check")
    ".github/workflows/spec-validation.yml" = @("tools/sdd/validate-specs.ps1", "tools/sdd/check-traceability.ps1", "tools/sdd/test-validators.ps1", "tools/sdd/generate-build-files.ps1 -Check")
    ".github/workflows/build-system-validation.yml" = @("tools/sdd/validate-specs.ps1", "tools/sdd/verify-build-spec.ps1", "tools/sdd/test-validators.ps1", "tools/sdd/generate-build-files.ps1 -Check")
    ".vscode/tasks.json" = @("tools/sdd/validate-specs.ps1", "tools/sdd/check-traceability.ps1", "tools/sdd/verify-build-spec.ps1", "tools/sdd/test-validators.ps1", "tools/template/update-from-template.ps1")
}
foreach ($entry in $expectedReferences.GetEnumerator()) {
    $path = Join-Path $repoRoot $entry.Key
    if (-not (Test-Path $path)) { $errors.Add("Missing build artifact: $($entry.Key)"); continue }
    $content = Get-Content $path -Raw
    foreach ($expected in $entry.Value) {
        if ($content -notmatch [regex]::Escape($expected)) { $errors.Add("Expected $($entry.Key) to reference $expected") }
    }
}

$tasksPath = Join-Path $repoRoot ".vscode/tasks.json"
if (Test-Path $tasksPath) {
    $taskConfiguration = Get-Content $tasksPath -Raw | ConvertFrom-Json
    foreach ($task in $taskConfiguration.tasks) {
        if ($task.type -ne "process" -or $task.command -ne "pwsh" -or $task.windows.command -ne "powershell") {
            $errors.Add("VS Code task '$($task.label)' must use process execution with pwsh and a Windows powershell override")
        }
        if ($task.options.cwd -ne '${workspaceFolder}') {
            $errors.Add("VS Code task '$($task.label)' must run from the workspace root")
        }
        if ($task.args.Count -ne 5 -or ($task.args[0..3] -join " ") -ne "-NoProfile -ExecutionPolicy Bypass -File") {
            $errors.Add("VS Code task '$($task.label)' must use -NoProfile -ExecutionPolicy Bypass -File followed by a script path")
        } elseif (-not (Test-Path (Join-Path $repoRoot $task.args[4]) -PathType Leaf)) {
            $errors.Add("VS Code task '$($task.label)' references a missing script: $($task.args[4])")
        }
    }
}

foreach ($workflow in Get-ChildItem (Join-Path $repoRoot ".github/workflows") -File -Filter "*.yml") {
    $content = Get-Content $workflow.FullName -Raw
    foreach ($step in [regex]::Matches($content, "(?ms)^      - .*?(?=^      - |\z)")) {
        if ($step.Value -notmatch "(?m)^\s+run:") { continue }
        if ($step.Value -notmatch "(?m)^\s+shell: pwsh\s*$") {
            $errors.Add("Workflow $($workflow.Name) run steps must use shell: pwsh")
        }
        foreach ($scriptRun in [regex]::Matches($step.Value, "(?m)^\s+run:\s+(?<command>.+\.ps1.*)$")) {
            if ($scriptRun.Groups["command"].Value -notmatch "^pwsh -NoProfile -ExecutionPolicy Bypass -File ") {
                $errors.Add("Workflow $($workflow.Name) must invoke scripts with pwsh -NoProfile -ExecutionPolicy Bypass -File")
            }
        }
    }
    if ($workflow.Name -eq "build-system-validation.yml" -and
        $content.IndexOf("run: pwsh -NoProfile -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1") -gt
        $content.IndexOf("run: pwsh -NoProfile -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1")) {
        $errors.Add("Build-system workflow must validate specs before implementation checks")
    }
}

$bashLaunchers = [ordered]@{
    "tools/sdd/validate-specs.sh"       = "validate-specs.ps1"
    "tools/sdd/check-traceability.sh"   = "check-traceability.ps1"
    "tools/sdd/verify-build-spec.sh"    = "verify-build-spec.ps1"
    "tools/sdd/test-validators.sh"      = "test-validators.ps1"
    "tools/sdd/generate-build-files.sh" = "generate-build-files.ps1"
    "tools/dev/doctor.sh"               = "doctor.ps1"
}
foreach ($entry in $bashLaunchers.GetEnumerator()) {
    $path = Join-Path $repoRoot $entry.Key
    if (-not (Test-Path $path)) { $errors.Add("Missing Bash launcher: $($entry.Key)"); continue }
    $content = Get-Content $path -Raw
    if ($content -notmatch [regex]::Escape($entry.Value)) { $errors.Add("Bash launcher $($entry.Key) must delegate to $($entry.Value)") }
}

foreach ($required in @(".github/pull_request_template.md", ".github/prompts/create-feature-spec.prompt.md", ".github/prompts/update-build-spec.prompt.md", "CODEOWNERS", "SECURITY.md", "SDD_TEMPLATE_VERSION", "CHANGELOG.md", "docs/template-adoption-checklist.md", "docs/template-upgrade.md", "tools/template/update-from-template.ps1", "docs/github-branch-protection.md", "docs/examples/create-feature-spec-executable.md", "docs/examples/create-feature-spec-subcomponent.md", "docs/examples/update-build-spec.md", "tools/sdd/new-spec-set.ps1", "tools/sdd/test-validators.ps1", "build/templates/specs/feature.spec.md.template", "build/templates/specs/component.spec.md.template", "build/templates/specs/interface.spec.md.template", "build/templates/specs/acceptance.spec.md.template", "build/templates/specs/build-system.spec.md.template")) {
    if (-not (Test-Path (Join-Path $repoRoot $required))) { $errors.Add("Missing required governance artifact: $required") }
}

$ciSpec = Get-Content (Join-Path $repoRoot "specs/build/ci-cd.spec.md") -Raw
foreach ($workflow in @(".github/workflows/spec-validation.yml", ".github/workflows/build-system-validation.yml", ".github/workflows/ci.yml")) {
    if ($ciSpec -notmatch [regex]::Escape($workflow)) { $errors.Add("CI/CD spec does not document $workflow") }
}
foreach ($job in @("Validate specs", "Check SDD traceability", "Verify build-system traceability", "Test SDD validators", "Check generated ownership manifest")) {
    if ($ciSpec -notmatch [regex]::Escape($job)) { $errors.Add("CI/CD spec does not document job: $job") }
}

$localDevSpec = Get-Content (Join-Path $repoRoot "specs/build/local-dev.spec.md") -Raw
foreach ($command in @("tools/dev/doctor.ps1", "tools/sdd/validate-specs.ps1", "tools/sdd/check-traceability.ps1", "tools/sdd/verify-build-spec.ps1", "tools/sdd/test-validators.ps1")) {
    if ($localDevSpec -notmatch [regex]::Escape($command)) { $errors.Add("Local development spec does not document $command") }
}

$buildSpec = Get-Content (Join-Path $repoRoot "specs/build/build-system.spec.md") -Raw
foreach ($command in @("tools/sdd/check-traceability.ps1", "tools/sdd/verify-build-spec.ps1", "tools/sdd/new-spec-set.ps1", "tools/sdd/test-validators.ps1", "build/templates/specs/")) {
    if ($buildSpec -notmatch [regex]::Escape($command)) { $errors.Add("Build-system spec does not document $command") }
}


$createPrompt = Get-Content (Join-Path $repoRoot ".github/prompts/create-feature-spec.prompt.md") -Raw
foreach ($requiredText in @("tools/sdd/new-spec-set.ps1", "tools/sdd/test-validators.ps1", "build/templates/specs/", "Ask the user", "subcomponent", "executable", "docs/examples/", "docs/github-branch-protection.md", "/update-build-spec")) {
    if ($createPrompt -notmatch [regex]::Escape($requiredText)) { $errors.Add("Create feature spec prompt does not document: $requiredText") }
}
if ($createPrompt -match [regex]::Escape('-Kind build-system')) { $errors.Add("Create feature spec prompt must not scaffold build-system specs; route them to /update-build-spec") }

$updatePrompt = Get-Content (Join-Path $repoRoot ".github/prompts/update-build-spec.prompt.md") -Raw
foreach ($requiredText in @("tools/sdd/new-spec-set.ps1", "-Kind build-system", "specs/build/", "tools/sdd/validate-specs.ps1", "tools/sdd/verify-build-spec.ps1", "containers", "docs/examples/update-build-spec.md", "docs/github-branch-protection.md", "/create-feature-spec")) {
    if ($updatePrompt -notmatch [regex]::Escape($requiredText)) { $errors.Add("Update build spec prompt does not document: $requiredText") }
}

$templateLifecycleSpec = Get-Content (Join-Path $repoRoot "specs/build/template-lifecycle.spec.md") -Raw
foreach ($requiredText in @("tools/template/update-from-template.ps1", "template-only", "-Apply", "CODEOWNERS", "README.md", "SECURITY.md", "LICENSE", "github.event.repository.is_template")) {
    if ($templateLifecycleSpec -notmatch [regex]::Escape($requiredText)) { $errors.Add("Template lifecycle spec does not document: $requiredText") }
}

$templateUpgradeDoc = Get-Content (Join-Path $repoRoot "docs/template-upgrade.md") -Raw
foreach ($requiredText in @("tools/template/update-from-template.ps1", "-Apply", "CODEOWNERS", "README.md", "SECURITY.md", "LICENSE")) {
    if ($templateUpgradeDoc -notmatch [regex]::Escape($requiredText)) { $errors.Add("Template upgrade docs do not document: $requiredText") }
}

$templateCleanupWorkflow = Get-Content (Join-Path $repoRoot ".github/workflows/template-cleanup.yml") -Raw
foreach ($requiredText in @("github.event.repository.is_template == false", "tools/template/bootstrap.ps1", "contents: write")) {
    if ($templateCleanupWorkflow -notmatch [regex]::Escape($requiredText)) { $errors.Add("Template cleanup workflow does not document: $requiredText") }
}
if ($templateCleanupWorkflow -match "(?im)^\s*Remove-Item\b") {
    $errors.Add("Template cleanup must retain lifecycle artifacts required by validation and local tasks")
}
if ($templateCleanupWorkflow -match [regex]::Escape("UweErikMartin/spec-driven-development")) {
    $errors.Add("Template cleanup workflow must not hard-code the template repository identity")
}
if ($errors.Count -gt 0) {
    Write-Host "Build-system verification failed:" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host " - $e" -ForegroundColor Red }
    exit 1
}
Write-Host "Build-system verification passed." -ForegroundColor Green
