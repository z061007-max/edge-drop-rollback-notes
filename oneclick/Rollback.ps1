param([switch]$LibraryOnly)

function Get-RollbackArguments([string]$Msi,[string]$Log) {
    '/i "{0}" REINSTALL=ALL REINSTALLMODE=vomus ALLOWDOWNGRADE=1 /passive /norestart /L*v "{1}"' -f $Msi,$Log
}
function Test-InstallResult([int]$Code,[string]$Version) {
    ($Code -in @(0,3010)) -and ($Version -eq '151.0.4129.107')
}
if ($LibraryOnly) { return }
$ErrorActionPreference = 'Stop'
$state = $null
try {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath)
        exit
    }
    $msi = Join-Path $PSScriptRoot 'MicrosoftEdgeEnterpriseX64.msi'
    Write-Host '[1/5] 检查安装包、数字签名及当前浏览器……'
    if (!(Test-Path -LiteralPath $msi)) { throw '请完整解压工具包；MSI 必须与本脚本位于同一文件夹。' }
    $expected = 'B75F03B87DFB0CBC85BA2C0858C632511B17355F42563A43FCA5368100FFE0FE'
    if ((Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash -ne $expected) { throw '安装包校验不匹配，已停止。本工具只接受指定的 151 x64 安装包。' }
    $sig = Get-AuthenticodeSignature -LiteralPath $msi
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') { throw '微软数字签名验证未通过，已停止。' }
    $exe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (!(Test-Path -LiteralPath $exe)) { throw '未找到本工具支持的系统级 Edge 安装路径。' }
    $currentVersion = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    Write-Host "当前文件版本：$currentVersion；目标：151.0.4129.107"
    if($currentVersion -eq '151.0.4129.107') {
        Write-Host '当前已经是目标版本，不重复安装。可在 Edge 中访问 edge://version 核对运行版本。'
        Write-Host '这个检查不代表已取消其他待处理更新。'
        Read-Host '按回车关闭' | Out-Null
        exit 0
    }
    Write-Host '本工具临时回退到 Edge 151。旧版缺少后续安全修复。'
    Write-Host '请保存网页内容并完全退出 Edge（包括后台进程）。'
    Write-Host '不强关浏览器、不删除更新文件、不保证 Drop 长期可用。'
    if ((Read-Host '输入 YES 确认备份浏览资料并安装 151；其他输入取消') -cne 'YES') { exit 0 }
    if (Get-Process msedge -ErrorAction SilentlyContinue) { throw 'Edge 仍在运行，请完全退出后重试。' }
    $base = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'EdgeRollbackLocal'
    $run = Join-Path $base (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
    New-Item -ItemType Directory -Path $run -Force | Out-Null
    Write-Host "本地备份和日志位置：$run"
    Write-Host '此目录含个人浏览资料，请勿上传或分享。'
    $data = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
    if (Test-Path -LiteralPath $data) {
        Write-Host '[2/5] 正在备份浏览资料，请等待……'
        & robocopy.exe $data (Join-Path $run 'User Data') /E /XJ /R:1 /W:1 /NFL /NDL /NP "/LOG:$run\backup.log" | Out-Host
        if ($LASTEXITCODE -ge 8) { throw '浏览资料备份失败，尚未开始安装。' }
    }
    Write-Host '[3/5] 保存更新设置并临时暂停已有更新服务和任务……'
    $services = @(Get-CimInstance Win32_Service | Where-Object { $_.Name -in @('edgeupdate','edgeupdatem') } | Select-Object Name,StartMode,State)
    $tasks = @(Get-ScheduledTask | Where-Object { $_.TaskName -like 'MicrosoftEdgeUpdate*' } | ForEach-Object {
        [pscustomobject]@{TaskName=$_.TaskName;TaskPath=$_.TaskPath;Enabled=[bool]$_.Settings.Enabled}
    })
    $state = Join-Path $run 'update-state.clixml'
    [pscustomobject]@{Services=$services;Tasks=$tasks} | Export-Clixml -LiteralPath $state
    foreach($t in $tasks) {
        Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath | Out-Null
        Stop-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath
    }
    foreach($s in $services) {
        Set-Service -Name $s.Name -StartupType Disabled
        Stop-Service -Name $s.Name -Force
    }
    Get-Process MicrosoftEdgeUpdate -ErrorAction SilentlyContinue | Stop-Process -Force
    $log = Join-Path $run 'install.log'
    Write-Host '[4/5] 正在安装，请勿按 Ctrl+C 或关闭窗口……'
    $p = Start-Process "$env:WINDIR\System32\msiexec.exe" -ArgumentList (Get-RollbackArguments $msi $log) -Wait -PassThru
    $version = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    Write-Host "[5/5] 安装退出码：$($p.ExitCode)；实际文件版本：$version"
    if (!(Test-InstallResult $p.ExitCode $version)) { throw '回退校验未通过。请在本地查看 install.log，不要公开原始日志。' }
    Write-Host '文件版本校验通过：151.0.4129.107。请打开 edge://version 核对运行版本并测试 Drop。'
    Write-Host '不要使用“关于”页面检查版本，该页面可能触发更新。'
    Write-Host '更新服务和任务目前临时暂停，不是永久锁版。'
    Write-Host "测试结束后双击恢复更新设置入口，选择：$state"
    if($p.ExitCode -eq 3010) { Write-Host '安装器要求重启。请先保存工作并检查待更新状态，不会自动重启。' }
    Read-Host '按回车完成' | Out-Null
} catch {
    Write-Host "已停止：$($_.Exception.Message)" -ForegroundColor Red
    if($state -and (Test-Path -LiteralPath $state)) {
        Write-Host '操作失败，正在尝试恢复捕获的更新设置……'
        try { & (Join-Path $PSScriptRoot 'Restore-Updates.ps1') -StateFile $state -NoPause } catch { Write-Host "恢复设置也遇到问题：$($_.Exception.Message)" }
    }
    Read-Host '按回车关闭' | Out-Null
    exit 1
}
