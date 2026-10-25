# 安装包说明

优先从[微软企业版下载页面](https://www.microsoft.com/en-us/edge/business/download)获取官方安装包。历史版本是否仍提供，以微软当时页面为准。

本案例使用的安装包：

| 字段 | 值 |
| --- | --- |
| 文件名 | MicrosoftEdgeEnterpriseX64.msi |
| 包版本 | 151.0.4129.107 |
| 架构 | Windows x64 |
| 大小 | 213475328 字节 |
| SHA-256 | B75F03B87DFB0CBC85BA2C0858C632511B17355F42563A43FCA5368100FFE0FE |

以上哈希仅标识本案例文件，不替代微软数字签名验证，也不证明当前下载链接会返回相同包。

```powershell
Get-FileHash -LiteralPath 'D:\Installers\MicrosoftEdgeEnterpriseX64.msi' -Algorithm SHA256
Get-AuthenticodeSignature -LiteralPath 'D:\Installers\MicrosoftEdgeEnterpriseX64.msi' |
    Format-List Status, StatusMessage, SignerCertificate
```

本仓库未重新分发微软 MSI、EXE、DLL 或本机待更新文件。它们不是个人浏览数据，但不需要把整套应用程序备份公开，才能分享排错方法。本地已验证安装包应自行保留。
