$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$errors = New-Object System.Collections.Generic.List[string]

$powerShellCommand = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    (Get-Command pwsh).Source
} elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
    (Get-Command powershell).Source
} else {
    throw "PowerShell executable not found. Install PowerShell 7 (pwsh) or Windows PowerShell (powershell)."
}
$powerShellArguments = @("-NoProfile")
$isWindowsHost = -not (Get-Variable IsWindows -ErrorAction SilentlyContinue) -or $IsWindows
if ($isWindowsHost) {
    $powerShellArguments += @("-ExecutionPolicy", "Bypass")
}

function Invoke-PowerShellTestCommand([string]$Command) {
    $previousErrorActionPreference = $ErrorActionPreference
    $previousNativeErrorPreference = $null
    $hasNativeErrorPreference = Test-Path variable:PSNativeCommandUseErrorActionPreference
    if ($hasNativeErrorPreference) {
        $previousNativeErrorPreference = $PSNativeCommandUseErrorActionPreference
    }
    try {
        $ErrorActionPreference = "Continue"
        if ($hasNativeErrorPreference) {
            $global:PSNativeCommandUseErrorActionPreference = $false
        }
        & $powerShellCommand @powerShellArguments -Command $Command 2>&1
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
        if ($hasNativeErrorPreference) {
            $global:PSNativeCommandUseErrorActionPreference = $previousNativeErrorPreference
        }
    }
}
function Invoke-GitTestCommand([string[]]$Arguments) {
    $previousErrorActionPreference = $ErrorActionPreference
    $previousNativeErrorPreference = $null
    $hasNativeErrorPreference = Test-Path variable:PSNativeCommandUseErrorActionPreference
    if ($hasNativeErrorPreference) {
        $previousNativeErrorPreference = $PSNativeCommandUseErrorActionPreference
    }
    try {
        $ErrorActionPreference = "Continue"
        if ($hasNativeErrorPreference) {
            $global:PSNativeCommandUseErrorActionPreference = $false
        }
        $output = & git @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
        if ($hasNativeErrorPreference) {
            $global:PSNativeCommandUseErrorActionPreference = $previousNativeErrorPreference
        }
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed:`n$($output | Out-String)"
    }
    return $output
}

function New-TestRoot {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("sdd-validator-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    return $root
}

function Invoke-ExpectFailure([string]$Name, [scriptblock]$Setup, [string]$CommandTemplate, [string]$ExpectedText) {
    $previousLocation = Get-Location
    $tempRoot = New-TestRoot
    try {
        & $Setup $tempRoot
        $command = $CommandTemplate.Replace("__ROOT__", $tempRoot.Replace("'", "''"))
        $output = Invoke-PowerShellTestCommand $command
        $exitCode = $LASTEXITCODE
        $text = ($output | Out-String)
        if ($exitCode -eq 0) { $errors.Add("$Name expected failure but passed") }
        elseif ($text -notmatch [regex]::Escape($ExpectedText)) { $errors.Add("$Name failed without expected text '$ExpectedText'. Output: $text") }
    } finally {
        Set-Location $previousLocation
        if (Test-Path $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
    }
}

function Invoke-ExpectSuccess([string]$Name, [scriptblock]$Setup, [string]$CommandTemplate) {
    $previousLocation = Get-Location
    $tempRoot = New-TestRoot
    try {
        & $Setup $tempRoot
        $command = $CommandTemplate.Replace("__ROOT__", $tempRoot.Replace("'", "''"))
        $output = Invoke-PowerShellTestCommand $command
        $exitCode = $LASTEXITCODE
        $text = ($output | Out-String)
        if ($exitCode -ne 0) { $errors.Add("$Name expected success but failed. Output: $text") }
    } finally {
        Set-Location $previousLocation
        if (Test-Path $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
    }
}

function Invoke-ExpectSuccessWithAssertion([string]$Name, [scriptblock]$Setup, [scriptblock]$Assert) {
    $previousLocation = Get-Location
    $tempRoot = New-TestRoot
    try {
        & $Setup $tempRoot
        & $Assert $tempRoot
    } catch {
        $errors.Add("$Name failed: $($_.Exception.Message)")
    } finally {
        Set-Location $previousLocation
        if (Test-Path $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
    }
}

function Copy-SddScripts([string]$TempRoot) {
    New-Item -ItemType Directory -Force -Path (Join-Path $TempRoot "tools/sdd") | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "tools/sdd/validate-specs.ps1") -Destination (Join-Path $TempRoot "tools/sdd/validate-specs.ps1")
    Copy-Item -LiteralPath (Join-Path $repoRoot "tools/sdd/check-traceability.ps1") -Destination (Join-Path $TempRoot "tools/sdd/check-traceability.ps1")
}

function Copy-TemplateScripts([string]$TempRoot) {
    New-Item -ItemType Directory -Force -Path (Join-Path $TempRoot "tools/template") | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "tools/template/bootstrap.ps1") -Destination (Join-Path $TempRoot "tools/template/bootstrap.ps1")
    Copy-Item -LiteralPath (Join-Path $repoRoot "tools/template/update-from-template.ps1") -Destination (Join-Path $TempRoot "tools/template/update-from-template.ps1")
}

function Write-TestFile([string]$Root, [string]$Path, [string]$Content) {
    $target = Join-Path $Root $Path
    New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($target, ($Content -replace "`r`n", "`n"), $utf8)
}

function Copy-ValidationFixture([string]$Root) {
    foreach ($directory in @(".github", ".vscode", "specs", "tools", "build", "artifacts", "docs")) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $directory) -Destination $Root -Recurse
    }
    Get-ChildItem -LiteralPath $repoRoot -File -Force | Copy-Item -Destination $Root
}

function New-SpecContent([string]$Id, [string]$Domain, [string]$Status, [string[]]$Owns) {
    $ownsText = ($Owns | ForEach-Object { "  - $_" }) -join "`n"
    return @"
---
id: $Id
domain: $Domain
status: $Status
owns:
$ownsText
---
# $Id

## Purpose

Test purpose.

## Scope

Test scope.

## Inputs

- Test input

## Outputs

- Test output

## Acceptance Criteria

- Test criterion.

## Validation

- Test validation.
"@
}

function Add-MinimalRequiredFiles([string]$Root) {
    foreach ($path in @("AGENTS.md", ".github/copilot-instructions.md", ".github/pull_request_template.md", "CODEOWNERS", "SECURITY.md", "specs/README.md", "specs/product/requirements/sdd-template-repository.spec.md", "specs/build/build-system.spec.md", "specs/build/local-dev.spec.md", "specs/build/ci-cd.spec.md", "specs/build/toolchain.spec.md", "specs/build/quality-gates.spec.md", "specs/testing/test-strategy.spec.md", "specs/architecture/system-context.md")) {
        Write-TestFile $Root $path "placeholder"
    }
}

function Add-ValidSpecSet([string]$Root) {
    Copy-SddScripts $Root
    foreach ($path in @("AGENTS.md", ".github/copilot-instructions.md", ".github/pull_request_template.md", "SECURITY.md", "specs/README.md")) {
        Write-TestFile $Root $path "placeholder"
    }
    Write-TestFile $Root "CODEOWNERS" "* @repo-owners"
    Write-TestFile $Root "specs/product/requirements/sdd-template-repository.spec.md" (New-SpecContent "product.requirements.template" "product" "active" @("README.md"))
    Write-TestFile $Root "specs/build/build-system.spec.md" (New-SpecContent "build.build-system" "build" "active" @("tools/sdd/**"))
    Write-TestFile $Root "specs/build/local-dev.spec.md" (New-SpecContent "build.local-dev" "build" "active" @(".vscode/tasks.json"))
    Write-TestFile $Root "specs/build/ci-cd.spec.md" (New-SpecContent "build.ci-cd" "build" "active" @(".github/workflows/**"))
    Write-TestFile $Root "specs/build/toolchain.spec.md" (New-SpecContent "build.toolchain" "build" "active" @(".vscode/extensions.json"))
    Write-TestFile $Root "specs/build/quality-gates.spec.md" (New-SpecContent "build.quality-gates" "build" "active" @("CODEOWNERS"))
    Write-TestFile $Root "specs/testing/test-strategy.spec.md" (New-SpecContent "testing.test-strategy" "testing" "active" @("specs/testing/test-strategy.spec.md"))
    Write-TestFile $Root "specs/architecture/system-context.md" (New-SpecContent "architecture.system-context" "architecture" "active" @("specs/architecture/system-context.md"))
}

Invoke-ExpectSuccess "valid spec set passes validation" { param($root) Add-ValidSpecSet $root } "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1"

Invoke-ExpectSuccess "personalized CODEOWNERS passes traceability" {
    param($root)
    Copy-SddScripts $root
    foreach ($path in @(".github/pull_request_template.md", "AGENTS.md", "SECURITY.md")) {
        Write-TestFile $root $path "Controlling Spec`nBuild-system impact`ncheck-traceability.ps1`nGenerated or derived files`nDefinition Of Ready`nDefinition Of Done`nReporting A Vulnerability`nSDD Security Expectations"
    }
    Write-TestFile $root "CODEOWNERS" "* @product-team"
    Write-TestFile $root "specs/product/features/demo.spec.md" (New-SpecContent "product.features.demo" "product" "active" @("specs/product/features/demo.spec.md"))
} "Set-Location '__ROOT__'; ./tools/sdd/check-traceability.ps1"

Invoke-ExpectSuccessWithAssertion "bootstrap dry-run apply and idempotence" {
    param($root)
    Copy-TemplateScripts $root
    Write-TestFile $root "CODEOWNERS" "* @repo-owners`n"
} {
    param($root)
    Set-Location $root
    ./tools/template/bootstrap.ps1 -RepositoryOwner product-team -RepositoryName demo | Out-Null
    $dryRunContent = Get-Content (Join-Path $root "CODEOWNERS") -Raw
    if ($dryRunContent -notmatch "@repo-owners") { throw "bootstrap dry run modified CODEOWNERS" }
    ./tools/template/bootstrap.ps1 -RepositoryOwner product-team -RepositoryName demo -Apply | Out-Null
    $appliedContent = Get-Content (Join-Path $root "CODEOWNERS") -Raw
    if ($appliedContent -notmatch "@product-team") { throw "bootstrap apply did not personalize CODEOWNERS" }
    ./tools/template/bootstrap.ps1 -RepositoryOwner product-team -RepositoryName demo -Apply | Out-Null
    $againContent = Get-Content (Join-Path $root "CODEOWNERS") -Raw
    if ($againContent -ne $appliedContent) { throw "bootstrap is not idempotent" }
}

Invoke-ExpectSuccess "personalized template preserves validation and local task dependencies" {
    param($root)
    Copy-ValidationFixture $root
} @"
Set-Location '__ROOT__'
./tools/template/bootstrap.ps1 -RepositoryOwner product-team -RepositoryName demo -Apply
if (-not `$?) { exit 1 }
./tools/sdd/validate-specs.ps1
if (-not `$?) { exit 1 }
./tools/sdd/check-traceability.ps1
if (-not `$?) { exit 1 }
./tools/sdd/verify-build-spec.ps1
if (-not `$?) { exit 1 }
./tools/sdd/generate-build-files.ps1 -Check
exit `$LASTEXITCODE
"@

Invoke-ExpectFailure "VS Code tasks reject terminal-shell execution" {
    param($root)
    Copy-ValidationFixture $root
    $tasks = Get-Content (Join-Path $root ".vscode/tasks.json") -Raw | ConvertFrom-Json
    $tasks.tasks[0].type = "shell"
    Write-TestFile $root ".vscode/tasks.json" ($tasks | ConvertTo-Json -Depth 10)
} "Set-Location '__ROOT__'; ./tools/sdd/verify-build-spec.ps1" "must use process execution"

Invoke-ExpectFailure "workflows reject non-PowerShell run steps" {
    param($root)
    Copy-ValidationFixture $root
    $workflow = (Get-Content (Join-Path $root ".github/workflows/ci.yml") -Raw).Replace("shell: pwsh", "shell: bash")
    Write-TestFile $root ".github/workflows/ci.yml" $workflow
} "Set-Location '__ROOT__'; ./tools/sdd/verify-build-spec.ps1" "must use shell: pwsh"

Invoke-ExpectFailure "template cleanup rejects removal of validation dependencies" {
    param($root)
    Copy-ValidationFixture $root
    $workflow = Get-Content (Join-Path $root ".github/workflows/template-cleanup.yml") -Raw
    $workflow += "`n      - name: Remove lifecycle tooling`n        shell: pwsh`n        run: |`n          Remove-Item ./tools/template -Recurse -Force`n"
    Write-TestFile $root ".github/workflows/template-cleanup.yml" $workflow
} "Set-Location '__ROOT__'; ./tools/sdd/verify-build-spec.ps1" "must retain lifecycle artifacts"

Invoke-ExpectSuccessWithAssertion "template update dry-run and apply" {
    param($root)
    $derivedRoot = Join-Path $root "derived"
    New-Item -ItemType Directory -Force -Path $derivedRoot | Out-Null
    Set-Location $derivedRoot
    Invoke-GitTestCommand @("init", "--initial-branch=main", "--quiet") | Out-Null
    Invoke-GitTestCommand @("config", "user.email", "sdd@example.invalid") | Out-Null
    Invoke-GitTestCommand @("config", "user.name", "SDD Test") | Out-Null
    Invoke-GitTestCommand @("config", "core.autocrlf", "false") | Out-Null

    Copy-TemplateScripts $derivedRoot
    Write-TestFile $derivedRoot "tools/sdd/example.txt" "template-new`n"
    Write-TestFile $derivedRoot "README.md" "template-readme`n"
    Invoke-GitTestCommand @("add", ".") | Out-Null
    Invoke-GitTestCommand @("commit", "-m", "template") | Out-Null
    $templateSha = ((Invoke-GitTestCommand @("rev-parse", "HEAD")) | Out-String).Trim()
    Invoke-GitTestCommand @("branch", "-M", "template-base") | Out-Null
    Invoke-GitTestCommand @("update-ref", "refs/remotes/template/main", $templateSha) | Out-Null

    Invoke-GitTestCommand @("switch", "--quiet", "--orphan", "main") | Out-Null
    Get-ChildItem -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
    Copy-TemplateScripts $derivedRoot
    Write-TestFile $derivedRoot "tools/sdd/example.txt" "derived-old`n"
    Write-TestFile $derivedRoot "README.md" "derived-readme`n"
    Invoke-GitTestCommand @("add", ".") | Out-Null
    Invoke-GitTestCommand @("commit", "-m", "derived") | Out-Null
    Invoke-GitTestCommand @("remote", "add", "template", ".") | Out-Null
} {
    param($root)
    $derivedRoot = Join-Path $root "derived"
    Set-Location $derivedRoot
    ./tools/template/update-from-template.ps1 -TemplateRemote template -TemplateRef main -SkipFetch | Out-Null
    $dryRunTool = Get-Content (Join-Path $derivedRoot "tools/sdd/example.txt") -Raw
    if ($dryRunTool -notmatch "derived-old") { throw "template update dry run modified allowlisted file" }
    ./tools/template/update-from-template.ps1 -TemplateRemote template -TemplateRef main -SkipFetch -Apply -UpgradeBranch chore/test-template-update | Out-Null
    $updatedTool = Get-Content (Join-Path $derivedRoot "tools/sdd/example.txt") -Raw
    if ($updatedTool -notmatch "template-new") { throw "template update apply did not restore allowlisted file" }
    $readme = Get-Content (Join-Path $derivedRoot "README.md") -Raw
    if ($readme -notmatch "derived-readme") { throw "template update apply modified personalized README" }
}

Invoke-ExpectFailure "missing required section" {
    param($root)
    Add-ValidSpecSet $root
    $missingSection = (New-SpecContent "product.features.broken" "product" "active" @("specs/product/features/broken.spec.md")) -replace "(?s)## Validation.*$", ""
    Write-TestFile $root "specs/product/features/broken.spec.md" $missingSection
} "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1" "Missing section '## Validation'"

Invoke-ExpectFailure "duplicate spec id" {
    param($root)
    Add-ValidSpecSet $root
    Write-TestFile $root "specs/product/features/duplicate.spec.md" (New-SpecContent "build.build-system" "product" "active" @("specs/product/features/duplicate.spec.md"))
} "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1" "Duplicate spec id"

Invoke-ExpectFailure "unsupported metadata domain" {
    param($root)
    Add-ValidSpecSet $root
    Write-TestFile $root "specs/product/features/baddomain.spec.md" (New-SpecContent "product.features.baddomain" "marketing" "active" @("specs/product/features/baddomain.spec.md"))
} "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1" "Unsupported metadata domain"

Invoke-ExpectFailure "duplicate owned path" {
    param($root)
    Add-ValidSpecSet $root
    Write-TestFile $root "specs/product/features/dupowner.spec.md" (New-SpecContent "product.features.dupowner" "product" "active" @("tools/sdd/**"))
} "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1" "Duplicate owned path"

Invoke-ExpectFailure "missing front matter" {
    param($root)
    Add-ValidSpecSet $root
    Write-TestFile $root "specs/product/features/nometa.spec.md" "# No Front Matter`n`n## Purpose`n`nx`n`n## Scope`n`nx`n`n## Inputs`n`n- x`n`n## Outputs`n`n- x`n`n## Acceptance Criteria`n`n- x`n`n## Validation`n`n- x`n"
} "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1" "Missing metadata front matter"

Invoke-ExpectFailure "placeholder text remains" {
    param($root)
    Add-ValidSpecSet $root
    $withPlaceholder = (New-SpecContent "product.features.placeholder" "product" "active" @("specs/product/features/placeholder.spec.md")) -replace "Test purpose\.", "To be refined as the system evolves"
    Write-TestFile $root "specs/product/features/placeholder.spec.md" $withPlaceholder
} "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1" "Placeholder text remains"

Invoke-ExpectFailure "wildcard ownership overlap" {
    param($root)
    Copy-SddScripts $root
    Add-MinimalRequiredFiles $root
    Write-TestFile $root "specs/product/features/parent.spec.md" (New-SpecContent "product.features.parent" "product" "active" @("src/**"))
    Write-TestFile $root "specs/product/features/child.spec.md" (New-SpecContent "product.features.child" "product" "active" @("src/child/file.txt"))
} "Set-Location '__ROOT__'; ./tools/sdd/validate-specs.ps1" "Overlapping owned paths"

Invoke-ExpectFailure "draft implementation guard" {
    param($root)
    Copy-SddScripts $root
    foreach ($path in @(".github/pull_request_template.md", "AGENTS.md", "SECURITY.md", "CODEOWNERS")) {
        Write-TestFile $root $path "Controlling Spec`nBuild-system impact`ncheck-traceability.ps1`nGenerated or derived files`nDefinition Of Ready`nDefinition Of Done`nReporting A Vulnerability`nSDD Security Expectations`n* @repo-owners"
    }
    Write-TestFile $root "specs/product/features/demo.spec.md" (New-SpecContent "product.features.demo" "product" "active" @("specs/product/features/demo.spec.md"))
    Set-Location $root
    Invoke-GitTestCommand @("init", "--initial-branch=main", "--quiet") | Out-Null
    Invoke-GitTestCommand @("config", "user.email", "sdd@example.invalid") | Out-Null
    Invoke-GitTestCommand @("config", "user.name", "SDD Test") | Out-Null
    Invoke-GitTestCommand @("config", "core.autocrlf", "false") | Out-Null
    Invoke-GitTestCommand @("add", ".") | Out-Null
    Invoke-GitTestCommand @("commit", "-m", "base") | Out-Null
    Write-TestFile $root "specs/product/features/demo.spec.md" (New-SpecContent "product.features.demo" "product" "draft" @("specs/product/features/demo.spec.md"))
    Write-TestFile $root "src/demo.txt" "implementation"
    Invoke-GitTestCommand @("add", ".") | Out-Null
    Invoke-GitTestCommand @("commit", "-m", "draft implementation") | Out-Null
} "Set-Location '__ROOT__'; ./tools/sdd/check-traceability.ps1 -BaseRef HEAD~1" "controlling specs are still draft"

if ($errors.Count -gt 0) {
    Write-Host "Validator tests failed:" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host " - $e" -ForegroundColor Red }
    exit 1
}
Write-Host "Validator tests passed." -ForegroundColor Green
exit 0
