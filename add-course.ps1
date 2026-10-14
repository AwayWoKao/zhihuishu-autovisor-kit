# ============================================================
#  智慧树刷课启动器 (add-course.ps1)
#  用法: 双击 启动刷课.bat  (自动读取剪贴板里的课程链接)
#        或命令行: powershell -File add-course.ps1 -Urls <链接1>,<链接2>
# ============================================================
param(
  [string[]]$Urls = @(),
  [switch]$NoPrompt   # 测试用: 不交互, 只保存不启动
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$ErrorActionPreference = 'Stop'
$dir        = $PSScriptRoot
$configPath = Join-Path $dir 'config.ini'

function Pause-Exit([int]$code) {
  if (-not $NoPrompt) { Read-Host '按回车退出' | Out-Null }
  exit $code
}

if (-not (Test-Path $configPath)) {
  Write-Host '[错误] 未找到 config.ini, 请把本脚本放在 Autovisor 同目录' -ForegroundColor Red
  Pause-Exit 1
}

# ---------- 1. 收集课程链接: 参数优先, 其次读剪贴板 ----------
if ($Urls.Count -eq 0) {
  try {
    $clip = Get-Clipboard -Raw -ErrorAction SilentlyContinue
    if ($clip) { $Urls = @($clip -split '\s+' | Where-Object { $_ -match '^https?://' }) }
  } catch { }
}
$valid = @($Urls |
  Where-Object { $_ -match 'zhihuishu\.com/' } |
  Select-Object -Unique)

Write-Host ''
Write-Host '======== 智慧树刷课启动器 ========' -ForegroundColor Cyan

if ($valid.Count -eq 0) {
  Write-Host '没有检测到有效的智慧树课程链接' -ForegroundColor Yellow
  Write-Host ''
  Write-Host '怎样获取课程链接:'
  Write-Host '  1. 浏览器登录智慧树, 打开目标课程的视频播放页'
  Write-Host '     (地址形如 studyvideoh5.zhihuishu.com/stuStudy?recruitAndCourseId=...)'
  Write-Host '  2. 复制地址栏完整链接'
  Write-Host '  3. 再双击 启动刷课.bat, 会自动读取剪贴板并追加'
  Write-Host ''
  Write-Host '多门课一起刷: 多个链接分行粘贴到剪贴板, 一次全部加入, 程序会按顺序刷完'
  Pause-Exit 0
}

# ---------- 2. 合并写入 config.ini (自动去重) ----------
$bytes  = [System.IO.File]::ReadAllBytes($configPath)
$strict = New-Object System.Text.UTF8Encoding($false, $true)
try   { $text = $strict.GetString($bytes); $enc = New-Object System.Text.UTF8Encoding($false) }
catch { $enc = [System.Text.Encoding]::GetEncoding('GB18030'); $text = $enc.GetString($bytes) }

$oldLines = @($text -split "\r?\n")
$merged = @()
foreach ($l in $oldLines) {
  if ($l -match '^\s*URL\d+\s*=\s*(\S+)') {
    $u = $Matches[1]
    if ($merged -notcontains $u) { $merged += $u }
  }
}
$newCount = 0
foreach ($u in $valid) {
  if ($merged -notcontains $u) { $merged += $u; $newCount++ }
}

# 丢弃旧的 URL 行(含空槽和 URLn 模板), 然后按清单重排
$out = New-Object System.Collections.Generic.List[string]
foreach ($l in $oldLines) {
  if ($l -match '^\s*URL[a-z0-9]+\s*=') { continue }
  $out.Add($l)
}
for ($i = 0; $i -lt $merged.Count; $i++) { $out.Add("URL$($i + 1) = $($merged[$i])") }

[System.IO.File]::WriteAllText($configPath, ($out -join "`r`n") + "`r`n", $enc)

# ---------- 3. 展示课程清单 ----------
Write-Host ''
Write-Host "当前课程清单 (共 $($merged.Count) 门, 按顺序依次刷完):"
$i = 1
foreach ($u in $merged) { Write-Host "  [$i] $u"; $i++ }
Write-Host ''
if ($newCount -gt 0) { Write-Host "已新增 $newCount 门课程" -ForegroundColor Green }
else                 { Write-Host '链接都已在清单里, 没有新增' -ForegroundColor DarkGray }

# ---------- 4. 启动 / 重启 ----------
$running = Get-Process -Name 'Autovisor' -ErrorAction SilentlyContinue
if ($running) { Write-Host '注意: 检测到 Autovisor 正在运行' -ForegroundColor Yellow }

if ($NoPrompt) { Write-Host '(NoPrompt 模式: 只保存, 不启动)'; exit 0 }

$ans = Read-Host '现在启动/重启刷课? (回车或Y=启动, N=只保存)'
if ($ans -eq '' -or $ans -match '^[Yy]') {
  if ($running) {
    Stop-Process -Name 'Autovisor' -Force
    Start-Sleep -Seconds 3
    Write-Host '已结束旧进程 (残留的浏览器窗口可手动关掉)'
  }
  Start-Process -FilePath (Join-Path $dir 'Autovisor.exe') -WorkingDirectory $dir
  Write-Host ''
  Write-Host '已启动! 注意: 别最小化浏览器窗口; 弹题会自动处理' -ForegroundColor Green
} else {
  Write-Host '已保存. 之后随时双击 Autovisor.exe 即可按清单顺序刷'
}
Pause-Exit 0
