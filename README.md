# Codex SSH 配置文件（Windows 版）

本工具用于在 Windows 上为远程服务器配置可复用的 SSH 别名，并生成一个 Codex 所需的元数据文件。支持在不同 Windows 账户下使用，只需指定对应的 `.ssh` 目录即可。

该工具**不会存储密码或 Google Authenticator 验证码**。

## 生成的文件

默认情况下，脚本会写入以下两个文件：

```text
%USERPROFILE%\.ssh\config
%USERPROFILE%\.ssh\codex_ssh_profiles.json
config：标准的 OpenSSH 配置文件，用于定义主机别名。

codex_ssh_profiles.json：存储 Codex 的偏好设置，例如是否需要 Google Authenticator，以及 Codex 是否保持连接直到用户主动断开。

在写入新文件前，脚本会自动备份已有文件。

默认配置示例
运行脚本时，默认会写入以下两个主机配置：

text
DL-mjq
  HostName 211.69.xxx.xxx
  Port     22xxx
  User     mjq

HPC-jqmao
  HostName 211.69.xxx.xxx
  Port     22xxx
  User     jqmao
  Google Authenticator 启用
  Codex 保持连接，直到用户请求断开
为当前 Windows 用户运行
在项目目录中打开 PowerShell，执行：

powershell
.\setup_codex_ssh_profiles.ps1
脚本会打印所有即将写入的配置值，并要求你输入 YES 确认。

为其他 Windows 用户运行
显式传入该用户的 .ssh 目录路径：

powershell
.\setup_codex_ssh_profiles.ps1 `
  -SshDir "C:\Users\OtherUser\.ssh"
如果目标目录属于其他用户，请确保当前 PowerShell 具有对该目录的写入权限。

自定义主机参数
所有连接参数都可以通过命令行显式指定：

powershell
.\setup_codex_ssh_profiles.ps1 `
  -DlName "DL-mjq" `
  -DlHost "211.69.xxx.xxx" `
  -DlPort 22xxx `
  -DlUser "mjq" `
  -HpcName "HPC-jqmao" `
  -HpcHost "211.69.xxx.xxx" `
  -HpcPort 22xxx `
  -HpcUser "jqmao" `
  -HpcDefaultRemoteDir "/public/home/youpath/"
如果你已经确认参数无误，并希望跳过交互式确认，可以使用 -Force 参数：

powershell
.\setup_codex_ssh_profiles.ps1 -Force
配置完成后的测试
运行以下命令测试 SSH 别名是否可用：

powershell
ssh DL-mjq
ssh HPC-jqmao
对于 HPC-jqmao 主机，登录时会要求输入 Google Authenticator 动态验证码。Codex 会在验证通过后启动一个持久会话，并在后续操作中复用该会话，直到你主动请求断开连接为止。
