[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$expectedUserName = 'yuweiyang9611'
$expectedEmail = '91787866+yuweiyang9611@users.noreply.github.com'
$expectedHooksPath = '.githooks'

function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$GitArguments)

    & git @GitArguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git was not found in PATH.'
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    throw 'Run this script from inside a Git clone of TodoDemo.'
}

$repoRoot = $repoRoot.Trim()
Set-Location -LiteralPath $repoRoot

$requiredHooks = @(
    '.githooks/pre-commit',
    '.githooks/pre-push'
)

foreach ($hook in $requiredHooks) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $hook))) {
        throw "Required hook is missing: $hook"
    }
}

Invoke-Git -GitArguments @('config', '--local', 'core.hooksPath', $expectedHooksPath)
Invoke-Git -GitArguments @('config', '--local', 'user.name', $expectedUserName)
Invoke-Git -GitArguments @('config', '--local', 'user.email', $expectedEmail)
Invoke-Git -GitArguments @('config', '--local', 'user.useConfigOnly', 'true')

$actualHooksPath = (& git config --local --get core.hooksPath).Trim()
$actualEmail = (& git config --local --get user.email).Trim()
$useConfigOnly = (& git config --local --get user.useConfigOnly).Trim()

if ($actualHooksPath -ne $expectedHooksPath) {
    throw "Unexpected hooks path: $actualHooksPath"
}
if ($actualEmail -ne $expectedEmail) {
    throw "Unexpected Git email: $actualEmail"
}
if ($useConfigOnly -ne 'true') {
    throw 'user.useConfigOnly was not enabled.'
}

Write-Host 'Git hooks enabled for this clone.'
Write-Host "core.hooksPath=$actualHooksPath"
Write-Host "user.email=$actualEmail"
Write-Host "user.useConfigOnly=$useConfigOnly"