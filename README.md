# 🚀 Push Tools

一键推送工具，让你在任何项目目录中快速推送到 GitHub 或 Docker Hub。

![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash)
![License](https://img.shields.io/badge/License-MIT-blue)
![Platform](https://img.shields.io/badge/Platform-Linux%20|%20macOS-orange)

## ✨ 特性

- 🚀 **一键推送** - 无需记忆复杂命令
- 🔐 **安全登录** - 支持设备代码和 Token 登录
- 📦 **自动创建仓库** - 不存在时自动创建
- 🔒 **可见性选择** - 支持公开/私有仓库
- 🎨 **交互式界面** - 友好的命令行提示
- 🌐 **SSH 友好** - 适合无 GUI 的服务器环境

## 📦 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/jiege6-66/push-tools/master/install.sh | sudo bash
```

或使用 wget：

```bash
wget -qO- https://raw.githubusercontent.com/jiege6-66/push-tools/master/install.sh | sudo bash
```

## 🔧 手动安装

```bash
git clone https://github.com/jiege6-66/push-tools.git
cd push-tools
sudo ./install.sh
```

## 📖 使用方法

### github-push

在任何 Git 项目目录中推送到 GitHub：

```bash
cd /path/to/your/project
github-push
```

功能：
- 🔐 GitHub 登录（设备代码 / Token）
- 📝 输入仓库名称
- 🔒 选择公开或私有
- 🚀 自动创建仓库并推送

### docker-push

在任何 Docker 项目目录中推送镜像：

```bash
cd /path/to/docker/project
docker-push
```

功能：
- 🔐 Docker Hub 登录
- 🏷️ 自定义镜像名和标签
- 🔒 选择公开或私有
- 🚀 自动构建并推送

## 🗑️ 卸载

```bash
# 方式一：使用卸载脚本
sudo ./uninstall.sh

# 方式二：手动删除
sudo rm /usr/local/bin/github-push /usr/local/bin/docker-push
```

## 📋 系统要求

- **操作系统**: Linux / macOS
- **GitHub CLI**: 自动安装（github-push 需要）
- **Docker**: 需要已安装（docker-push 需要）

## 🖼️ 截图

### github-push
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🚀 Rust Stream - 一键推送到 GitHub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ GitHub CLI: gh version 2.x.x
✓ 已登录 GitHub
  当前用户: your-username

请输入仓库名称 [my-project]: 

请选择仓库可见性:
  1) 🌍 公开 (Public)
  2) 🔒 私有 (Private)
```

### docker-push
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🐳 Rust Stream - 一键推送到 Docker Hub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Docker: 24.x.x
✓ 已登录 Docker Hub
  当前用户: your-username

✓ 找到本地镜像: my-image:latest

请输入 Docker Hub 镜像名称 [my-image]: 
请输入镜像标签 [latest]: 
```

## 📄 许可证

MIT License

## 🙏 贡献

欢迎提交 Issue 和 Pull Request！

