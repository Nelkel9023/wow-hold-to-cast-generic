$ErrorActionPreference = 'Continue'
$env:GH_PROMPT_DISABLED = '1'
$env:GH_NO_UPDATE_NOTIFIER = '1'

function RunGh([string[]]$ghArgs, [int]$secs = 90) {
    $o = Join-Path $env:TEMP 'gh_o.txt'
    $e = Join-Path $env:TEMP 'gh_e.txt'
    Remove-Item $o, $e -ErrorAction SilentlyContinue
    $p = Start-Process -FilePath 'gh' -ArgumentList $ghArgs -NoNewWindow -PassThru `
        -RedirectStandardOutput $o -RedirectStandardError $e
    if (-not $p.WaitForExit($secs * 1000)) {
        try { $p.Kill() } catch {}
        "TIMEOUT ($secs s): gh $($ghArgs -join ' ')"
        return
    }
    "EXIT $($p.ExitCode): gh $($ghArgs -join ' ')"
    Get-Content $o, $e -ErrorAction SilentlyContinue | Where-Object { $_.Trim() }
}

"=== repo states"
RunGh @('repo', 'view', 'Nelkel9023/wow-hold-to-cast', '--json', 'name,visibility,url,description')
RunGh @('repo', 'view', 'Nelkel9023/wow-hold-to-cast-whitemane', '--json', 'name,visibility,url')

$src = 'C:\Games\HoldToCast'
Remove-Item (Join-Path $src '_publish.ps1') -ErrorAction SilentlyContinue
git -C $src rm --cached _publish.ps1 2>&1 | Out-String

@'
build/*
!build/build.ps1
third_party/
tools/
*.dll
*.log
*.obj
*.pdb
'@ | Set-Content -Path (Join-Path $src '.gitignore') -Encoding utf8 -NoNewline

git -C $src add -A 2>&1 | Out-String
git -C $src -c user.name='Nelkel9023' -c user.email='Nelkel9023@users.noreply.github.com' commit -m 'fix: track build/build.ps1, drop publish helper' 2>&1 | Out-String
git -C $src push origin main 2>&1 | Out-String

"=== tracked files in HEAD"
git -C $src ls-tree -r HEAD --name-only 2>&1
"=== log"
git -C $src log --oneline -3 2>&1
"=== status"
git -C $src status --short 2>&1
"DONE"
