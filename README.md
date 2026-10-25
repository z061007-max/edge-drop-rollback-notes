# Edge Drop 回退排错记录

## 快速开始

[⬇ 下载完整回退包（含 151 MSI，预览版）](https://github.com/z061007-max/edge-drop-rollback-notes/releases/download/v0.2.0-preview/EdgeDrop-151-Windows-x64.zip)

下载 → 完整解压 → 保存工作并退出 Edge → 双击 **开始回退.cmd** → 管理员确认。测试完成可双击 **恢复更新设置.cmd**。已是 151 时不会重复安装。

完整包没有账号、浏览资料或原始日志；本地运行产生的备份不要分享。新一键工具尚未完成真实安装全流程测试。

> **使用反馈（2026-10-25）：Windows 11 家庭版，回退到 Edge 151.0.4129.107 后，使用者反馈目前使用无问题，Drop 仍可正常传输。** 这是本次个人环境的反馈，不代表所有设备都适用，也不代表 Drop 将来一直可用。

用于分享一次 Windows 上 Microsoft Edge Drop 传输问题的排查过程，不是微软官方修复方案，也不是长期冻结浏览器版本的工具。

## 本次观察

| 项目 | 结果 |
| --- | --- |
| 操作系统 | Windows 11 家庭版（使用者提供） |
| 最近反馈日期 | 2026-10-25 |
| 起始浏览器版本 | 156.0.4314.42 |
| 回退目标 | 151.0.4129.107，Windows x64 |
| 普通 MSI 安装 | 返回 0，但实际程序仍为 156 |
| 加入重装参数后 | 返回 0，实际程序版本变为 151 |
| 当前使用情况 | 截至反馈日期，使用者报告使用无问题，Drop 能够正常传输 |
| 后续更新 | 打开“关于”页触发更新，出现待替换的新版程序 |
| 临时处理 | 将三个 new_*.exe 文件移到本地备份；之后使用者报告仍停留在 151 |

这是一台机器上的案例，不能据此认定所有 156 都不能使用 Drop，或所有 151 都可以使用。没有独立验证长期锁版效果，也没有完整验证系统重启后的行为。

## 阅读顺序

1. [回退操作参考](ROLLBACK.md)
2. [排错证据与待更新文件](TROUBLESHOOTING.md)
3. [安装包来源和校验](INSTALLER.md)
4. [公开内容与隐私边界](PRIVACY.md)

## 重要说明

- 旧浏览器缺少后续安全修复，只适合临时验证。回退可能导致浏览数据丢失。
- 请先保存工作并在本地备份浏览器资料。备份和安装日志可能包含敏感数据，不要上传到 Issue 或仓库。
- 本仓库不包含账号、Cookie、用户资料目录、原始日志、截图或浏览器二进制文件。
- 排错过程曾暂停更新；问题解决后应恢复正常更新。恢复更新可能使浏览器再次升到新版本。
- “已是最新版本”或“点击更新没有变化”不是成功锁版的证据。

## 官方资料

- [Microsoft Edge 回退说明](https://learn.microsoft.com/en-us/deployedge/edge-learnmore-rollback)
- [Windows Installer REINSTALLMODE](https://learn.microsoft.com/en-us/windows/win32/msi/reinstallmode)
- [Microsoft Edge 更新策略](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-update-policies)
- [Microsoft Edge 企业版下载](https://www.microsoft.com/en-us/edge/business/download)

## 双击回退工具

参见 [oneclick 使用说明](oneclick/README.md)。完整解压工具目录，把匹配的官方 MSI 放到同一目录，再双击 Start-Rollback.cmd。工具自动检查安装包、备份、临时暂停更新并校验版本，仍需要管理员及 YES 确认。Restore-Updates.cmd 用于恢复捕获的更新设置。新工具通过语法与逻辑检查，尚未进行真实安装端到端测试。

**注意区分：上面的成功反馈来自本次实际回退操作，不是新一键工具已完成全流程实测的声明。**

## 交流与建议

欢迎在 [Issues](https://github.com/z061007-max/edge-drop-rollback-notes/issues) 报告使用结果、问题或建议，也可以提交 Pull request 改进文档与工具。
留言请仅提供必要的系统版本、Edge 版本、退出码及脱敏错误片段；不要上传账号、邮箱、Cookie、原始日志或浏览器备份。
