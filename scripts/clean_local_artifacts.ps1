[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Remove-PathIfPresent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "Skip missing: $Path" -ForegroundColor DarkGray
        return
    }

    if ($PSCmdlet.ShouldProcess($Path, 'Remove')) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        Write-Host "Removed: $Path" -ForegroundColor Yellow
    }
}

$targets = @(
    (Join-Path $repoRoot 'build'),
    (Join-Path $repoRoot 'release_output'),
    (Join-Path $repoRoot 'release_symbols'),
    (Join-Path $repoRoot '.dart_tool')
)

foreach ($target in $targets) {
    Remove-PathIfPresent -Path $target
}

$logPatterns = @('*.log', '*.log.*', '*.trace', '*.dmp', '*.stackdump')
$logFiles = Get-ChildItem -Path $repoRoot -File -Force | Where-Object {
    $name = $_.Name
    $logPatterns | Where-Object { $name -like $_ } | Select-Object -First 1
}

foreach ($logFile in $logFiles) {
    Remove-PathIfPresent -Path $logFile.FullName
}

$rootArtifacts = @(
    (Join-Path $repoRoot 'build_output.txt')
)

foreach ($artifact in $rootArtifacts) {
    Remove-PathIfPresent -Path $artifact
}

Write-Host "Cleanup plan complete for $repoRoot." -ForegroundColor Green
