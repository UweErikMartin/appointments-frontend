param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("feature", "executable", "subcomponent", "build-system")]
    [string]$Kind,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [string]$ParentComponent,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$templateRoot = Join-Path $repoRoot "build/templates/specs"

function ConvertTo-KebabCase([string]$Value) {
    $normalized = $Value.Trim().ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    return $normalized.Trim("-")
}

function ConvertTo-Title([string]$Value) {
    return ((ConvertTo-KebabCase $Value) -split "-" | ForEach-Object { if ($_.Length -gt 0) { $_.Substring(0,1).ToUpperInvariant() + $_.Substring(1) } }) -join " "
}

function Format-BulletList([string[]]$Items) {
    return (($Items | ForEach-Object { "- $_" }) -join "`n")
}

function Format-OwnedPaths([string[]]$Items) {
    return (($Items | ForEach-Object { "  - $_" }) -join "`n")
}

function Write-FromTemplate([string]$TemplateName, [string]$TargetPath, [hashtable]$Values) {
    $templatePath = Join-Path $templateRoot $TemplateName
    if (-not (Test-Path $templatePath)) { throw "Missing template: $TemplateName" }
    $absoluteTarget = Join-Path $repoRoot $TargetPath
    if ((Test-Path $absoluteTarget) -and -not $Force) { throw "Target already exists: $TargetPath. Re-run with -Force only after confirming overwrite is intended." }
    New-Item -ItemType Directory -Force -Path (Split-Path $absoluteTarget -Parent) | Out-Null
    $content = Get-Content $templatePath -Raw
    foreach ($key in $Values.Keys) { $content = $content.Replace("{{$key}}", [string]$Values[$key]) }
    if ($content -match "\{\{[A-Z0-9_]+\}\}") { throw "Unresolved template token in $TargetPath" }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($absoluteTarget, ($content -replace "`r`n", "`n"), $utf8)
    Write-Host "Created $TargetPath"
}

$slug = ConvertTo-KebabCase $Name
if ([string]::IsNullOrWhiteSpace($slug)) { throw "Name must contain at least one letter or number." }
$title = ConvertTo-Title $Name
$parent = if ([string]::IsNullOrWhiteSpace($ParentComponent)) { "Not specified" } else { $ParentComponent }
$related = New-Object System.Collections.Generic.List[string]
$created = New-Object System.Collections.Generic.List[string]

$commonValidation = Format-BulletList @(
    '`powershell -ExecutionPolicy Bypass -File ./tools/sdd/validate-specs.ps1`',
    '`powershell -ExecutionPolicy Bypass -File ./tools/sdd/check-traceability.ps1`',
    '`powershell -ExecutionPolicy Bypass -File ./tools/sdd/verify-build-spec.ps1`'
)

if ($Kind -eq "build-system") {
    $buildSpecPath = "specs/build/$slug.spec.md"
    $related.Add($buildSpecPath)
    $created.Add($buildSpecPath)
}

if ($Kind -in @("feature", "executable")) {
    $featurePath = "specs/product/features/$slug.spec.md"
    $related.Add($featurePath)
    $created.Add($featurePath)
}
if ($Kind -in @("executable", "subcomponent")) {
    $componentPath = "specs/architecture/components/$slug.spec.md"
    $interfacePath = if ($Kind -eq "executable") { "specs/architecture/interfaces/$slug-cli.spec.md" } else { "specs/architecture/interfaces/$slug.spec.md" }
    $related.Add($componentPath)
    $related.Add($interfacePath)
    $created.Add($componentPath)
    $created.Add($interfacePath)
}
if ($Kind -ne "build-system") {
    $acceptancePath = "specs/testing/acceptance/$slug.spec.md"
    $related.Add($acceptancePath)
    $created.Add($acceptancePath)
}

$relatedText = ($related -join ", ")

if ($Kind -eq "build-system") {
    Write-FromTemplate "build-system.spec.md.template" "specs/build/$slug.spec.md" @{
        SPEC_ID = "build.$slug"
        OWNED_PATHS = Format-OwnedPaths @("specs/build/$slug.spec.md")
        TITLE = "$title Build-System Spec"
        PURPOSE = $Summary
        SCOPE = "Define build, CI/CD, local development, release, artifact, or toolchain behavior for $title. Ask for confirmation before choosing tools, file names, commands, container images, registries, or workflow semantics not stated by the user."
        INPUTS = Format-BulletList @("Source files and repository specs", "Local developer commands", "CI/CD workflow events and environment", "Toolchain and artifact requirements")
        OUTPUTS = Format-BulletList @("Documented build-system behavior", "Validation commands", "Generated or derived build artifacts, if applicable")
        BUILD_CONTRACT = "Specify exact commands, expected inputs, outputs, failure behavior, and ownership boundaries before implementation."
        LOCAL_DEV_IMPACT = "Describe new or changed local commands, prerequisites, and developer diagnostics. If none, state no local development impact."
        CI_CD_IMPACT = "Describe new or changed workflows, jobs, permissions, runner assumptions, and required checks. If none, state no CI/CD impact."
        ARTIFACT_IMPACT = "Describe generated files, container images, build outputs, release artifacts, cache paths, or registry outputs. If none, state no artifact impact."
        ACCEPTANCE_CRITERIA = Format-BulletList @("Build-system behavior is specified before implementation.", "Local and CI entry points remain equivalent where feasible.", "Generated or derived artifacts are traceable to this spec or a more specific build spec.", "Ambiguous tools, commands, image names, or publication targets are confirmed with the user before implementation.")
        RELATED_SPECS = $relatedText
        IMPLEMENTATION_TARGETS = "To be defined after commands, workflows, tools, and artifact paths are confirmed."
        GENERATED_FILES = "To be defined if this build-system behavior generates files or artifacts."
        VALIDATION = $commonValidation
    }
}


if ($Kind -in @("feature", "executable")) {
    Write-FromTemplate "feature.spec.md.template" "specs/product/features/$slug.spec.md" @{
        SPEC_ID = "product.features.$slug"
        OWNED_PATHS = Format-OwnedPaths @("specs/product/features/$slug.spec.md")
        TITLE = "$title Feature Spec"
        PURPOSE = $Summary
        SCOPE = "Define the user-visible behavior for $title. Refine this scope before implementation if boundaries are unclear."
        INPUTS = Format-BulletList @("User or caller request for $title", "Related product and architecture specs")
        OUTPUTS = Format-BulletList @("Observable behavior for $title", "Validation evidence mapped to acceptance criteria")
        BEHAVIOR_CONTRACT = "Describe the externally observable behavior, including success paths, failure paths, and non-goals. Ask for confirmation before inventing missing behavior."
        ACCEPTANCE_CRITERIA = Format-BulletList @("Behavior is defined with measurable success and failure outcomes.", "Ambiguous behavior is resolved with the user before implementation.", "Implementation links back to this spec and related specs.")
        TEST_STRATEGY = "Define acceptance, regression, and contract tests required for this feature before implementation."
        BUILD_IMPACT = "No build-system impact unless this feature changes local commands, CI, release, generated artifacts, or toolchain behavior."
        RELATED_SPECS = $relatedText
        IMPLEMENTATION_TARGETS = "To be defined after architecture and interface specs are confirmed."
        GENERATED_FILES = "None unless a generator is introduced by a controlling build spec."
        VALIDATION = $commonValidation
    }
}

if ($Kind -in @("executable", "subcomponent")) {
    Write-FromTemplate "component.spec.md.template" "specs/architecture/components/$slug.spec.md" @{
        SPEC_ID = "architecture.components.$slug"
        OWNED_PATHS = Format-OwnedPaths @("specs/architecture/components/$slug.spec.md")
        TITLE = "$title Component Spec"
        PURPOSE = $Summary
        SCOPE = "Define responsibilities, boundaries, dependencies, and non-goals for the $title component."
        INPUTS = Format-BulletList @("Calls, commands, data, or events accepted by $title", "Related feature and interface specs")
        OUTPUTS = Format-BulletList @("Results, side effects, state changes, files, or events produced by $title")
        RESPONSIBILITIES = Format-BulletList @("Own the behavior explicitly assigned in related specs.", "Reject or surface unsupported behavior instead of guessing.")
        DEPENDENCIES = "List runtime, build-time, external service, and data dependencies. Ask the user if dependencies are unclear."
        ACCEPTANCE_CRITERIA = Format-BulletList @("Component responsibilities are unique and do not overlap conflicting specs.", "Dependencies and integration points are documented before implementation.", "Failure behavior is specified or explicitly deferred.")
        PARENT_COMPONENT = $parent
        RELATED_SPECS = $relatedText
        IMPLEMENTATION_TARGETS = "To be defined after repository language and layout are confirmed."
        VALIDATION = $commonValidation
    }

    $interfaceTitle = if ($Kind -eq "executable") { "$title CLI Interface Spec" } else { "$title Interface Spec" }
    Write-FromTemplate "interface.spec.md.template" $interfacePath @{
        SPEC_ID = if ($Kind -eq "executable") { "architecture.interfaces.$slug-cli" } else { "architecture.interfaces.$slug" }
        OWNED_PATHS = Format-OwnedPaths @($interfacePath)
        TITLE = $interfaceTitle
        PURPOSE = "Define the interface contract for $title."
        SCOPE = "Define commands, inputs, outputs, errors, compatibility, and integration expectations for this interface."
        INPUTS = if ($Kind -eq "executable") { Format-BulletList @("Command-line arguments", "Environment variables", "Standard input, if applicable") } else { Format-BulletList @("Calls, messages, events, or data accepted by the component") }
        OUTPUTS = if ($Kind -eq "executable") { Format-BulletList @("Exit codes", "Standard output", "Standard error", "Files or side effects, if applicable") } else { Format-BulletList @("Return values, messages, events, state changes, or side effects") }
        INTERFACE_CONTRACT = "Specify exact input/output behavior. Ask the user before choosing names, arguments, protocols, or error formats that are not stated."
        COMPATIBILITY = "Document compatibility commitments and migration expectations."
        ACCEPTANCE_CRITERIA = Format-BulletList @("Inputs, outputs, and error behavior are deterministic.", "Unsupported inputs are handled explicitly.", "Compatibility impact is documented before implementation.")
        RELATED_SPECS = $relatedText
        IMPLEMENTATION_TARGETS = "To be defined after repository language and layout are confirmed."
        VALIDATION = $commonValidation
    }
}

if ($Kind -ne "build-system") {
    Write-FromTemplate "acceptance.spec.md.template" $acceptancePath @{
    SPEC_ID = "testing.acceptance.$slug"
    OWNED_PATHS = Format-OwnedPaths @($acceptancePath)
    TITLE = "$title Acceptance Spec"
    PURPOSE = "Define acceptance validation for $title."
    SCOPE = "Cover user-visible and integration-level outcomes required before implementation is considered done."
    INPUTS = Format-BulletList @("Related feature, component, and interface specs", "Acceptance criteria from the controlling spec group")
    OUTPUTS = Format-BulletList @("Acceptance scenarios", "Validation commands or manual review gates")
    ACCEPTANCE_SCENARIOS = Format-BulletList @("Happy path: define the expected successful use of $title.", "Failure path: define expected behavior for invalid or unsupported input.", "Regression path: define behavior that must remain stable after future changes.")
    ACCEPTANCE_CRITERIA = Format-BulletList @("Acceptance scenarios map to related spec acceptance criteria.", "Validation is automated where feasible or explicitly marked as manual.", "Ambiguous expected outcomes are confirmed with the user before implementation.")
    RELATED_SPECS = $relatedText
    IMPLEMENTATION_TARGETS = "To be defined after implementation layout is confirmed."
    VALIDATION = $commonValidation
    }
}

Write-Host "Spec set created for '$Name' ($Kind). Review and refine draft specs before implementation."
