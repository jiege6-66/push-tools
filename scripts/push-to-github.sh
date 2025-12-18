#!/bin/bash
# =============================================================================
# 🚀 github-push - 一键推送到 GitHub
# 支持 SSH 环境、创建仓库、选择公开/私有、自动推送
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

# 标题
clear 2>/dev/null || true
echo -e "${CYAN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 github-push - 一键推送到 GitHub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
    error "当前目录不是 Git 仓库！"
    exit 1
fi

# 检查 GitHub CLI
check_gh_cli() {
    command -v gh &> /dev/null
}

# 安装 GitHub CLI
install_gh_cli() {
    info "正在安装 GitHub CLI..."
    
    if [ -f /etc/debian_version ]; then
        (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install 'dnf-command(config-manager)' -y
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install gh -y
    else
        error "不支持的操作系统，请手动安装 GitHub CLI"
        echo "  访问: https://github.com/cli/cli#installation"
        exit 1
    fi
    
    success "GitHub CLI 安装完成"
}

# 检查登录状态
check_auth() {
    gh auth status &> /dev/null
}

# 登录 GitHub (优化 SSH 环境)
login_github() {
    echo ""
    info "需要登录 GitHub..."
    echo ""
    echo -e "${YELLOW}请选择登录方式:${NC}"
    echo ""
    echo -e "  1) ${BOLD}设备代码登录${NC} ${GREEN}(推荐 - 适合 SSH 环境)${NC}"
    echo "     在任意设备的浏览器中打开 github.com/login/device"
    echo "     输入显示的代码即可完成登录"
    echo ""
    echo -e "  2) ${BOLD}Personal Access Token${NC}"
    echo "     使用 GitHub 生成的访问令牌"
    echo ""
    read -p "请输入选择 [1/2]: " login_choice
    
    case $login_choice in
        1)
            echo ""
            info "正在启动设备代码登录..."
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BOLD}请按照以下步骤操作:${NC}"
            echo ""
            echo "  1. 在任意设备上打开浏览器"
            echo ""
            echo -e "  2. 访问: ${GREEN}https://github.com/login/device${NC}"
            echo ""
            echo "  3. 输入下面显示的代码"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            # 使用 HTTPS 协议，适合 SSH 环境
            gh auth login -h github.com -p https -w
            ;;
        2)
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BOLD}创建 Personal Access Token:${NC}"
            echo ""
            echo "  1. 打开浏览器访问:"
            echo ""
            echo "     https://github.com/settings/tokens/new"
            echo ""
            echo "  2. Note: 输入一个名称 (如: rust-stream-push)"
            echo "  3. Expiration: 选择有效期"
            echo -e "  4. 勾选权限: ${YELLOW}repo${NC} (完整仓库访问)"
            echo "  5. 点击 'Generate token' 生成"
            echo "  6. 复制生成的 token"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            read -sp "请粘贴你的 GitHub Token: " token
            echo ""
            
            if [ -z "$token" ]; then
                error "Token 不能为空"
                exit 1
            fi
            
            echo "$token" | gh auth login -h github.com -p https --with-token
            ;;
        *)
            error "无效选择"
            exit 1
            ;;
    esac
    
    echo ""
    if check_auth; then
        success "登录成功！"
        echo ""
        gh auth status
    else
        error "登录失败，请重试"
        exit 1
    fi
}

# 主流程
main() {
    # 1. 检查/安装 GitHub CLI
    if ! check_gh_cli; then
        warning "GitHub CLI 未安装"
        read -p "是否自动安装? [Y/n]: " install_choice
        if [[ "$install_choice" != "n" && "$install_choice" != "N" ]]; then
            install_gh_cli
        else
            error "需要 GitHub CLI 才能继续"
            exit 1
        fi
    else
        success "GitHub CLI: $(gh --version | head -1)"
    fi
    
    # 2. 检查登录状态
    echo ""
    if ! check_auth; then
        login_github
    else
        success "已登录 GitHub"
        GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null)
        echo -e "  当前用户: ${GREEN}$GITHUB_USER${NC}"
    fi
    
    # 3. 获取仓库名称
    echo ""
    DEFAULT_REPO_NAME=$(basename "$(pwd)")
    echo -e "请输入仓库名称 [${GREEN}$DEFAULT_REPO_NAME${NC}]: "
    read -r REPO_NAME
    REPO_NAME=${REPO_NAME:-$DEFAULT_REPO_NAME}
    
    # 4. 选择公开/私有
    echo ""
    echo -e "${YELLOW}请选择仓库可见性:${NC}"
    echo "  1) 🌍 公开 (Public) - 任何人都可以看到"
    echo "  2) 🔒 私有 (Private) - 只有你可以看到"
    echo ""
    read -p "请输入选择 [1/2]: " visibility_choice
    
    case $visibility_choice in
        1) VISIBILITY="public" ;;
        2) VISIBILITY="private" ;;
        *) VISIBILITY="private"; warning "默认使用私有仓库" ;;
    esac
    
    # 5. 获取仓库描述
    echo ""
    echo "请输入仓库描述 [可选，直接回车跳过]: "
    read -r REPO_DESC
    
    # 6. 确认信息
    GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null)
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}确认信息${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  用户:     ${GREEN}$GITHUB_USER${NC}"
    echo -e "  仓库名称: ${GREEN}$REPO_NAME${NC}"
    echo -e "  可见性:   ${GREEN}$VISIBILITY${NC}"
    echo -e "  描述:     ${GREEN}${REPO_DESC:-（无）}${NC}"
    echo -e "  地址:     ${GREEN}github.com/$GITHUB_USER/$REPO_NAME${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "确认推送到 GitHub? [Y/n]: " confirm
    
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        warning "已取消"
        exit 0
    fi
    
    # 7. 检查远程仓库是否已存在
    echo ""
    REPO_EXISTS=false
    if gh repo view "$GITHUB_USER/$REPO_NAME" &> /dev/null; then
        REPO_EXISTS=true
        warning "仓库 $GITHUB_USER/$REPO_NAME 已存在"
        read -p "是否直接推送到现有仓库? [Y/n]: " use_existing
        if [[ "$use_existing" == "n" || "$use_existing" == "N" ]]; then
            exit 0
        fi
    fi
    
    REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"
    
    # 8. 创建仓库 (如果不存在)
    if [ "$REPO_EXISTS" = false ]; then
        info "正在创建仓库..."
        
        CREATE_ARGS="--$VISIBILITY --source=. --remote=origin --push"
        if [ -n "$REPO_DESC" ]; then
            CREATE_ARGS="$CREATE_ARGS --description \"$REPO_DESC\""
        fi
        
        if eval "gh repo create \"$REPO_NAME\" $CREATE_ARGS"; then
            success "仓库创建并推送成功！"
        else
            error "仓库创建失败"
            exit 1
        fi
    else
        # 9. 推送到现有仓库
        info "正在推送代码..."
        
        # 设置远程
        if git remote | grep -q "^origin$"; then
            git remote set-url origin "$REPO_URL"
        else
            git remote add origin "$REPO_URL"
        fi
        
        # 推送
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        if git push -u origin "$BRANCH" --force; then
            success "推送成功！"
        else
            error "推送失败"
            exit 1
        fi
    fi
    
    # 10. 完成
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ 操作成功完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  🔗 仓库地址: ${CYAN}https://github.com/$GITHUB_USER/$REPO_NAME${NC}"
    echo ""
    echo "  📋 克隆命令:"
    echo "     git clone https://github.com/$GITHUB_USER/$REPO_NAME.git"
    echo ""
}

# 运行
main "$@"
