[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$SiteDir = (Join-Path (Split-Path -Parent $PSScriptRoot) '_site')
)

$ErrorActionPreference = 'Stop'

function Assert-Equal {
    param([string]$Actual, [string]$Expected, [string]$Label)
    if ($Actual.Trim() -cne $Expected) {
        throw "$Label expected '$Expected' but found '$Actual'."
    }
}

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Label)
    if ($Text -notmatch $Pattern) {
        throw "$Label did not match /$Pattern/."
    }
}

function Assert-NoMatch {
    param([string]$Text, [string]$Pattern, [string]$Label)
    if ($Text -match $Pattern) {
        throw "$Label unexpectedly matched /$Pattern/."
    }
}

$config = Get-Content -Raw -LiteralPath (Join-Path $Root '_config.yml')
$cname = Get-Content -Raw -LiteralPath (Join-Path $Root 'CNAME')
$manifest = Get-Content -Raw -LiteralPath (Join-Path $Root 'pwa/manifest.json')

Assert-Match $config '(?m)^title:\s*Jimmy Blog\r?$' '_config.yml title'
Assert-Match $config '(?m)^url:\s*"https://blog\.jebhenry\.dpdns\.org"\r?$' '_config.yml url'
Assert-Match $config '(?m)^github_username:\s*jimmy6270\r?$' '_config.yml GitHub'
Assert-Match $config 'https://github\.com/jimmy6270\.png' '_config.yml avatar'
Assert-NoMatch $config 'huangxuan\.me|huxpro@gmail\.com|UA-49627206-1|disqus_username:\s*hux' '_config.yml old accounts'
Assert-Equal $cname 'blog.jebhenry.dpdns.org' 'CNAME'
Assert-Match $manifest '"name":\s*"Jimmy Blog"' 'PWA name'
Assert-NoMatch $manifest 'Hux Blog' 'PWA old name'

Write-Host 'Personalization verification passed.'
