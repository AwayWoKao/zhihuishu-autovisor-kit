<#
  setup.ps1 —— 智慧树刷课工具包 一键部署
  ------------------------------------------------------------
  作用: 从官方 Release 下载 Autovisor(作者 CXRunfree), 解压到本目录下的 Autovisor 文件夹,
        并把启动器(启动刷课.bat / add-course.ps1)与配置模板一并放好。
  用法: 右键本文件 -> "使用 PowerShell 运行"
        或:  powershell -ExecutionPolicy Bypass -File setup.ps1
  参数:  -TargetDir <路径>   自定义安装目录(默认 <脚本目录>\Autovisor)
         -Force             目标目录已存在时, 先清空再部署
#>
param(
  [string]$TargetDir = '',
  [switch]$Force
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $TargetDir) { $TargetDir = Join-Path $root 'Autovisor' }

Write-Host ''
Write-Host '======== 智慧树刷课工具包 · 部署 ========' -ForegroundColor Cyan
Write-Host ('安装目录: ' + $TargetDir)

# ---------- 1. 解析下载地址(优先最新版, 失败则用内置固定版本) ----------
$fallbackVer = '3.18.4'
$assetName   = "Autovisor-$fallbackVer-windows-amd64.zip"
$url         = "https://github.com/CXRunfree/Autovisor/releases/download/$fallbackVer/$assetName"

try {
  $rel = Invoke-RestMethod 'https://api.github.com/repos/CXRunfree/Autovisor/releases/latest' `
         -Headers @{ 'User-Agent' = 'zhihuishu-kit-setup' } -TimeoutSec 20
  $a = $rel.assets | Where-Object { $_.name -like '*windows-amd64.zip' } | Select-Object -First 1
  if ($a) {
    $assetName = $a.name
    $url       = $a.browser_download_url
    Write-Host ('获取到最新版本: ' + $rel.tag_name) -ForegroundColor Green
  }
} catch {
  Write-Host ('获取最新版本失败(可能是网络或 API 限流), 改用内置版本 ' + $fallbackVer) -ForegroundColor Yellow
}

$sources = @(
  $url,
  ('https://ghfast.top/' + $url),
  ('https://gh-proxy.com/' + $url),
  ('https://ghproxy.net/' + $url)
)

# ---------- 2. 下载(逐个源回退) ----------
$zip = Join-Path $env:TEMP $assetName
$ok  = $false
foreach ($s in $sources) {
  Write-Host ''
  Write-Host ('尝试下载: ' + $s)
  try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest $s -OutFile $zip -TimeoutSec 900
    $sizeMB = [math]::Round((Get-Item $zip).Length / 1MB, 1)
    Write-Host ('  下载完成: ' + $sizeMB + ' MB') -ForegroundColor Green
    if ((Get-Item $zip).Length -gt 20MB) { $ok = $true; break }
  } catch {
    Write-Host '  该源失败, 换下一个' -ForegroundColor DarkYellow
  }
}
if (-not $ok) {
  Write-Host ''
  Write-Host '所有下载源都失败了。请手动从下面地址下载后解压到安装目录:' -ForegroundColor Red
  Write-Host '  https://github.com/CXRunfree/Autovisor/releases'
  Read-Host '按回车退出' | Out-Null
  exit 1
}

# ---------- 3. 解压 ----------
if (Test-Path $TargetDir) {
  if ($Force) {
    Write-Host '目标目录已存在, -Force 指定: 先清空' -ForegroundColor Yellow
    Get-ChildItem $TargetDir -Force | Where-Object { $_.Name -notin @('config.ini', 'data', 'logs') } |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  } else {
    Write-Host '目标目录已存在, 将覆盖程序文件(配置与登录凭证保留)' -ForegroundColor Yellow
  }
} else {
  New-Item -ItemType Directory $TargetDir -Force | Out-Null
}
Expand-Archive $zip -DestinationPath $TargetDir -Force
Remove-Item $zip -Force -ErrorAction SilentlyContinue

# ---------- 4. 放入启动器与配置 ----------
Copy-Item (Join-Path $root 'add-course.ps1')      $TargetDir -Force
Copy-Item (Join-Path $root '启动刷课.bat')         $TargetDir -Force
Copy-Item (Join-Path $root 'README.md')           $TargetDir -Force -ErrorAction SilentlyContinue
$cfg = Join-Path $TargetDir 'config.ini'
if (-not (Test-Path $cfg)) {
  Copy-Item (Join-Path $root 'config.ini.example') $cfg -Force
  Write-Host '已生成 config.ini (首次使用留空即可, 启动后手动登录一次)' -ForegroundColor Green
} else {
  Write-Host '检测到已有 config.ini, 保留你原来的配置'
}

Write-Host ''
Write-Host '======== 部署完成 ========' -ForegroundColor Green
Write-Host ('1. 打开目录: ' + $TargetDir)
Write-Host '2. 浏览器登录智慧树, 打开课程视频页, 复制地址栏链接'
Write-Host '3. 双击 启动刷课.bat  ->  按提示回车启动'
Write-Host ''
Write-Host '首次运行会自动下载运行依赖(约100MB)并需要在浏览器里手动登录一次'
Write-Host '注意: 刷课时不要最小化浏览器窗口, 电脑不要进入睡眠'
Read-Host '按回车退出' | Out-Null
