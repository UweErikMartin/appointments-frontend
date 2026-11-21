[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryOwner,

    [Parameter(Mandatory = $true)]
    [string]$RepositoryName,

    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$changes = New-Object System.Collections.Generic.List[string]

function Update-Placeholder([string]$Relative, [string]$Old, [string]$New) {
    $path = Join-Path $repoRoot $Relative
    if (-not (Test-Path $path)) { return }
    $content = Get-Content $path -Raw
    if ($content -notmatch [regex]::Escape($Old)) { return }
    $message = "{0} replace '{1}' with '{2}'" -f $Relative, $Old, $New
    $changes.Add($message)
    if ($Apply) {
        $updated = $content.Replace($Old, $New)
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($path, ($updated -replace "`r`n", "`n"), $utf8)
    }
}

Update-Placeholder "CODEOWNERS" "@repo-owners" "@$RepositoryOwner"

if ($changes.Count -eq 0) {
    Write-Host "Template bootstrap: nothing to personalize (already applied)." -ForegroundColor Green
} else {
    foreach ($change in $changes) { Write-Host " - $change" }
    if ($Apply) {
        Write-Host "Template bootstrap applied for $RepositoryOwner/$RepositoryName." -ForegroundColor Green
    } else {
        Write-Host "Template bootstrap dry run. Re-run with -Apply to write changes." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Remaining manual adoption steps (see docs/template-adoption-checklist.md):"
Write-Host " - Replace product-neutral specs with product-specific specs before adding implementation code."
Write-Host " - Update README.md and SECURITY.md for the product."
Write-Host " - Configure branch protection for the required SDD checks."
