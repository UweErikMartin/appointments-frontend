[CmdletBinding()]
param(
    [string]$TemplateRemote = "template",
    [string]$TemplateRef = "main",
    [string]$UpgradeBranch,
    [string[]]$IncludePath = @(
        "tools/sdd",
        "tools/dev",
        "build/templates",
        ".github/workflows",
        ".github/prompts",
        ".github/instructions",
        ".vscode/tasks.json",
        "specs/build",
        "specs/testing/test-strategy.spec.md",
        "docs/examples",
        "docs/github-branch-protection.md",
        "docs/template-upgrade.md"
    ),
    [switch]$Apply,
    [switch]$AllowDirty,
    [switch]$SkipFetch
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repoRoot

function Invoke-Git([string[]]$Arguments) {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = & git @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed:`n$($output | Out-String)"
    }
    return $output
}

function Test-GitRefExists([string]$Ref) {
    & git rev-parse --verify --quiet $Ref *> $null
    return $LASTEXITCODE -eq 0
}


function Test-TemplatePathExists([string]$ResolvedTemplateRef, [string]$Path) {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & git cat-file -e "$ResolvedTemplateRef`:$Path" 2>$null
        return $LASTEXITCODE -eq 0
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}
function Get-ChangedTemplatePaths([string]$ResolvedTemplateRef, [string[]]$Paths) {
    $changes = New-Object System.Collections.Generic.List[string]
    foreach ($path in $Paths) {
        $diff = & git diff --name-status HEAD $ResolvedTemplateRef -- $path 2>$null
        if ($LASTEXITCODE -ne 0) { throw "Unable to diff template path: $path" }
        foreach ($line in $diff) {
            if (-not [string]::IsNullOrWhiteSpace($line)) { $changes.Add($line) }
        }
    }
    return $changes
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required to update from the template remote."
}

Invoke-Git @("rev-parse", "--show-toplevel") | Out-Null

$remoteNames = @(git remote)
if ($remoteNames -notcontains $TemplateRemote) {
    throw "Template remote '$TemplateRemote' is not configured. Add it with: git remote add $TemplateRemote <template-url>"
}

if (-not $SkipFetch) {
    Write-Host "Fetching $TemplateRemote..."
    Invoke-Git @("fetch", $TemplateRemote) | Out-Null
}

$resolvedTemplateRef = "$TemplateRemote/$TemplateRef"
if (-not (Test-GitRefExists $resolvedTemplateRef)) {
    throw "Template ref '$resolvedTemplateRef' does not exist. Check -TemplateRemote and -TemplateRef."
}

Write-Host "Template source: $resolvedTemplateRef"
Write-Host "Mode: $(if ($Apply) { 'apply' } else { 'dry run' })"
Write-Host ""
Write-Host "Allowlisted template-only paths:"
foreach ($path in $IncludePath) { Write-Host " - $path" }
Write-Host ""

$changes = Get-ChangedTemplatePaths $resolvedTemplateRef $IncludePath
if ($changes.Count -eq 0) {
    Write-Host "No allowlisted template-only changes found." -ForegroundColor Green
    exit 0
}

Write-Host "Allowlisted changes from template:"
foreach ($change in $changes) { Write-Host " $change" }

if (-not $Apply) {
    Write-Host ""
    Write-Host "Dry run only. Re-run with -Apply to restore allowlisted paths from $resolvedTemplateRef." -ForegroundColor Yellow
    exit 0
}

if (-not $AllowDirty) {
    $status = git status --porcelain
    if ($status) {
        throw "Working tree is dirty. Commit, stash, or re-run with -AllowDirty after reviewing the risk."
    }
}

if ([string]::IsNullOrWhiteSpace($UpgradeBranch)) {
    $date = Get-Date -Format "yyyyMMdd-HHmmss"
    $UpgradeBranch = "chore/sdd-template-update-$date"
}

$currentBranch = (git branch --show-current).Trim()
if (Test-GitRefExists "refs/heads/$UpgradeBranch") {
    Write-Host "Switching to existing branch $UpgradeBranch"
    Invoke-Git @("switch", $UpgradeBranch) | Out-Null
} else {
    Write-Host "Creating branch $UpgradeBranch from $currentBranch"
    Invoke-Git @("switch", "-c", $UpgradeBranch) | Out-Null
}

foreach ($path in $IncludePath) {
    if (-not (Test-TemplatePathExists $resolvedTemplateRef $path)) {
        Write-Host "Skipping $path because it does not exist in $resolvedTemplateRef"
        continue
    }
    Write-Host "Restoring $path from $resolvedTemplateRef"
    Invoke-Git @("restore", "--source", $resolvedTemplateRef, "--", $path) | Out-Null
}

Write-Host ""
Write-Host "Template-only update paths restored on $UpgradeBranch." -ForegroundColor Green
Write-Host "Review the diff, resolve conflicts if any, update SDD_TEMPLATE_VERSION/CHANGELOG.md when appropriate, then run:"
Write-Host " powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1"
Write-Host " powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1"
Write-Host " powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1"
Write-Host " powershell -ExecutionPolicy Bypass -File ./tools/sdd/test-validators.ps1"