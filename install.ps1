# t3-orchestrator installer (Windows PowerShell 5.1+)
# Copies the T3 orchestration agents + skill into the opencode config dir and
# appends the T3 section to AGENTS.md once. Idempotent. ASCII only.
#
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -File install.ps1 -ConfigDir C:\path\to\opencode
#   powershell -ExecutionPolicy Bypass -File install.ps1 -DryRun

[CmdletBinding()]
param(
  [string]$ConfigDir = "",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Resolve-ConfigDir {
  param([string]$Given)
  if ($Given -ne "") { return $Given }
  if ($env:OPENCODE_CONFIG_DIR -and $env:OPENCODE_CONFIG_DIR -ne "") { return $env:OPENCODE_CONFIG_DIR }
  if ($env:XDG_CONFIG_HOME -and $env:XDG_CONFIG_HOME -ne "") { return (Join-Path $env:XDG_CONFIG_HOME 'opencode') }
  return (Join-Path $HOME '.config\opencode')
}

$src      = $PSScriptRoot
$cfg      = Resolve-ConfigDir -Given $ConfigDir
$stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$marker   = '## T3 Code (global, opencode harness)'
$agents   = @('t3-orchestrator.md', 't3-thread.md', 't3-subagent.md')
$skillDir = 't3-orchestration'

Write-Output "source      : $src"
Write-Output "config dir  : $cfg"
if ($DryRun) { Write-Output "mode        : DRY RUN (nothing is written)" }
Write-Output ""

if (-not (Test-Path $src))        { throw "Source dir not found: $src" }
if (-not (Test-Path "$src\install.ps1")) { throw "Run this from the repo root: $src" }

function Copy-WithBackup {
  param([string]$From, [string]$To)
  if (Test-Path $To) {
    $bak = "$To.bak.$stamp"
    if (-not $DryRun) { Copy-Item $To $bak -Force }
    Write-Output "  backup  $To -> $bak"
  }
  if (-not $DryRun) {
    $parent = Split-Path $To -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Copy-Item $From $To -Force
  }
  Write-Output "  write   $To"
}

Write-Output "agents:"
foreach ($a in $agents) {
  if (-not (Test-Path "$src\agents\$a")) { throw "Missing source agent: $src\agents\$a" }
  Copy-WithBackup -From "$src\agents\$a" -To "$cfg\agents\$a"
}

Write-Output ""
Write-Output "skill:"
Copy-WithBackup -From "$src\skills\$skillDir\SKILL.md" `
  -To "$cfg\skills\$skillDir\SKILL.md"
Copy-WithBackup -From "$src\skills\$skillDir\references\project-agents-template.md" `
  -To "$cfg\skills\$skillDir\references\project-agents-template.md"

Write-Output ""
Write-Output "AGENTS.md:"
$agentsMd = "$cfg\AGENTS.md"
$snippet  = Get-Content "$src\AGENTS.snippet.md" -Raw
$already  = $false
if (Test-Path $agentsMd) {
  $existing = Get-Content $agentsMd -Raw
  if ($existing -match [regex]::Escape($marker)) { $already = $true }
}

if ($already) {
  Write-Output "  skip    T3 section already present in $agentsMd"
} else {
  if (-not $DryRun) {
    if (-not (Test-Path $agentsMd)) { New-Item -ItemType File -Force -Path $agentsMd | Out-Null }
    else { Copy-Item $agentsMd "$agentsMd.bak.$stamp" -Force }
    Add-Content -Path $agentsMd -Value ("`r`n" + $snippet.TrimEnd() + "`r`n")
  }
  Write-Output "  append  T3 section -> $agentsMd"
}

Write-Output ""
if ($DryRun) {
  Write-Output "DRY RUN complete. Re-run without -DryRun to apply."
  exit 0
}

# --- self check -------------------------------------------------------------
$fail = @()
foreach ($a in $agents) { if (-not (Test-Path "$cfg\agents\$a")) { $fail += "missing agent $a" } }
if (-not (Test-Path "$cfg\skills\$skillDir\SKILL.md")) { $fail += "missing SKILL.md" }
if (-not (Test-Path "$cfg\skills\$skillDir\references\project-agents-template.md")) { $fail += "missing project-agents-template.md" }
if (-not (Test-Path $agentsMd)) { $fail += "missing AGENTS.md" }
elseif (-not ((Get-Content $agentsMd -Raw) -match [regex]::Escape($marker))) { $fail += "AGENTS.md marker missing" }

if ($fail.Count -gt 0) {
  Write-Output "CHECK: FAIL"
  $fail | ForEach-Object { Write-Output "  - $_" }
  exit 1
}

Write-Output "CHECK: PASS ($($agents.Count) agents, 2 skill files, AGENTS.md section)"
Write-Output ""
Write-Output "Next:"
Write-Output "  1. Restart opencode (config is not hot-reloaded)."
Write-Output "  2. T3: Settings -> Providers -> enable the 'opencode' instance and sign in."
Write-Output "  3. T3: select agent 't3-orchestrator' and describe a project-scale task."
exit 0
