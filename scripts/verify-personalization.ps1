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

$config = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root '_config.yml')
$cname = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'CNAME')
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'pwa/manifest.json')

Assert-Match $config '(?m)^title:\s*Jimmy Blog\r?$' '_config.yml title'
Assert-Match $config '(?m)^url:\s*"https://blog\.jebhenry\.dpdns\.org"\r?$' '_config.yml url'
Assert-Match $config '(?m)^github_username:\s*jimmy6270\r?$' '_config.yml GitHub'
Assert-Match $config 'https://github\.com/jimmy6270\.png' '_config.yml avatar'
Assert-NoMatch $config 'huangxuan\.me|huxpro@gmail\.com|UA-49627206-1|disqus_username:\s*hux' '_config.yml old accounts'
Assert-Equal $cname 'blog.jebhenry.dpdns.org' 'CNAME'
Assert-Match $manifest '"name":\s*"Jimmy Blog"' 'PWA name'
Assert-NoMatch $manifest 'Hux Blog' 'PWA old name'

$posts = @(Get-ChildItem -LiteralPath (Join-Path $Root '_posts') -Recurse -File -ErrorAction SilentlyContinue)
if ($posts.Count -ne 0) {
    throw "Expected no inherited posts, found $($posts.Count)."
}

$inheritedContentPaths = @(
    (Join-Path $Root '_includes/posts'),
    (Join-Path $Root 'img/in-post')
)
foreach ($path in $inheritedContentPaths) {
    if (Test-Path -LiteralPath $path) {
        throw "Inherited content path still exists: $path"
    }
}

$about = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root '_includes/about/zh.md')
$index = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'index.html')
Assert-Match $about 'Jimmy' 'About name'
Assert-Match $about 'AI \u7F16\u7A0B' 'About focus'
Assert-NoMatch $about '\u9EC4\u7384|Hux|Meta|React Team|Facebook' 'About upstream biography'
Assert-Match $index '\u63A2\u7D22 AI \u7F16\u7A0B\u4E0E\u5E94\u7528\uFF0C\u5206\u4EAB\u5B9E\u8DF5\u3001\u5DE5\u5177\u4E0E\u601D\u8003\u3002' 'Homepage description'

Write-Host 'Personalization verification passed.'
