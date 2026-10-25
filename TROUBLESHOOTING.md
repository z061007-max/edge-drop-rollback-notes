# 排错记录（人工重写，不是原始日志）

## MSI 返回成功，文件却没有变化

本次观察到以下字段，已去除用户路径、设备信息和时间戳：

```text
ProductVersion = 151.0.4129.107
ALLOWDOWNGRADE = 1
ProductState = 5
Skipping action: DoInstall (condition is false)
Configuration completed successfully.
MainEngineThread is returning 0
```

实际 msedge.exe 仍为 156.0.4314.42。安装包的 DoInstall、BuildInstallCommand 等动作包含已安装组件与 REINSTALL 的条件，因此下一次加入 REINSTALL=ALL，运行后返回 0 且实际文件变为 151.0.4129.107。

不能把 MSI 日志中的 RollbackInfo、DisableRollback 等通用事务字段直接当作浏览器版本回退的成功证据。

## 服务停止不等于所有更新入口都被关闭

本次两个更新服务和两个常规任务已禁用，但 MicrosoftEdgeUpdateBrowserReplacementTask 仍为 Ready。Ready 表示可触发，不单独证明它导致了自动升级。

关闭该任务后重装成功；之后打开“关于”页面仍触发了更新。安装或修复也可能改变更新组件状态，应复查而不是永久相信之前的输出。

## new_msedge.exe 是待替换程序，不只是下载缓存

本次观察：

```text
msedge.exe      151.0.4129.107
new_msedge.exe  156.0.4314.42
```

另有 new_msedge_proxy.exe 和 new_pwahelper.exe。停止更新进程后，将这三个文件移出 Application 目录并保留本地备份；未删除用户资料、151 版本目录、156 版本目录或 EdgeUpdate 目录。

这是一次临时排错操作，不是微软支持的完整“撤销更新”接口。移动文件可能使更新状态不一致，不能保证撤销安装器的其他待处理动作。因此本仓库不提供一键删除缓存、永久禁更或任意恢复这些文件的脚本。

如果出现异常，不要在版本已经改变后把旧的暂存文件盲目移回去。优先使用签名有效的官方安装程序修复。正常重新打开浏览器、系统重启和联网后的行为需要分别验证。

## 本次结论的范围

使用者确认回退后 Drop 可用，并报告移走待替换文件后仍停留在 151。这是单机结果；未证明新版功能变化原因、服务端行为或长期兼容性。
