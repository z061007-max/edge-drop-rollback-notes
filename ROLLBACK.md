# 回退操作参考

以下为人工检查后执行的命令示例，不是无人值守脚本。示例省略了本机路径和个人信息；不要把占位路径原样执行。

## 1. 使用正确的命令窗口

以管理员身份打开 PowerShell。如果当前是管理员 CMD，先输入 `powershell`。默认 PowerShell 提示符以 `PS` 开头；使用主题时提示符可能不同。CMD 不支持 `$变量`、`Get-Process` 等 PowerShell 语法。

## 2. 准备和备份

- 从微软官方下载目标版本 MSI，核对数字签名、架构和包版本。
- 将书签等重要资料备份到仅自己可访问的位置；同步并不能替代所有本地备份。
- 保存网页内容，退出浏览器，并用 `Get-Process msedge -ErrorAction SilentlyContinue` 检查后台进程。
- 根据官方回退文档临时控制更新，并事先记录服务、计划任务和策略的原状态。不同设备的企业管理策略和权限可能不同。
- 不要用删除 EdgeUpdate 目录、修改权限或破坏更新器的方式代替更新管理。

## 3. 本次案例中生效的 MSI 重装参数

常规安装发现 MSI 已注册、但浏览器文件版本不同，且日志明确显示跳过 DoInstall 时，本次案例使用了下列参数。不是所有安装失败都适合用重装解决。

```powershell
$msi = 'D:\Installers\MicrosoftEdgeEnterpriseX64.msi' # 改为自己的安装包位置
$log = Join-Path $env:TEMP ('edge-rollback-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
if (!(Test-Path -LiteralPath $msi)) { throw '安装包不存在' }
if (Get-Process msedge -ErrorAction SilentlyContinue) { throw '请先退出 Edge' }
$arguments = "/i `"$msi`" REINSTALL=ALL REINSTALLMODE=vomus ALLOWDOWNGRADE=1 /passive /norestart /L*v `"$log`""
$process = Start-Process "$env:WINDIR\System32\msiexec.exe" -ArgumentList $arguments -Wait -PassThru
Write-Host "安装退出码：$($process.ExitCode)"
Write-Host "日志仅供本地检查：$log"
```

`ALLOWDOWNGRADE=1` 允许降级；本案例安装包的执行条件在已安装状态下需要 `REINSTALL` 才会进入安装动作。`REINSTALLMODE=vomus` 选择重新缓存安装包及相应重装行为，不代表所有文件都会被强制覆盖。

## 4. 验证，不能只看退出码

```powershell
$exe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (Test-Path -LiteralPath $exe) {
    (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
}
```

安装路径可能不同。退出码 0 只说明安装事务报告成功；3010 通常表示成功但需要重启，应先保存工作并检查更新状态。其他退出码应先查看日志，不要反复盲目重装。

启动浏览器后访问 `edge://version` 核对运行版本，测试 Drop 文字和小文件传输。验证版本时不要使用会触发更新检查的“关于”页面。

## 5. 结束测试与恢复

按事先保存的状态恢复被修改的服务启动类型、计划任务和更新策略。不要猜测所有机器的默认设置，也不要把本来禁用的企业任务一律启用。

如果没有记录原状态，应先核查设备管理策略；必要时使用微软当前正式版安装程序修复更新组件。确认能正常检查更新后，再判断是否清理本地备份。

本次对 151 的回退已成功，不意味着未来任意新版本、任意系统都能无损回退。保留已验证安装包和离线备份，但不要公开个人备份。
