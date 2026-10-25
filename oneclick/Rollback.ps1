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
    if (!(Test-Path -LiteralPath $msi)) { throw 'Place MicrosoftEdgeEnterpriseX64.msi next to this script.' }
    $expected = 'B75F03B87DFB0CBC85BA2C0858C632511B17355F42563A43FCA5368100FFE0FE'
    if ((Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash -ne $expected) { throw 'MSI hash mismatch. This tool accepts only the tested 151 x64 package.' }
    $sig = Get-AuthenticodeSignature -LiteralPath $msi
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') { throw 'Valid Microsoft signature required.' }
    $exe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (!(Test-Path -LiteralPath $exe)) { throw 'Supported system-wide Edge x64 installation not found.' }
    Write-Host 'Temporary Edge 151 rollback. Older versions lack current security fixes.'
    Write-Host 'Save all work and CLOSE Edge, including background processes, before continuing.'
    Write-Host 'This tool does not force-close Edge, delete update files, or guarantee Drop availability.'
    if ((Read-Host 'Type YES to back up local browser data and install 151') -cne 'YES') { exit 0 }
    if (Get-Process msedge -ErrorAction SilentlyContinue) { throw 'Edge is still running. Exit Edge and run again.' }
    $base = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'EdgeRollbackLocal'
    $run = Join-Path $base (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
    New-Item -ItemType Directory -Path $run -Force | Out-Null
    Write-Host "Local backup/log location: $run"
    Write-Host 'NEVER upload this local backup or its logs to GitHub.'
    $data = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
    if (Test-Path -LiteralPath $data) {
        Write-Host 'Backing up browser data. Please wait...'
        & robocopy.exe $data (Join-Path $run 'User Data') /E /XJ /R:1 /W:1 /NFL /NDL /NP "/LOG:$run\backup.log" | Out-Host
        if ($LASTEXITCODE -ge 8) { throw 'Backup failed. Installation has NOT started.' }
    }
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
    Write-Host 'Installing. Do not interrupt...'
    $p = Start-Process "$env:WINDIR\System32\msiexec.exe" -ArgumentList (Get-RollbackArguments $msi $log) -Wait -PassThru
    $version = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    Write-Host "Installer exit code: $($p.ExitCode); actual file version: $version"
    if (!(Test-InstallResult $p.ExitCode $version)) { throw 'Rollback verification failed. Inspect the LOCAL install.log; do not publish it.' }
    Write-Host 'PASS: file version is 151.0.4129.107. Check edge://version and test Drop.'
    Write-Host 'Do NOT use the About page for version checking: it may trigger an update.'
    Write-Host 'Update services/tasks are paused for this temporary test, not permanently locked.'
    Write-Host 'Run Restore-Updates.cmd after testing. It restores the captured state, not guessed defaults.'
    if($p.ExitCode -eq 3010) { Write-Host 'Installer requests a restart. Save work first; inspect pending updates before restarting.' }
    Read-Host 'Press Enter to finish' | Out-Null
} catch {
    Write-Host "STOP: $($_.Exception.Message)" -ForegroundColor Red
    if($state -and (Test-Path -LiteralPath $state)) {
        Write-Host 'Restoring captured update settings after failure...'
        try { & (Join-Path $PSScriptRoot 'Restore-Updates.ps1') -StateFile $state -NoPause } catch { Write-Host "Restore also needs attention: $($_.Exception.Message)" }
    }
    Read-Host 'Press Enter to close' | Out-Null
    exit 1
}
