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
        return $false
    }
    "EXIT $($p.ExitCode): gh $($ghArgs -join ' ')"
    Get-Content $o, $e -ErrorAction SilentlyContinue | Where-Object { $_.Trim() }
    return ($p.ExitCode -eq 0)
}

"=== 1. make wow-hold-to-cast private"
RunGh @('repo', 'edit', 'Nelkel9023/wow-hold-to-cast', '--visibility', 'private', '--accept-visibility-change-consequences') | Out-Null

"=== 2. rename to wow-hold-to-cast-whitemane"
RunGh @('repo', 'rename', 'wow-hold-to-cast-whitemane', '--repo', 'Nelkel9023/wow-hold-to-cast', '--yes') | Out-Null

"=== 3. create + push public generic repo"
$src = 'C:\Games\HoldToCast'
if (-not (Test-Path (Join-Path $src '.git'))) {
    git -C $src init -b main 2>&1 | Out-String
}
git -C $src add -A 2>&1 | Out-String
git -C $src -c user.name='Nelkel9023' -c user.email='Nelkel9023@users.noreply.github.com' commit -m 'Initial commit: standalone hold-to-cast proxy for WoW 3.3.5a (build 12340)' 2>&1 | Out-String

RunGh @('repo', 'create', 'Nelkel9023/wow-hold-to-cast', '--public', '--source', $src,
    '--remote', 'origin', '--push',
    '--description', 'Hold an action-bar key to repeat its cast - standalone dinput8.dll proxy for WoW 3.3.5a (build 12340)') | Out-Null

"=== 4. topics"
RunGh @('repo', 'edit', 'Nelkel9023/wow-hold-to-cast', '--add-topic', 'world-of-warcraft,wotlk,3.3.5a,addon,minhook,proxy-dll') | Out-Null

"=== final state"
RunGh @('repo', 'list', 'Nelkel9023', '--limit', '20', '--json', 'name,visibility,url') | Out-Null
"DONE"
