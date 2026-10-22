# /pack PowerShell execution script
#
# Usage:
#   normal mode: powershell -ExecutionPolicy Bypass -File .claude\skills\pack\scripts\pack.ps1
#   share  mode: powershell -ExecutionPolicy Bypass -File .claude\skills\pack\scripts\pack.ps1 -Mode share
#
# Reads packaging.config.json, cleans staging, copies sources, applies excludes,
# compresses the zip, and runs a sensitive-file quick check.
#
# share mode is OPT-IN ONLY. It produces a separate artifact name (shareMode.artifact)
# that carries local credentials such as *.token-cache.json. Such artifacts MUST be
# ignored by git and MUST NOT be pushed or redistributed. The script auto-appends the
# share artifact name to .gitignore and aborts if git tracking is detected.
#
# Output is kept ASCII-only so this script runs under any PowerShell default
# encoding (Windows PS 5.1 included). See SKILL.md for the full constraints.

param(
    [string]$Root,
    [ValidateSet("normal", "share")]
    [string]$Mode = "normal"
)

$ErrorActionPreference = "Stop"

# --- Helpers -----------------------------------------------------------------

# Convert a Windows path under a root to a forward-slash relative path.
function Get-RelPath {
    param([string]$Full, [string]$Root)
    $rel = $Full.Substring($Root.Length).TrimStart('\','/')
    return ($rel -replace '\\', '/')
}

# Glob matcher for forward-slash paths. Supports ** (any segments incl. zero)
# and * (within one segment). Implemented by translating to a .NET regex.
function Test-GlobMatch {
    param([string]$Path, [string]$Pattern)
    $rx = [regex]::Escape($Pattern)
    # Restore wildcard semantics after escaping.
    $rx = $rx -replace '\\\*\\\*/', '(?:.*/)?'
    $rx = $rx -replace '\\\*\\\*', '.*'
    $rx = $rx -replace '\\\*', '[^/]*'
    return [regex]::IsMatch($Path, '^' + $rx + '$')
}

# Parse references out of SKILL.md. Two sources:
#   1) Markdown links: [text](relative/path)
#   2) Backtick-wrapped path-like strings ending in a known file extension
# Skipped in both cases: absolute URLs, anchors, mailto, paths with .., and
# verbose project-level paths starting with .claude/ (authors typically also
# write a short form for those, which we pick up instead).
function Get-SkillReferencedPaths {
    param([string]$SkillMdPath)
    if (-not (Test-Path $SkillMdPath)) { return @() }
    $content = Get-Content $SkillMdPath -Raw -Encoding UTF8
    $out = @()

    # 1) Markdown links
    $mdMatches = [regex]::Matches($content, '\]\(([^)\s]+)\)')
    foreach ($m in $mdMatches) {
        $p = $m.Groups[1].Value.Trim()
        if (-not $p) { continue }
        if ($p -match '^(https?:|mailto:|#|/|~)') { continue }
        if ($p -match '\.\.') { continue }
        $p = ($p -split '#')[0]
        if (-not $p) { continue }
        $out += ($p -replace '\\', '/')
    }

    # 2) Backtick-wrapped paths with known file extension
    $extList = 'json|md|html|htm|js|mjs|ts|ps1|sh|py|yaml|yml|png|svg|jpg|jpeg|gif|css|txt|xml|tsv|csv'
    $btMatches = [regex]::Matches($content, '`([^`\s]+\.(?:' + $extList + '))`')
    foreach ($m in $btMatches) {
        $p = $m.Groups[1].Value.Trim()
        if (-not $p) { continue }
        if ($p -match '^(https?:|/|~)') { continue }
        if ($p -match '\.\.') { continue }
        if ($p -match '^\.claude/') { continue }
        $out += ($p -replace '\\', '/')
    }

    return ($out | Sort-Object -Unique)
}

# Copy a single skill directory by whitelist rules.
function Copy-SingleSkill {
    param(
        [string]$SkillSrc,
        [string]$SkillDest,
        $Whitelist
    )
    if (-not (Test-Path $SkillDest)) {
        New-Item -ItemType Directory -Force -Path $SkillDest | Out-Null
    }

    $allFiles = Get-ChildItem -Path $SkillSrc -Recurse -File -Force -ErrorAction SilentlyContinue
    $skillRoot = (Resolve-Path $SkillSrc).Path

    # Build keep set.
    $keep = New-Object 'System.Collections.Generic.HashSet[string]'

    # Rule 1: alwaysInclude (exact filename at skill root).
    foreach ($name in @($Whitelist.alwaysInclude)) {
        $candidate = Join-Path $skillRoot $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $keep.Add((Get-RelPath -Full $candidate -Root $skillRoot)) | Out-Null
        }
    }

    # Rule 2: includeDirs (glob).
    foreach ($pat in @($Whitelist.includeDirs)) {
        foreach ($f in $allFiles) {
            $rel = Get-RelPath -Full $f.FullName -Root $skillRoot
            if (Test-GlobMatch -Path $rel -Pattern $pat) { $keep.Add($rel) | Out-Null }
        }
    }

    # Rule 3: includeDirsExcept (include glob minus except glob).
    foreach ($entry in @($Whitelist.includeDirsExcept)) {
        $incPat = $entry.dir
        $excPat = $entry.except
        foreach ($f in $allFiles) {
            $rel = Get-RelPath -Full $f.FullName -Root $skillRoot
            if (Test-GlobMatch -Path $rel -Pattern $incPat) {
                if ($excPat -and (Test-GlobMatch -Path $rel -Pattern $excPat)) { continue }
                $keep.Add($rel) | Out-Null
            }
        }
    }

    # Rule 4: SKILL.md reference fallback.
    if ($Whitelist.referenceFallback -and $Whitelist.referenceFallback.enabled) {
        $skillMd = Join-Path $skillRoot "SKILL.md"
        $refs = Get-SkillReferencedPaths -SkillMdPath $skillMd
        foreach ($r in $refs) {
            $target = Join-Path $skillRoot ($r -replace '/', '\')
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $keep.Add(($r -replace '\\', '/')) | Out-Null
            }
        }
    }

    # Copy kept files preserving relative structure.
    foreach ($rel in $keep) {
        $srcFile = Join-Path $skillRoot ($rel -replace '/', '\')
        $destFile = Join-Path $SkillDest ($rel -replace '/', '\')
        $destDir = Split-Path $destFile -Parent
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }
        Copy-Item -LiteralPath $srcFile -Destination $destFile -Force
    }

    return $keep.Count
}

# Iterate every immediate sub-directory under .claude/skills and copy by rules.
function Copy-SkillsByWhitelist {
    param(
        [string]$SrcRoot,
        [string]$DestRoot,
        $Whitelist
    )
    if (-not (Test-Path $DestRoot)) {
        New-Item -ItemType Directory -Force -Path $DestRoot | Out-Null
    }
    $skills = Get-ChildItem -Path $SrcRoot -Directory -Force
    $totalKept = 0
    foreach ($s in $skills) {
        $destSkillDir = Join-Path $DestRoot $s.Name
        $totalKept += (Copy-SingleSkill -SkillSrc $s.FullName -SkillDest $destSkillDir -Whitelist $Whitelist)
    }
    Write-Host ("  whitelist kept {0} files across {1} skills" -f $totalKept, $skills.Count)
}

# -----------------------------------------------------------------------------


# 1. Locate project root
if (-not $Root) {
    try { $Root = (git rev-parse --show-toplevel 2>$null) } catch {}
    if (-not $Root) { $Root = (Get-Location).Path }
}
$Root = $Root.Trim()
Set-Location $Root

$configPath = ".claude\skills\pack\packaging.config.json"
if (-not (Test-Path $configPath)) {
    Write-Error "Missing packaging config: $configPath"
    exit 1
}

$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

$staging  = $config.staging
$artifact = $config.artifact
$excludes = @($config.excludes)
$readmeBanner = $null

# 1.5. Apply share mode overrides
if ($Mode -eq "share") {
    if (-not $config.shareMode) {
        Write-Error "Mode 'share' requested but shareMode block missing in config."
        exit 1
    }
    $artifact = $config.shareMode.artifact
    $readmeBanner = $config.shareMode.readmeBanner

    # Drop excludes listed in shareMode.excludesOverride
    $drop = @($config.shareMode.excludesOverride)
    $excludes = @($excludes | Where-Object { $drop -notcontains $_ })

    # Auto-append artifact name to .gitignore (HARD requirement for share mode)
    $gitignorePath = ".gitignore"
    $needAppend = $true
    if (Test-Path $gitignorePath) {
        $gi = Get-Content $gitignorePath -Raw -Encoding UTF8
        if ($gi -match [regex]::Escape($artifact)) { $needAppend = $false }
    }
    if ($needAppend) {
        Write-Host "[SHARE MODE] Appending '$artifact' to .gitignore"
        $line = "`r`n# share-mode artifact (contains local credentials, never commit)`r`n$artifact`r`n"
        Add-Content -Path $gitignorePath -Value $line -Encoding UTF8
    }
}

# 2. Pre-check: design-system.md reachable
$designSrc = $null
foreach ($s in $config.sources) {
    if ($s.dest -eq "design-system.md") {
        $designSrc = $s.src -replace '^~', $env:USERPROFILE
        break
    }
}
if ($designSrc -and -not (Test-Path $designSrc)) {
    Write-Error "design-system.md not found at: $designSrc. Place it under ~/.claude/ first."
    exit 1
}

Write-Host "[PACK BUILD]"
Write-Host ("Root    : {0}" -f $Root)
Write-Host ("Mode    : {0}" -f $Mode)
Write-Host ("Artifact: {0}" -f $artifact)
Write-Host ""

# 3. Clean staging
Write-Host -NoNewline "Cleaning staging ... "
if (Test-Path $staging) {
    Remove-Item -Recurse -Force $staging -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $staging | Out-Null
Write-Host "OK"

# 4. Copy sources
Write-Host -NoNewline ("Copying sources ({0} entries) ... " -f $config.sources.Count)
foreach ($src in $config.sources) {
    $srcPath = $src.src -replace '^~', $env:USERPROFILE
    $destPath = Join-Path $staging $src.dest

    $destDir = Split-Path $destPath -Parent
    if ($destDir -and -not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    }

    if ($src.type -eq "copy" -or $src.type -eq "template") {
        if (-not (Test-Path $srcPath)) {
            Write-Error "Source file missing: $srcPath (dest: $($src.dest))"
            exit 1
        }
        Copy-Item -LiteralPath $srcPath -Destination $destPath -Force
    } elseif ($src.type -eq "copyDir") {
        if (-not (Test-Path $srcPath)) {
            Write-Error "Source directory missing: $srcPath"
            exit 1
        }
        if ($src.dest -eq "skills" -and $config.skillsWhitelist) {
            Copy-SkillsByWhitelist -SrcRoot $srcPath -DestRoot $destPath -Whitelist $config.skillsWhitelist
        } else {
            Copy-Item -LiteralPath $srcPath -Destination $destPath -Recurse -Force
        }
    } else {
        Write-Error "Unknown source type: $($src.type)"
        exit 1
    }
}
Write-Host "OK"

# 4.5. Inject README banner in share mode
if ($Mode -eq "share" -and $readmeBanner) {
    $readmePath = Join-Path $staging "README.md"
    if (Test-Path $readmePath) {
        $original = Get-Content $readmePath -Raw -Encoding UTF8
        $merged = $readmeBanner + "`r`n" + $original
        Set-Content -Path $readmePath -Value $merged -Encoding UTF8 -NoNewline
        Write-Host "Injected share-mode README banner"
    }
}

# 5. Apply exclude patterns
Write-Host -NoNewline ("Applying excludes ({0} rules) ... " -f $excludes.Count)
$removed = 0
foreach ($pat in $excludes) {
    $hits = Get-ChildItem -Path $staging -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $pat }
    foreach ($h in $hits) {
        if (Test-Path $h.FullName) {
            Remove-Item -LiteralPath $h.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }
}
Write-Host ("removed {0} items" -f $removed)

# 6. Build zip
Write-Host -NoNewline "Compressing zip ... "
if (Test-Path $artifact) {
    Remove-Item -LiteralPath $artifact -Force
}
$stagingContents = Get-ChildItem -Path $staging -Force
Compress-Archive -Path $stagingContents.FullName -DestinationPath $artifact -CompressionLevel Optimal -Force
Write-Host "OK"

# 7. Summary
$size = (Get-Item $artifact).Length / 1MB
$fileCount = (Get-ChildItem -Path $staging -Recurse -Force -File).Count

Write-Host ""
Write-Host ("Artifact : {0}" -f $artifact)
Write-Host ("Size     : {0:N2} MB" -f $size)
Write-Host ("Files    : {0}" -f $fileCount)
Write-Host ""

# 8. Sensitive file quick scan (skip token-cache in share mode since it is intentional)
$sensitivePatterns = @("*.token-cache.json", "results.tsv", "*.bak-*", ".DS_Store")
if ($Mode -eq "share") {
    $sensitivePatterns = $sensitivePatterns | Where-Object { $_ -ne "*.token-cache.json" }
    Write-Host "Sensitive file scan (share mode, token-cache allowed) ..."
} else {
    Write-Host "Sensitive file scan ..."
}
$sensitiveHits = @()
foreach ($pat in $sensitivePatterns) {
    $found = Get-ChildItem -Path $staging -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $pat }
    foreach ($f in $found) {
        $rel = $f.FullName.Substring($staging.Length).TrimStart('\','/')
        $sensitiveHits += $rel
    }
}
if ($sensitiveHits.Count -gt 0) {
    Write-Host "FAIL: sensitive files still present in staging:"
    foreach ($h in $sensitiveHits) { Write-Host "  - $h" }
    Write-Host "Check packaging.config.json excludes."
    exit 2
}
Write-Host "OK - no sensitive files in staging"

# 9. Size limit
$maxMB = $config.constraints.maxSizeMB
if ($maxMB -and $size -gt $maxMB) {
    Write-Host ("WARN: size {0:N2} MB exceeds cap {1} MB" -f $size, $maxMB)
}

# 10. Share-mode post-build safety: ensure git does not track the artifact
if ($Mode -eq "share") {
    Write-Host ""
    Write-Host "Share-mode post-build safety checks ..."
    $tracked = $null
    try { $tracked = (git ls-files --error-unmatch $artifact 2>$null) } catch {}
    if ($tracked) {
        Write-Host "FAIL: '$artifact' is currently tracked by git."
        Write-Host "      Run: git rm --cached $artifact"
        Write-Host "      Then ensure .gitignore contains: $artifact"
        exit 3
    }
    $status = $null
    try { $status = (git status --porcelain $artifact 2>$null) } catch {}
    if ($status) {
        Write-Host "FAIL: '$artifact' appears in 'git status'. .gitignore may not have taken effect."
        Write-Host "      Output: $status"
        exit 3
    }
    Write-Host "OK - artifact is git-ignored"

    Write-Host ""
    Write-Host "=================================================================="
    Write-Host "WARNING: SHARE-MODE ARTIFACT CONTAINS LOCAL CREDENTIALS"
    Write-Host "------------------------------------------------------------------"
    Write-Host "  - DO NOT commit"
    Write-Host "  - DO NOT push to any remote"
    Write-Host "  - DO NOT redistribute"
    Write-Host "  Deliver out-of-band to the intended recipient only."
    Write-Host "=================================================================="
}

Write-Host ""
Write-Host "Next: run /pack check for full zip-content validation."
