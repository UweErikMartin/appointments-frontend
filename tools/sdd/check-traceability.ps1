param(
    [string]$BaseRef = $env:GITHUB_BASE_REF
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$errors = New-Object System.Collections.Generic.List[string]

function Test-TextContains([string]$RelativePath, [string[]]$RequiredText) {
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path $path)) { $errors.Add("Missing required traceability artifact: $RelativePath"); return }
    $content = Get-Content $path -Raw
    foreach ($text in $RequiredText) {
        if ($content -notmatch [regex]::Escape($text)) { $errors.Add("$RelativePath must reference '$text'") }
    }
}

Test-TextContains ".github/pull_request_template.md" @("Controlling Spec", "Build-system impact", "check-traceability.ps1", "Generated or derived files")
Test-TextContains "AGENTS.md" @("Definition Of Ready", "Definition Of Done", "check-traceability.ps1")
Test-TextContains "SECURITY.md" @("Reporting A Vulnerability", "SDD Security Expectations")

$codeownersPath = Join-Path $repoRoot "CODEOWNERS"
if (-not (Test-Path $codeownersPath)) {
    $errors.Add("Missing required traceability artifact: CODEOWNERS")
} elseif (-not ((Get-Content $codeownersPath) | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "@" })) {
    $errors.Add("CODEOWNERS must define at least one owner reference")
}

$specFiles = Get-ChildItem (Join-Path $repoRoot "specs") -Recurse -File -Include "*.spec.md", "vision.md", "system-context.md", "security-overview.md"
$ownedPatterns = New-Object System.Collections.Generic.List[string]
foreach ($spec in $specFiles) {
    $content = Get-Content $spec.FullName -Raw
    if ($content -match "(?s)^---\n(?<meta>.*?)\n---\n") {
        $meta = $Matches.meta
        $ownsMatch = [regex]::Match($meta, "(?ms)^owns:\s*\n(?<items>(?:\s+-\s+.+\n?)+)")
        if ($ownsMatch.Success) {
            foreach ($line in ($ownsMatch.Groups["items"].Value -split "\n")) {
                if ($line -match "^\s+-\s+(?<path>.+?)\s*$") { $ownedPatterns.Add($Matches.path.Trim().Replace("\", "/")) }
            }
        }
    }
}

if ($ownedPatterns.Count -eq 0) { $errors.Add("No spec ownership metadata found") }

if (-not [string]::IsNullOrWhiteSpace($BaseRef) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $base = $BaseRef
    if ($base -notmatch "^(origin/|HEAD|[0-9a-f]{7,40}$)") { $base = "origin/$base" }
    $changed = @()
    try { $changed = git diff --name-only "$base...HEAD" 2>$null } catch { $changed = @() }
    if ($changed.Count -gt 0) {
        $specChanged = $changed | Where-Object { $_ -like "specs/*" }
        $implementationChanged = $changed | Where-Object {
            $_ -notlike "specs/*" -and
            $_ -notlike "*.md" -and
            $_ -ne "SDD_TEMPLATE_VERSION" -and
            $_ -ne "CHANGELOG.md"
        }
        if ($implementationChanged.Count -gt 0 -and $specChanged.Count -eq 0) {
            $errors.Add("Implementation/build files changed without a specs/ change in this comparison range")
        }

        $draftSpecChanged = @()
        foreach ($specPath in $specChanged) {
            $absoluteSpecPath = Join-Path $repoRoot $specPath
            if (Test-Path $absoluteSpecPath) {
                $specContent = Get-Content $absoluteSpecPath -Raw
                if ($specContent -match "(?m)^status:\s*draft\s*$") { $draftSpecChanged += $specPath }
            }
        }
        if ($implementationChanged.Count -gt 0 -and $draftSpecChanged.Count -gt 0) {
            $errors.Add("Implementation/build files changed while controlling specs are still draft: $($draftSpecChanged -join ', ')")
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_EVENT_PATH) -and (Test-Path $env:GITHUB_EVENT_PATH)) {
    try {
        $event = Get-Content $env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json
        if ($event.pull_request) {
            $body = [string]$event.pull_request.body
            foreach ($required in @("## Controlling Spec", "## Validation", "## Traceability")) {
                if ($body -notmatch [regex]::Escape($required)) { $errors.Add("Pull request body is missing required section: $required") }
            }
            foreach ($label in @("Spec:", "Build-system impact:", "Specs updated:", "Implementation files:", "Generated or derived files:")) {
                $match = [regex]::Match($body, "(?m)^\s*-\s*" + [regex]::Escape($label) + "\s*(?<value>.*)$")
                if (-not $match.Success) { $errors.Add("Pull request body is missing traceability field: $label") }
                elseif ([string]::IsNullOrWhiteSpace($match.Groups["value"].Value)) { $errors.Add("Pull request traceability field is blank: $label") }
            }
        }
    } catch {
        $errors.Add("Unable to inspect GitHub pull request event payload: $($_.Exception.Message)")
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Traceability validation failed:" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host " - $e" -ForegroundColor Red }
    exit 1
}
Write-Host "Traceability validation passed." -ForegroundColor Green
