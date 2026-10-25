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
        Write-Host 'Select the update-state.clixml from the specific rollback run to restore.'
        Write-Host "Local backup root: $base"
        $StateFile = (Read-Host 'Paste the FULL state file path').Trim('"')
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
    Write-Host 'Captured service/task settings restored. Previously disabled items remain disabled.'
    Write-Host 'No registry policy was changed by this tool. Installer-created tasks are not removed.'
    if(!$NoPause) { Read-Host 'Press Enter to finish' | Out-Null }
} catch {
    Write-Host "STOP: $($_.Exception.Message)" -ForegroundColor Red
    if(!$NoPause) { Read-Host 'Press Enter to close' | Out-Null }
    exit 1
}
