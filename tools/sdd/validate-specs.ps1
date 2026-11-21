$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$requiredFiles = @(
    "AGENTS.md",
    ".github/copilot-instructions.md",
    ".github/pull_request_template.md",
    "CODEOWNERS",
    "SECURITY.md",
    "specs/README.md",
    "specs/product/requirements/sdd-template-repository.spec.md",
    "specs/build/build-system.spec.md",
    "specs/build/local-dev.spec.md",
    "specs/build/ci-cd.spec.md",
    "specs/build/toolchain.spec.md",
    "specs/build/quality-gates.spec.md",
    "specs/testing/test-strategy.spec.md",
    "specs/architecture/system-context.md"
)
$requiredSections = @("## Purpose", "## Scope", "## Inputs", "## Outputs", "## Acceptance Criteria", "## Validation")
$errors = New-Object System.Collections.Generic.List[string]

foreach ($file in $requiredFiles) {
    $path = Join-Path $repoRoot $file
    if (-not (Test-Path $path)) { $errors.Add("Missing required file: $file") }
}

function Get-RepoRelativePath([string]$FullName) {
    $root = $repoRoot.ProviderPath.TrimEnd("\", "/")
    $full = (Resolve-Path $FullName).ProviderPath
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length).TrimStart("\", "/").Replace("\", "/")
    }
    return $full.Replace("\", "/")
}

$specFiles = Get-ChildItem (Join-Path $repoRoot "specs") -Recurse -File -Include "*.spec.md", "vision.md", "system-context.md", "security-overview.md"
$ids = @{}
$ownedPaths = @{}
$ownedRecords = New-Object System.Collections.Generic.List[object]
$allowedDomains = @("product", "architecture", "build", "testing", "operations")

foreach ($spec in $specFiles) {
    $relative = Get-RepoRelativePath $spec.FullName
    $content = Get-Content $spec.FullName -Raw

    foreach ($section in $requiredSections) {
        if ($content -notmatch [regex]::Escape($section)) { $errors.Add("Missing section '$section' in $relative") }
    }

    if ($content -match "To be refined as the system evolves") {
        $errors.Add("Placeholder text remains in $relative")
    }

    if ($content -notmatch "(?s)^---\n(?<meta>.*?)\n---\n") {
        $errors.Add("Missing metadata front matter in $relative")
        continue
    }

    $meta = $Matches.meta
    $idMatch = [regex]::Match($meta, "(?m)^id:\s*(?<value>[A-Za-z0-9_.-]+)\s*$")
    $domainMatch = [regex]::Match($meta, "(?m)^domain:\s*(?<value>[A-Za-z0-9_-]+)\s*$")
    $statusMatch = [regex]::Match($meta, "(?m)^status:\s*(?<value>[A-Za-z0-9_-]+)\s*$")

    if (-not $idMatch.Success) { $errors.Add("Missing metadata id in $relative") }
    else {
        $id = $idMatch.Groups["value"].Value
        if ($ids.ContainsKey($id)) { $errors.Add("Duplicate spec id '$id' in $relative and $($ids[$id])") }
        else { $ids[$id] = $relative }
    }

    if (-not $domainMatch.Success) { $errors.Add("Missing metadata domain in $relative") }
    elseif ($allowedDomains -notcontains $domainMatch.Groups["value"].Value) { $errors.Add("Unsupported metadata domain '$($domainMatch.Groups["value"].Value)' in $relative") }

    if (-not $statusMatch.Success) { $errors.Add("Missing metadata status in $relative") }

    $ownsMatch = [regex]::Match($meta, "(?ms)^owns:\s*\n(?<items>(?:\s+-\s+.+\n?)+)")
    if (-not $ownsMatch.Success) {
        $errors.Add("Missing metadata owns list in $relative")
    } else {
        foreach ($line in ($ownsMatch.Groups["items"].Value -split "\n")) {
            if ($line -match "^\s+-\s+(?<path>.+?)\s*$") {
                $owned = $Matches.path.Trim().Replace("\", "/")
                if ([string]::IsNullOrWhiteSpace($owned)) { continue }
                if ($ownedPaths.ContainsKey($owned)) { $errors.Add("Duplicate owned path '$owned' in $relative and $($ownedPaths[$owned])") }
                else { $ownedPaths[$owned] = $relative }
                $ownedRecords.Add([pscustomobject]@{ Pattern = $owned; Spec = $relative })
            }
        }
    }
}

function Convert-OwnedPatternToRegex([string]$Pattern) {
    $escaped = [regex]::Escape($Pattern).Replace("\*\*", "__DOUBLE_STAR__").Replace("\*", "__SINGLE_STAR__")
    $escaped = $escaped.Replace("__DOUBLE_STAR__", ".*").Replace("__SINGLE_STAR__", "[^/]*")
    return "^$escaped$"
}

function Test-OwnedPatternOverlap([string]$Left, [string]$Right) {
    if ($Left -eq $Right) { return $true }
    if ($Left.EndsWith("/**")) {
        $prefix = $Left.Substring(0, $Left.Length - 3)
        if ($Right -eq $prefix -or $Right.StartsWith("$prefix/")) { return $true }
    }
    if ($Right.EndsWith("/**")) {
        $prefix = $Right.Substring(0, $Right.Length - 3)
        if ($Left -eq $prefix -or $Left.StartsWith("$prefix/")) { return $true }
    }
    if ($Left.Contains("*") -and ($Right -match (Convert-OwnedPatternToRegex $Left))) { return $true }
    if ($Right.Contains("*") -and ($Left -match (Convert-OwnedPatternToRegex $Right))) { return $true }
    return $false
}

for ($i = 0; $i -lt $ownedRecords.Count; $i++) {
    for ($j = $i + 1; $j -lt $ownedRecords.Count; $j++) {
        $left = $ownedRecords[$i]
        $right = $ownedRecords[$j]
        if ($left.Spec -ne $right.Spec -and (Test-OwnedPatternOverlap $left.Pattern $right.Pattern)) {
            $errors.Add("Overlapping owned paths '$($left.Pattern)' in $($left.Spec) and '$($right.Pattern)' in $($right.Spec)")
        }
    }
}
if ($errors.Count -gt 0) {
    Write-Host "Spec validation failed:" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host " - $e" -ForegroundColor Red }
    exit 1
}
Write-Host "Spec validation passed." -ForegroundColor Green