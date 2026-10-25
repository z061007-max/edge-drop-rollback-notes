# 公开资料的隐私处理

本仓库使用重新编写的文档及通用命令示例，不对原始用户目录进行打包或同步。

## 明确排除

- 微软账号、邮箱、登录凭据、Cookie、令牌。
- User Data、Local State、Login Data、Web Data、History、Sessions 等浏览器资料。
- 书签、下载历史、Drop 传输内容、OneDrive 文件。
- 原始安装日志、备份日志、截图、完整聊天记录。
- 本机用户名、绝对个人路径、设备名、用户 SID、设备专属任务标识。
- 安装包、可执行文件、压缩包和其他二进制备份。

## 发布方法

只发布根目录的 README.md、ROLLBACK.md、TROUBLESHOOTING.md、INSTALLER.md、PRIVACY.md、.gitignore，以及 oneclick/ 中人工编写的两个 PowerShell 脚本、两个 CMD 启动文件和 README.md。MSI 和本地运行生成的任何备份都不在公开名单中。公开材料没有从浏览器资料中提取账号信息。

发布前检查文件名单、文本内容及可能的用户名、邮箱、凭据模式。该检查不是对以后提交内容的自动保证；后续 Issue、附件和提交也应独立审查。

GitHub 仓库所属账号、公开个人资料及公开活动会按 GitHub 平台规则显示。这与微软账号和本机浏览器资料不同；本仓库不承诺匿名发布。

请勿在 Issue 中上传原始日志或个人浏览器备份。描述问题时只提供必要的版本、退出码和脱敏的少量错误字段。
