param([string]$Zig = $env:ZIG)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root 'src'
$tp   = Join-Path $root 'third_party'
$out  = Join-Path $root 'build'

if (-not $Zig) {
    $cmd = Get-Command zig -ErrorAction SilentlyContinue
    if ($cmd) { $Zig = $cmd.Source }
}
if (-not $Zig) { throw 'zig not found: put zig on PATH or pass -Zig <path to zig.exe>' }

if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

$mh = Join-Path $tp 'minhook-master'
if (-not (Test-Path $mh)) { throw "MinHook missing: expected $mh (see README)" }

$args = @(
    'cc', '-target', 'x86-windows-gnu', '-O2', '-shared',
    '-o', (Join-Path $out 'dinput8.dll'),
    (Join-Path $src 'proxy_dinput8.c'),
    (Join-Path $src 'holdtocast.c'),
    (Join-Path $mh 'src\hook.c'),
    (Join-Path $mh 'src\buffer.c'),
    (Join-Path $mh 'src\trampoline.c'),
    (Join-Path $mh 'src\hde\hde32.c'),
    '-I', (Join-Path $mh 'include'),
    '-I', (Join-Path $mh 'src')
)

Write-Host "zig: $Zig"
& $Zig @args
if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }
Write-Host "OK -> $out\dinput8.dll"
