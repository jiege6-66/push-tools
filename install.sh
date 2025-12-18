#!/bin/bash
# =============================================================================
# 🚀 Push Tools - 一键安装 github-push 和 docker-push 命令
# 
# 在线安装:
#   curl -fsSL https://raw.githubusercontent.com/jiege6-66/push-tools/master/install.sh | sudo bash
#
# 本地安装:
#   sudo ./install.sh
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 打印函数
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# 配置
REPO_URL="https://raw.githubusercontent.com/jiege6-66/push-tools/master"
INSTALL_DIR="/usr/local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# 临时目录
TMP_DIR=""
cleanup() {
    [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# 标题
echo ""
echo -e "${CYAN}"
cat << 'EOF'
  ╔═══════════════════════════════════════════════════╗
  ║                                                   ║
  ║   🚀 Push Tools Installer                         ║
  ║                                                   ║
  ║   github-push  - 一键推送到 GitHub                ║
  ║   docker-push  - 一键推送到 Docker Hub            ║
  ║                                                   ║
  ╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 检查权限
if [ "$EUID" -ne 0 ]; then
    error "需要 root 权限！"
    echo ""
    echo "  请使用以下命令运行:"
    echo ""
    echo "    sudo ./install.sh"
    echo "    或"
    echo "    curl -fsSL URL | sudo bash"
    echo ""
    exit 1
fi

# 检测是本地安装还是远程安装
LOCAL_INSTALL=false
if [ -f "$SCRIPT_DIR/scripts/push-to-github.sh" ] && [ -f "$SCRIPT_DIR/scripts/push-to-dockerhub.sh" ]; then
    LOCAL_INSTALL=true
    info "检测到本地脚本，使用本地安装模式"
else
    info "使用在线安装模式"
fi

# 检测下载工具
download() {
    local url="$1"
    local dest="$2"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget &> /dev/null; then
        wget -qO "$dest" "$url"
    else
        error "需要 curl 或 wget"
        exit 1
    fi
}

# 安装命令
install_command() {
    local name="$1"
    local src="$2"
    local dest="$INSTALL_DIR/$name"
    
    if [ "$LOCAL_INSTALL" = true ]; then
        # 本地安装
        if [ -f "$src" ]; then
            cp "$src" "$dest"
            chmod +x "$dest"
            success "已安装: $name"
        else
            error "源文件不存在: $src"
            return 1
        fi
    else
        # 远程安装
        local url="${REPO_URL}/scripts/${src}"
        info "下载 $name..."
        
        if download "$url" "$TMP_DIR/$name"; then
            chmod +x "$TMP_DIR/$name"
            mv "$TMP_DIR/$name" "$dest"
            success "已安装: $name"
        else
            error "下载失败: $name"
            return 1
        fi
    fi
}

# 创建临时目录
TMP_DIR=$(mktemp -d)

# 开始安装
echo ""
info "正在安装命令到 $INSTALL_DIR ..."
echo ""

if [ "$LOCAL_INSTALL" = true ]; then
    install_command "github-push" "$SCRIPT_DIR/scripts/push-to-github.sh"
    install_command "docker-push" "$SCRIPT_DIR/scripts/push-to-dockerhub.sh"
else
    install_command "github-push" "push-to-github.sh"
    install_command "docker-push" "push-to-dockerhub.sh"
fi

# 安装 GitHub CLI（可选）
echo ""
if ! command -v gh &> /dev/null; then
    echo -e "GitHub CLI 未安装 (github-push 需要)"
    read -p "是否现在安装? [Y/n]: " install_gh </dev/tty
    if [[ "$install_gh" != "n" && "$install_gh" != "N" ]]; then
        info "正在安装 GitHub CLI..."
        
        if [ -f /etc/debian_version ]; then
            (type -p wget >/dev/null || (apt update && apt-get install wget -y)) \
            && mkdir -p -m 755 /etc/apt/keyrings \
            && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
            && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
            && apt update \
            && apt install gh -y
            success "GitHub CLI 安装完成"
        elif [ -f /etc/redhat-release ]; then
            dnf install 'dnf-command(config-manager)' -y 2>/dev/null || yum install yum-utils -y
            dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            dnf install gh -y 2>/dev/null || yum install gh -y
            success "GitHub CLI 安装完成"
        else
            warning "请手动安装 GitHub CLI: https://github.com/cli/cli#installation"
        fi
    fi
else
    success "GitHub CLI 已安装: $(gh --version | head -1)"
fi

# 完成
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ 安装完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  🎉 现在你可以在任何目录使用以下命令:"
echo ""
echo -e "  ${CYAN}${BOLD}github-push${NC}  推送当前项目到 GitHub"
echo "               支持创建仓库、选择公开/私有"
echo ""
echo -e "  ${CYAN}${BOLD}docker-push${NC}  推送 Docker 镜像到 Docker Hub"
echo "               支持打标签、选择公开/私有"
echo ""
echo "  📖 使用示例:"
echo ""
echo "      cd /path/to/your/project"
echo "      github-push"
echo ""
echo "      cd /path/to/docker/project"
echo "      docker-push"
echo ""

