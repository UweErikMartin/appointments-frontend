$ErrorActionPreference = "Stop"
$errors = New-Object System.Collections.Generic.List[string]
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $errors.Add("Required command not found: git") }
$hasPwsh = [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
$hasWindowsPowerShell = [bool](Get-Command powershell -ErrorAction SilentlyContinue)
if (-not ($hasPwsh -or $hasWindowsPowerShell)) { $errors.Add("Required command not found: pwsh or powershell") }
if ($PSVersionTable.PSVersion.Major -lt 5) { $errors.Add("PowerShell 5 or newer is required. Current version: $($PSVersionTable.PSVersion)") }
if ($errors.Count -gt 0) { Write-Host "Developer environment check failed:" -ForegroundColor Red; foreach ($e in $errors) { Write-Host " - $e" -ForegroundColor Red }; exit 1 }
Write-Host "Developer environment check passed." -ForegroundColor Green
