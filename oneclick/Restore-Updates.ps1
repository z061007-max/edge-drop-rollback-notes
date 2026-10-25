param([string]$StateFile,[switch]$NoPause)
$ErrorActionPreference = 'Stop'
try {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath)
        exit
    }
    if (!$StateFile) {
        $base = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'EdgeRollbackLocal'
        Write-Host '请选择需要恢复的那次回退记录；不读取浏览资料。'
        Write-Host "本地备份根目录：$base"
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Filter = 'Update state (update-state.clixml)|update-state.clixml'
        if(Test-Path -LiteralPath $base) { $picker.InitialDirectory = $base }
        if($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { $picker.Dispose(); exit 0 }
        $StateFile = $picker.FileName
        $picker.Dispose()
    }
    $state = Import-Clixml -LiteralPath $StateFile
    foreach($s in $state.Services) {
        if($s.Name -notin @('edgeupdate','edgeupdatem')) { throw 'Unexpected service in state file.' }
        $mode = switch($s.StartMode) {'Auto' {'Automatic'} 'Manual' {'Manual'} 'Disabled' {'Disabled'} default {throw 'Unexpected startup type'}}
        Set-Service -Name $s.Name -StartupType $mode
        if($s.State -eq 'Running' -and $mode -ne 'Disabled') { Start-Service -Name $s.Name }
        else { Stop-Service -Name $s.Name -Force }
    }
    foreach($t in $state.Tasks) {
        if($t.TaskName -notlike 'MicrosoftEdgeUpdate*') { throw 'Unexpected task in state file.' }
        if($t.Enabled) { Enable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath | Out-Null }
        else { Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath | Out-Null }
    }
    Write-Host '已应用捕获的服务和任务设置。之前就禁用的项目仍保持禁用。'
    Write-Host '本工具未修改注册表策略；不会删除安装器新建的任务。'
    if(!$NoPause) { Read-Host '按回车完成' | Out-Null }
} catch {
    Write-Host "已停止：$($_.Exception.Message)" -ForegroundColor Red
    if(!$NoPause) { Read-Host '按回车关闭' | Out-Null }
    exit 1
}
