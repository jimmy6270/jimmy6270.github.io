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

$publicFiles = @(
    '_config.yml',
    'CNAME',
    'index.html',
    'about.html',
    '_includes/about/zh.md',
    '_includes/footer.html',
    '_includes/head.html',
    '_layouts/default.html',
    '_layouts/keynote.html',
    '_layouts/page.html',
    '_layouts/post.html',
    'pwa/manifest.json',
    'sw.js',
    'Rakefile',
    'package.json',
    'package-lock.json'
)
$publicText = ($publicFiles | ForEach-Object {
    Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root $_)
}) -join "`n"

Assert-NoMatch $publicText '\u9EC4\u7384|\u5ED6\u5251\u660E|huangxuan\.me|huxpro@gmail\.com|UA-49627206-1|user=huxpro|avatar-hux|icon_wechat|ca-pub-6487568398225121|include ads\.html' 'Public identity residue'
Assert-NoMatch (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'sw.js')) '"yanshuo\.io"' 'Service worker upstream host'
Assert-Match (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'Rakefile')) 'post\.puts "author: \\"Jimmy\\""' 'Rake post author'
Assert-Match (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'Rakefile')) 'post\.puts "header-img: \\"img/home-bg\.jpg\\""' 'Rake post header image'
Assert-Match (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'package.json')) '"name": "jimmy-blog"' 'Package name'
Assert-Match (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root 'package-lock.json')) '"name": "jimmy-blog"' 'Package lock name'

$removedPaths = @(
    '_doc',
    'img/avatar-hux-home.jpg',
    'img/avatar-hux-ny.jpg',
    'img/avatar-hux.jpg',
    'img/bg-me-2022.jpg',
    'img/blog-desktop.jpg',
    'img/blog-keynote.jpg',
    'img/blog-md-navbar.gif',
    'img/blog-sidebar.jpg',
    'img/icon_wechat.png',
    '_includes/ads.html',
    'ads.txt'
)
foreach ($relativePath in $removedPaths) {
    if (Test-Path -LiteralPath (Join-Path $Root $relativePath)) {
        throw "Upstream-only path still exists: $relativePath"
    }
}

if (Test-Path -LiteralPath $SiteDir) {
    $siteFiles = @(Get-ChildItem -LiteralPath $SiteDir -Recurse -File -Include *.html,*.xml,*.json)
    $siteText = ($siteFiles | ForEach-Object {
        Get-Content -Raw -Encoding UTF8 -LiteralPath $_.FullName
    }) -join "`n"

    Assert-Match $siteText 'Jimmy Blog' 'Generated site name'
    Assert-Match $siteText 'github\.com/jimmy6270' 'Generated GitHub link'
    Assert-Match $siteText '\u63A2\u7D22 AI \u7F16\u7A0B\u4E0E\u5E94\u7528' 'Generated site focus'
    Assert-NoMatch $siteText '\u9EC4\u7384|\u5ED6\u5251\u660E|huangxuan\.me|huxpro@gmail\.com|UA-49627206-1|user=huxpro|avatar-hux|icon_wechat|ca-pub-6487568398225121' 'Generated site identity residue'
}

Write-Host 'Personalization verification passed.'
