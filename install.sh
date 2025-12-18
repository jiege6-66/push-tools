#!/bin/bash
# =============================================================================
# 🚀 Push Tools - 一键安装脚本
# 
# 在线安装:
#   curl -fsSL https://raw.githubusercontent.com/jiege6-66/push-tools/master/install.sh | sudo bash
#
# 安装全部:
#   curl ... | sudo bash -s -- --all
#
# 只安装指定工具:
#   curl ... | sudo bash -s -- --only github-push,git-gui
# =============================================================================

# 不使用 set -e，因为某些命令可能预期失败（如读取 /dev/tty）
# set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
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

# 可用工具列表
declare -A TOOLS=(
    ["github-push"]="push-to-github.sh|🚀 一键推送到 GitHub"
    ["docker-push"]="push-to-dockerhub.sh|🐳 一键推送到 Docker Hub"
    ["git-gui"]="git-gui.sh|🎨 命令行图形化 Git 管理"
)

# 选择的工具
SELECTED_TOOLS=()
INSTALL_ALL=false
ONLY_TOOLS=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --all|-a)
            INSTALL_ALL=true
            shift
            ;;
        --only|-o)
            ONLY_TOOLS="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --all, -a       安装所有工具（跳过选择）"
            echo "  --only, -o      只安装指定工具（逗号分隔）"
            echo "                  例: --only github-push,git-gui"
            echo "  -h, --help      显示帮助"
            echo ""
            echo "可用工具: github-push, docker-push, git-gui"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# 临时目录
TMP_DIR=""
cleanup() {
    [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# 标题
show_header() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${CYAN}"
    cat << 'EOF'
  ╔═══════════════════════════════════════════════════════════╗
  ║                                                           ║
  ║   🚀 Push Tools Installer                                 ║
  ║                                                           ║
  ║   可用工具:                                               ║
  ║     • github-push  - 一键推送到 GitHub                    ║
  ║     • docker-push  - 一键推送到 Docker Hub                ║
  ║     • git-gui      - 命令行图形化 Git 管理                ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 检查权限
check_root() {
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
}

# 检测是本地安装还是远程安装
LOCAL_INSTALL=false
detect_install_mode() {
    if [ -f "$SCRIPT_DIR/scripts/push-to-github.sh" ]; then
        LOCAL_INSTALL=true
        info "检测到本地脚本，使用本地安装模式"
    else
        info "使用在线安装模式"
    fi
}

# 选择要安装的工具
select_tools() {
    # 如果指定了 --only 参数
    if [ -n "$ONLY_TOOLS" ]; then
        IFS=',' read -ra SELECTED_TOOLS <<< "$ONLY_TOOLS"
        return
    fi
    
    # 如果指定了 --all 参数
    if [ "$INSTALL_ALL" = true ]; then
        SELECTED_TOOLS=("github-push" "docker-push" "git-gui")
        return
    fi
    
    # 检查是否可以交互式输入
    if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
        # 无法交互，默认安装全部
        info "检测到非交互式环境，将安装全部工具"
        SELECTED_TOOLS=("github-push" "docker-push" "git-gui")
        return
    fi
    
    # 交互式选择
    echo ""
    echo -e "${BOLD}   请选择要安装的工具:${NC}"
    echo ""
    echo -e "   ${CYAN}[1]${NC} 🚀 github-push  - 一键推送项目到 GitHub"
    echo -e "       ${DIM}支持创建仓库、选择公开/私有、设备代码登录${NC}"
    echo ""
    echo -e "   ${CYAN}[2]${NC} 🐳 docker-push  - 一键推送镜像到 Docker Hub"
    echo -e "       ${DIM}支持打标签、选择公开/私有、自动构建${NC}"
    echo ""
    echo -e "   ${CYAN}[3]${NC} 🎨 git-gui      - 命令行图形化 Git 管理"
    echo -e "       ${DIM}查看历史、回滚、分支管理、提交、推送等${NC}"
    echo ""
    echo -e "   ${CYAN}[a]${NC} ✨ 全部安装 ${GREEN}(默认)${NC}"
    echo ""
    echo -e "   ${DIM}输入编号，多个用空格或逗号分隔 (如: 1 3 或 1,2,3)${NC}"
    echo -e "   ${DIM}直接回车将安装全部工具${NC}"
    echo ""
    
    # 尝试从 /dev/tty 读取
    local selection=""
    if [ -e /dev/tty ]; then
        read -p "   请选择 [a]: " selection </dev/tty 2>/dev/null || selection="a"
    else
        read -p "   请选择 [a]: " selection 2>/dev/null || selection="a"
    fi
    
    # 如果为空，默认全部安装
    if [ -z "$selection" ]; then
        selection="a"
    fi
    
    # 解析选择
    if [[ "$selection" == "a" || "$selection" == "A" || "$selection" == "all" ]]; then
        SELECTED_TOOLS=("github-push" "docker-push" "git-gui")
    else
        # 替换逗号为空格，然后遍历
        selection="${selection//,/ }"
        for sel in $selection; do
            case $sel in
                1) SELECTED_TOOLS+=("github-push") ;;
                2) SELECTED_TOOLS+=("docker-push") ;;
                3) SELECTED_TOOLS+=("git-gui") ;;
            esac
        done
    fi
    
    # 如果没有选中任何有效工具，默认全部
    if [ ${#SELECTED_TOOLS[@]} -eq 0 ]; then
        info "未识别的选择，将安装全部工具"
        SELECTED_TOOLS=("github-push" "docker-push" "git-gui")
    fi
}

# 下载文件
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

# 安装单个命令
install_command() {
    local name="$1"
    local script_file="${TOOLS[$name]%%|*}"
    local desc="${TOOLS[$name]#*|}"
    local dest="$INSTALL_DIR/$name"
    
    if [ "$LOCAL_INSTALL" = true ]; then
        local src="$SCRIPT_DIR/scripts/$script_file"
        if [ -f "$src" ]; then
            cp "$src" "$dest"
            chmod +x "$dest"
            success "已安装: $name - $desc"
            return 0
        else
            error "源文件不存在: $src"
            return 1
        fi
    else
        local url="${REPO_URL}/scripts/${script_file}"
        info "下载 $name..."
        
        if download "$url" "$TMP_DIR/$name"; then
            chmod +x "$TMP_DIR/$name"
            mv "$TMP_DIR/$name" "$dest"
            success "已安装: $name - $desc"
            return 0
        else
            error "下载失败: $name"
            return 1
        fi
    fi
}

# 安装 GitHub CLI
install_gh_cli() {
    if command -v gh &> /dev/null; then
        success "GitHub CLI 已安装: $(gh --version | head -1)"
        return 0
    fi
    
    echo ""
    echo -e "   ${YELLOW}GitHub CLI 未安装${NC} (github-push 需要)"
    
    local install_gh="y"
    if [ -e /dev/tty ]; then
        read -p "   是否现在安装? [Y/n]: " install_gh </dev/tty 2>/dev/null || install_gh="y"
    fi
    
    if [[ "$install_gh" == "n" || "$install_gh" == "N" ]]; then
        warning "跳过 GitHub CLI 安装"
        return 0
    fi
    
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
}

# 显示安装结果
show_result() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ 安装完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  🎉 已安装的命令:"
    echo ""
    
    for tool in "${SELECTED_TOOLS[@]}"; do
        local desc="${TOOLS[$tool]#*|}"
        echo -e "  ${CYAN}${BOLD}$tool${NC}"
        echo -e "      $desc"
        echo ""
    done
    
    echo "  📖 使用示例:"
    echo ""
    
    for tool in "${SELECTED_TOOLS[@]}"; do
        case $tool in
            github-push)
                echo "      cd /path/to/project && github-push"
                ;;
            docker-push)
                echo "      cd /path/to/docker && docker-push"
                ;;
            git-gui)
                echo "      cd /path/to/git-repo && git-gui"
                ;;
        esac
    done
    echo ""
}

# 主流程
main() {
    show_header
    check_root
    detect_install_mode
    select_tools
    
    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    
    # 确认安装
    echo ""
    echo -e "   ${BOLD}将安装以下工具:${NC}"
    for tool in "${SELECTED_TOOLS[@]}"; do
        local desc="${TOOLS[$tool]#*|}"
        echo -e "      ${GREEN}✓${NC} $tool - $desc"
    done
    echo ""
    
    # 尝试读取确认
    local confirm="y"
    if [ -e /dev/tty ]; then
        read -p "   确认安装? [Y/n]: " confirm </dev/tty 2>/dev/null || confirm="y"
    fi
    
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        warning "已取消安装"
        exit 0
    fi
    
    # 安装选中的工具
    echo ""
    info "正在安装到 $INSTALL_DIR ..."
    echo ""
    
    local installed=0
    for tool in "${SELECTED_TOOLS[@]}"; do
        if install_command "$tool"; then
            installed=$((installed + 1))
        fi
    done
    
    # 如果安装了 github-push，检查 GitHub CLI
    for tool in "${SELECTED_TOOLS[@]}"; do
        if [ "$tool" = "github-push" ]; then
            install_gh_cli
            break
        fi
    done
    
    # 显示结果
    if [ $installed -gt 0 ]; then
        show_result
    else
        error "没有成功安装任何工具"
        exit 1
    fi
}

# 运行
main "$@"
