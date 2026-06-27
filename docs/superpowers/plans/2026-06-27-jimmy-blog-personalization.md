# Jimmy Blog Personalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the forked Hux Blog repository into Jimmy's clean AI programming and applications blog without retaining the original author's posts, identity, accounts, or analytics.

**Architecture:** Preserve the existing Jekyll theme and deployment workflow, but replace the site-owned content and configuration at their existing boundaries. Add a repeatable PowerShell verification script that checks identity configuration, removed content, permitted attribution, and generated-site output.

**Tech Stack:** Jekyll 4, Liquid, Markdown, YAML, GitHub Pages, PowerShell, Git

---

## File Map

- `docs/superpowers/specs/2026-06-27-jimmy-blog-personalization-design.md`: approved scope.
- `scripts/verify-personalization.ps1`: repeatable acceptance checks.
- `_config.yml`: public identity, canonical URL, SEO, social links, sidebar, comments, analytics.
- `CNAME`: GitHub Pages custom domain.
- `index.html`: homepage strapline and empty post-list rendering.
- `about.html`, `_includes/about/zh.md`: Jimmy's public About page.
- `_posts/**`, `_includes/posts/**`: original-author articles and article fragments to remove.
- `img/in-post/**`, `img/post-*.{jpg,png,gif}`, `img/avatar-hux*.jpg`, `img/bg-me-2022.jpg`, `img/icon_wechat.png`: original-author article and identity assets to remove.
- `_layouts/default.html`: remove the hidden original WeChat preview image.
- `_includes/footer.html`: keep accurate theme provenance while removing the original author's personal-domain and repository widgets.
- `pwa/manifest.json`, `sw.js`: public PWA identity and cache entries.
- `Rakefile`: make newly generated posts default to Jimmy.
- `package.json`, `package-lock.json`: identify this fork and its repository correctly.
- `ads.txt`: remove the upstream author's advertising publisher account.
- `README.md`: Jimmy-specific maintenance instructions plus theme license attribution.
- `_doc/**`: obsolete upstream-author documentation to remove.

### Task 1: Import the Forked Blog Source

**Files:**
- Merge: remote `master` tree into the current repository
- Preserve: `docs/superpowers/specs/2026-06-27-jimmy-blog-personalization-design.md`
- Preserve: `docs/superpowers/plans/2026-06-27-jimmy-blog-personalization.md`

- [ ] **Step 1: Register the user's GitHub repository as `origin`**

Run:

```powershell
git remote add origin https://github.com/jimmy6270/jimmy6270.github.io.git
git remote -v
```

Expected: both fetch and push URLs point to `jimmy6270/jimmy6270.github.io.git`.

- [ ] **Step 2: Fetch the deployed branch**

Run:

```powershell
git fetch origin master
```

Expected: `origin/master` is created or updated.

- [ ] **Step 3: Merge the unrelated histories without discarding either side**

Run:

```powershell
git merge --allow-unrelated-histories origin/master -m "chore: import forked blog source"
```

Expected: a merge commit containing the Jekyll source and the approved design documents, with no conflicted paths.

- [ ] **Step 4: Verify the imported baseline**

Run:

```powershell
(git ls-files '_posts/**').Count
git status --short
```

Expected: the post count is `86` and the worktree is clean.

### Task 2: Personalize Site Configuration and Domain

**Files:**
- Create: `scripts/verify-personalization.ps1`
- Modify: `_config.yml`
- Modify: `CNAME`
- Modify: `pwa/manifest.json`

- [ ] **Step 1: Write failing configuration checks**

Create `scripts/verify-personalization.ps1` with:

```powershell
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

Assert-Match $config '(?m)^title:\s*Jimmy Blog$' '_config.yml title'
Assert-Match $config '(?m)^url:\s*"https://blog\.jebhenry\.dpdns\.org"$' '_config.yml url'
Assert-Match $config '(?m)^github_username:\s*jimmy6270$' '_config.yml GitHub'
Assert-Match $config 'https://github\.com/jimmy6270\.png' '_config.yml avatar'
Assert-NoMatch $config 'huangxuan\.me|huxpro@gmail\.com|UA-49627206-1|disqus_username:\s*hux' '_config.yml old accounts'
Assert-Equal $cname 'blog.jebhenry.dpdns.org' 'CNAME'
Assert-Match $manifest '"name":\s*"Jimmy Blog"' 'PWA name'
Assert-NoMatch $manifest 'Hux Blog' 'PWA old name'

Write-Host 'Personalization verification passed.'
```

- [ ] **Step 2: Run the check and confirm the inherited configuration fails**

Run:

```powershell
& .\scripts\verify-personalization.ps1
```

Expected: FAIL at `_config.yml title` or another inherited identity assertion.

- [ ] **Step 3: Replace the site-owned `_config.yml` values**

Keep the existing Jekyll build, Markdown, pagination, PWA, and tag settings. Replace the identity-related sections with:

```yaml
# Site settings
title: Jimmy Blog
SEOTitle: Jimmy 的博客 | AI 编程与应用
header-img: img/home-bg.jpg
description: "探索 AI 编程与应用，分享实践、工具与思考。"
keyword: "Jimmy, AI编程, 人工智能, AI应用, 大语言模型, 编程工具, 软件开发, 技术博客"
url: "https://blog.jebhenry.dpdns.org"
baseurl: ""

# SNS settings
RSS: false
github_username: jimmy6270

# Sidebar settings
sidebar: true
sidebar-about-description: "探索 AI 编程与应用，分享实践、工具与思考。"
sidebar-avatar: https://github.com/jimmy6270.png

# Friends
friends: []
```

Delete the inherited `email`, Weibo, Zhihu, Twitter, Disqus, Google Analytics, and Baidu Analytics values rather than replacing them with empty credentials.

- [ ] **Step 4: Set the custom domain and PWA metadata**

Replace `CNAME` with:

```text
blog.jebhenry.dpdns.org
```

Set the first three properties of `pwa/manifest.json` to:

```json
{
  "name": "Jimmy Blog",
  "short_name": "Jimmy Blog",
  "description": "探索 AI 编程与应用，分享实践、工具与思考。",
```

Keep its icons, colors, root `start_url`, display mode, and orientation unchanged.

- [ ] **Step 5: Run the configuration checks**

Run:

```powershell
& .\scripts\verify-personalization.ps1
```

Expected: `Personalization verification passed.`

- [ ] **Step 6: Commit the configuration**

Run:

```powershell
git add _config.yml CNAME pwa/manifest.json scripts/verify-personalization.ps1
git commit -m "feat: personalize blog identity and domain"
```

### Task 3: Remove Upstream Content and Create Jimmy's About Page

**Files:**
- Modify: `scripts/verify-personalization.ps1`
- Modify: `index.html`
- Modify: `about.html`
- Modify: `_includes/about/zh.md`
- Delete: `_includes/about/en.md`
- Delete: `_posts/**`
- Delete: `_includes/posts/**`
- Delete: `img/in-post/**`
- Delete: `img/post-*.jpg`
- Delete: `img/post-*.png`
- Delete: `img/post-*.gif`

- [ ] **Step 1: Add failing content checks before the final success message**

Insert this block before `Write-Host` in `scripts/verify-personalization.ps1`:

```powershell
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

$about = Get-Content -Raw -LiteralPath (Join-Path $Root '_includes/about/zh.md')
$index = Get-Content -Raw -LiteralPath (Join-Path $Root 'index.html')
Assert-Match $about 'Jimmy' 'About name'
Assert-Match $about 'AI 编程' 'About focus'
Assert-NoMatch $about '黄玄|Hux|Meta|React Team|Facebook' 'About upstream biography'
Assert-Match $index '探索 AI 编程与应用，分享实践、工具与思考。' 'Homepage description'
```

- [ ] **Step 2: Run the check and confirm inherited content fails**

Run:

```powershell
& .\scripts\verify-personalization.ps1
```

Expected: FAIL with `Expected no inherited posts, found 86.`

- [ ] **Step 3: Remove all inherited articles and their article assets**

Run with PowerShell-native removal after verifying each target is inside the repository:

```powershell
git rm -r _posts _includes/posts img/in-post
git rm img/post-*.jpg
```

Expected: all 86 posts, post fragments, in-post assets, and post header images are staged for deletion.

- [ ] **Step 4: Replace the homepage description**

Set the `index.html` front matter to:

```yaml
---
layout: page
description: "探索 AI 编程与应用，分享实践、工具与思考。"
---
```

Keep the existing paginator loop and pager markup below the front matter.

- [ ] **Step 5: Simplify the About page to one verified language**

Use this `about.html` structure:

```liquid
---
layout: page
title: "About"
description: "关于 Jimmy"
header-img: "img/home-bg.jpg"
header-mask: 0.3
---

<div class="zh post-container">
    {% capture about_zh %}{% include about/zh.md %}{% endcapture %}
    {{ about_zh | markdownify }}
</div>
```

Replace `_includes/about/zh.md` with:

```markdown
你好，我是 Jimmy。

这里主要记录我对 AI 编程与应用的探索，包括开发工具、实践方法、应用构建，以及学习过程中的思考。

希望这些内容既能留下自己的技术轨迹，也能为同样关注 AI 与软件开发的人提供一点参考。

你可以在 [GitHub](https://github.com/jimmy6270) 找到我。
```

Delete `_includes/about/en.md`; do not invent an English biography.

- [ ] **Step 6: Run the content checks**

Run:

```powershell
& .\scripts\verify-personalization.ps1
```

Expected: `Personalization verification passed.`

- [ ] **Step 7: Commit the content cleanup**

Run:

```powershell
git add index.html about.html _includes/about/zh.md scripts/verify-personalization.ps1
git add -u
git commit -m "content: remove upstream posts and add Jimmy about page"
```

### Task 4: Remove Public Identity Residue and Obsolete Upstream Material

**Files:**
- Modify: `scripts/verify-personalization.ps1`
- Modify: `_layouts/default.html`
- Modify: `_includes/footer.html`
- Modify: `sw.js`
- Modify: `Rakefile`
- Modify: `package.json`
- Modify: `package-lock.json`
- Replace: `README.md`
- Delete: `ads.txt`
- Delete: `_doc/**`
- Delete: `img/avatar-hux-home.jpg`
- Delete: `img/avatar-hux-ny.jpg`
- Delete: `img/avatar-hux.jpg`
- Delete: `img/bg-me-2022.jpg`
- Delete: `img/blog-desktop.jpg`
- Delete: `img/blog-keynote.jpg`
- Delete: `img/blog-md-navbar.gif`
- Delete: `img/blog-sidebar.jpg`
- Delete: `img/icon_wechat.png`

- [ ] **Step 1: Add failing residue checks before the final success message**

Insert this block before `Write-Host` in `scripts/verify-personalization.ps1`:

```powershell
$publicFiles = @(
    '_config.yml',
    'CNAME',
    'index.html',
    'about.html',
    '_includes/about/zh.md',
    '_includes/footer.html',
    '_layouts/default.html',
    'pwa/manifest.json',
    'sw.js',
    'Rakefile',
    'package.json',
    'package-lock.json'
)
$publicText = ($publicFiles | ForEach-Object {
    Get-Content -Raw -LiteralPath (Join-Path $Root $_)
}) -join "`n"

Assert-NoMatch $publicText '黄玄|廖剑明|huangxuan\.me|huxpro@gmail\.com|UA-49627206-1|user=huxpro|avatar-hux|icon_wechat' 'Public identity residue'
Assert-NoMatch (Get-Content -Raw -LiteralPath (Join-Path $Root 'sw.js')) '"yanshuo\.io"' 'Service worker upstream host'
Assert-Match (Get-Content -Raw -LiteralPath (Join-Path $Root 'Rakefile')) 'post\.puts "author: \\"Jimmy\\""' 'Rake post author'
Assert-Match (Get-Content -Raw -LiteralPath (Join-Path $Root 'package.json')) '"name": "jimmy-blog"' 'Package name'
Assert-Match (Get-Content -Raw -LiteralPath (Join-Path $Root 'package-lock.json')) '"name": "jimmy-blog"' 'Package lock name'

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
    'ads.txt'
)
foreach ($relativePath in $removedPaths) {
    if (Test-Path -LiteralPath (Join-Path $Root $relativePath)) {
        throw "Upstream-only path still exists: $relativePath"
    }
}
```

- [ ] **Step 2: Run the check and confirm residue fails**

Run:

```powershell
& .\scripts\verify-personalization.ps1
```

Expected: FAIL on public identity residue, the post generator author, package metadata, or an upstream-only path.

- [ ] **Step 3: Remove the hidden WeChat preview asset**

Delete this line from `_layouts/default.html`:

```html
<img src="/img/icon_wechat.png" width="0" height="0" />
```

- [ ] **Step 4: Replace the footer's upstream personal promotion**

Keep the social include and Jimmy copyright. Replace the footer attribution block with:

```html
<p class="copyright text-muted">
    Copyright &copy; {{ site.title }} {{ site.time | date: '%Y' }}
    <br>
    Theme based on
    <a href="https://github.com/Huxpro/huxpro.github.io">Hux Blog</a>
    (Apache-2.0)
</p>
```

Keep the existing theme JavaScript, search, PWA, catalog, and multilingual runtime below it. Remove the original author's star iframe and personal-domain link.

- [ ] **Step 5: Update service-worker site ownership**

In `sw.js`:

- change `CACHE_NAMESPACE` to `'jimmy-blog-'`;
- remove `./img/icon_wechat.png` and `./img/avatar-hux.jpg` from `PRECACHE_LIST`;
- keep `./img/home-bg.jpg` and `./img/404-bg.jpg`;
- set `HOSTNAME_WHITELIST` to:

```javascript
const HOSTNAME_WHITELIST = [
  self.location.hostname,
  "cdnjs.cloudflare.com"
]
```

Keep Apache-2.0 copyright comments because they are license provenance, not Jimmy's identity.

- [ ] **Step 6: Update authoring and package metadata**

In `Rakefile`, change the generated post line to:

```ruby
post.puts "author: \"Jimmy\""
```

Replace `package.json` with:

```json
{
    "name": "jimmy-blog",
    "title": "Jimmy Blog",
    "author": "Jimmy",
    "version": "1.0.0",
    "homepage": "https://blog.jebhenry.dpdns.org",
    "repository": {
        "type": "git",
        "url": "https://github.com/jimmy6270/jimmy6270.github.io"
    },
    "bugs": "https://github.com/jimmy6270/jimmy6270.github.io/issues",
    "devDependencies": {
        "grunt": ">=1.3.0",
        "grunt-banner": "~0.2.3",
        "grunt-contrib-less": "^2.0.0",
        "grunt-contrib-uglify": "^4.0.1",
        "grunt-contrib-watch": "^1.1.0"
    },
    "scripts": {
        "start": "bundle exec jekyll serve",
        "dev": "grunt watch & npm run start",
        "push": "git push origin master --tag"
    }
}
```

Edit only the root project metadata in `package-lock.json`:

```json
{
    "name": "jimmy-blog",
    "version": "1.0.0",
    "lockfileVersion": 2,
    "requires": true,
    "packages": {
        "": {
            "name": "jimmy-blog",
            "version": "1.0.0",
            "devDependencies": {
```

Keep every resolved dependency entry and version unchanged.

- [ ] **Step 7: Replace repository documentation while retaining license provenance**

Replace `README.md` with:

````markdown
# Jimmy Blog

Jimmy 的个人技术博客，主要记录 AI 编程、开发工具与实际应用。

- 网站：<https://blog.jebhenry.dpdns.org/>
- GitHub：<https://github.com/jimmy6270>

## 本地运行

需要 Ruby、Bundler 和 Node.js。

```sh
bundle install
bundle exec jekyll serve
```

默认访问地址为 <http://localhost:4000>。

## 发布

推送到 `master` 后，GitHub Actions 会构建并部署 GitHub Pages。自定义域名记录在根目录 `CNAME`。

## 主题与许可

本站主题基于 [Hux Blog](https://github.com/Huxpro/huxpro.github.io)，并派生自 Clean Blog Jekyll Theme。

主题代码继续遵循仓库内 [Apache License 2.0](LICENSE) 及相关第三方许可。
````

Delete `_doc/**`; it documents and promotes the upstream author's original site rather than this fork.

- [ ] **Step 8: Delete upstream-only identity and documentation assets**

Run:

```powershell
git rm -r _doc
git rm img/avatar-hux-home.jpg img/avatar-hux-ny.jpg img/avatar-hux.jpg
git rm img/bg-me-2022.jpg img/blog-desktop.jpg img/blog-keynote.jpg
git rm img/blog-md-navbar.gif img/blog-sidebar.jpg img/icon_wechat.png
git rm ads.txt
```

- [ ] **Step 9: Run the residue checks**

Run:

```powershell
& .\scripts\verify-personalization.ps1
```

Expected: `Personalization verification passed.`

- [ ] **Step 10: Commit the residue cleanup**

Run:

```powershell
git add _layouts/default.html _includes/footer.html sw.js Rakefile package.json package-lock.json README.md scripts/verify-personalization.ps1
git add -u
git commit -m "chore: remove upstream identity residue"
```

### Task 5: Build and Inspect the Generated Site

**Files:**
- Modify: `scripts/verify-personalization.ps1`
- Generated, ignored: `_site/**`

- [ ] **Step 1: Add generated-site assertions before the final success message**

Insert this block before `Write-Host` in `scripts/verify-personalization.ps1`:

```powershell
if (Test-Path -LiteralPath $SiteDir) {
    $siteFiles = @(Get-ChildItem -LiteralPath $SiteDir -Recurse -File -Include *.html,*.xml,*.json)
    $siteText = ($siteFiles | ForEach-Object {
        Get-Content -Raw -LiteralPath $_.FullName
    }) -join "`n"

    Assert-Match $siteText 'Jimmy Blog' 'Generated site name'
    Assert-Match $siteText 'github\.com/jimmy6270' 'Generated GitHub link'
    Assert-Match $siteText '探索 AI 编程与应用' 'Generated site focus'
    Assert-NoMatch $siteText '黄玄|廖剑明|huangxuan\.me|huxpro@gmail\.com|UA-49627206-1|user=huxpro|avatar-hux|icon_wechat' 'Generated site identity residue'
}
```

- [ ] **Step 2: Install the declared Ruby dependencies**

Run:

```powershell
bundle install
```

Expected: Bundler completes successfully using `Gemfile`.

- [ ] **Step 3: Build the production site**

Run:

```powershell
$env:JEKYLL_ENV='production'
bundle exec jekyll build
```

Expected: Jekyll exits `0` and writes `_site/index.html`, `_site/about/index.html`, and `_site/404.html`.

- [ ] **Step 4: Run source and generated-site checks**

Run:

```powershell
& .\scripts\verify-personalization.ps1
git diff --check
git status --short
```

Expected: verification passes, `git diff --check` is silent, and only `scripts/verify-personalization.ps1` is modified.

- [ ] **Step 5: Commit the generated-site verification**

Run:

```powershell
git add scripts/verify-personalization.ps1
git commit -m "test: verify personalized generated site"
```

### Task 6: Final Acceptance Review

**Files:**
- Review only: all tracked files and generated `_site/**`

- [ ] **Step 1: Confirm all commits and a clean worktree**

Run:

```powershell
git log --oneline -6
git status --short
```

Expected: import, configuration, content, residue, and verification commits are visible; the worktree is clean.

- [ ] **Step 2: Run the final verification suite**

Run:

```powershell
& .\scripts\verify-personalization.ps1
bundle exec jekyll build
& .\scripts\verify-personalization.ps1
```

Expected: both verification runs pass and the Jekyll build exits `0`.

- [ ] **Step 3: Inspect the key generated pages**

Review:

```text
_site/index.html
_site/about/index.html
_site/404.html
_site/pwa/manifest.json
```

Expected:

- visible author identity is Jimmy;
- About copy matches the approved text;
- only the `jimmy6270` social link is shown;
- no inherited posts appear;
- theme attribution is clearly separate from site authorship;
- the avatar resolves to `https://github.com/jimmy6270.png`;
- canonical URLs use `https://blog.jebhenry.dpdns.org`.

- [ ] **Step 4: Report completion without pushing**

Summarize changed files, deleted content, build results, and any environment limitation. Do not push to GitHub unless Jimmy explicitly requests it.
