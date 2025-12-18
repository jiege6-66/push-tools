#!/bin/bash
# =============================================================================
# 🐳 docker-push - 一键推送到 Docker Hub
# 支持登录、构建、打标签、选择可见性、推送镜像
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
echo "  🐳 docker-push - 一键推送到 Docker Hub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

# 检查 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker 未安装！"
        echo "  请先安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker 服务未运行或无权限！"
        echo "  请确保 Docker 正在运行，或使用 sudo 运行此脚本"
        exit 1
    fi
    
    success "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
}

# 检查登录状态
check_login() {
    if docker system info 2>/dev/null | grep -q "Username:"; then
        DOCKER_USER=$(docker system info 2>/dev/null | grep "Username:" | awk '{print $2}')
        return 0
    fi
    return 1
}

# 登录 Docker Hub
login_dockerhub() {
    echo ""
    info "需要登录 Docker Hub..."
    echo ""
    echo -e "${YELLOW}请选择登录方式:${NC}"
    echo ""
    echo -e "  1) ${BOLD}用户名 + Access Token${NC} ${GREEN}(推荐 - 更安全)${NC}"
    echo "     使用 Docker Hub 生成的访问令牌"
    echo ""
    echo -e "  2) ${BOLD}用户名 + 密码${NC}"
    echo "     使用 Docker Hub 账号密码"
    echo ""
    read -p "请输入选择 [1/2]: " login_choice
    
    echo ""
    read -p "请输入 Docker Hub 用户名: " DOCKER_USER
    
    if [ -z "$DOCKER_USER" ]; then
        error "用户名不能为空"
        exit 1
    fi
    
    case $login_choice in
        1)
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BOLD}创建 Docker Hub Access Token:${NC}"
            echo ""
            echo "  1. 打开浏览器访问:"
            echo ""
            echo "     https://hub.docker.com/settings/security"
            echo ""
            echo "  2. 点击 'New Access Token'"
            echo "  3. 输入描述 (如: rust-stream-push)"
            echo "  4. 选择权限: Read & Write"
            echo "  5. 点击 'Generate' 生成"
            echo "  6. 复制生成的 Token"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            read -sp "请粘贴你的 Access Token: " DOCKER_PASS
            echo ""
            ;;
        2)
            read -sp "请输入密码: " DOCKER_PASS
            echo ""
            ;;
        *)
            error "无效选择"
            exit 1
            ;;
    esac
    
    if [ -z "$DOCKER_PASS" ]; then
        error "密码/Token 不能为空"
        exit 1
    fi
    
    echo ""
    info "正在登录..."
    
    if echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin; then
        echo ""
        success "登录成功！"
    else
        echo ""
        error "登录失败，请检查用户名和密码/Token"
        exit 1
    fi
}

# 主流程
main() {
    # 1. 检查 Docker
    check_docker
    
    # 2. 检查登录状态
    echo ""
    if check_login; then
        success "已登录 Docker Hub"
        echo -e "  当前用户: ${GREEN}$DOCKER_USER${NC}"
    else
        login_dockerhub
        DOCKER_USER=$(docker system info 2>/dev/null | grep "Username:" | awk '{print $2}')
        if [ -z "$DOCKER_USER" ]; then
            read -p "请确认你的 Docker Hub 用户名: " DOCKER_USER
        fi
    fi
    
    # 3. 检查本地镜像
    echo ""
    info "检查本地 Docker 镜像..."
    
    LOCAL_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "rust-stream" | head -1)
    
    if [ -z "$LOCAL_IMAGE" ]; then
        warning "未找到 rust-stream 镜像"
        read -p "是否现在构建镜像? [Y/n]: " build_choice
        if [[ "$build_choice" != "n" && "$build_choice" != "N" ]]; then
            info "正在构建镜像..."
            docker compose build
            LOCAL_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "rust-stream" | head -1)
        else
            error "需要镜像才能推送"
            exit 1
        fi
    fi
    
    success "找到本地镜像: $LOCAL_IMAGE"
    
    # 4. 设置镜像名称
    echo ""
    DEFAULT_IMAGE_NAME="rust-stream"
    echo -e "请输入 Docker Hub 镜像名称 [${GREEN}$DEFAULT_IMAGE_NAME${NC}]: "
    read -r IMAGE_NAME
    IMAGE_NAME=${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}
    
    # 5. 设置标签
    echo ""
    echo -e "请输入镜像标签 [${GREEN}latest${NC}]: "
    read -r IMAGE_TAG
    IMAGE_TAG=${IMAGE_TAG:-latest}
    
    # 6. 选择仓库可见性
    echo ""
    echo -e "${YELLOW}请选择仓库可见性:${NC}"
    echo "  1) 🌍 公开 (Public) - 任何人都可以拉取"
    echo "  2) 🔒 私有 (Private) - 只有你可以拉取"
    echo ""
    echo -e "  ${BLUE}注意: Docker Hub 免费账户只能有 1 个私有仓库${NC}"
    echo ""
    read -p "请输入选择 [1/2]: " visibility_choice
    
    case $visibility_choice in
        1) VISIBILITY="public" ;;
        2) VISIBILITY="private" ;;
        *) VISIBILITY="public"; warning "默认使用公开仓库" ;;
    esac
    
    # 7. 设置描述 (可选)
    echo ""
    echo "请输入镜像描述 [可选，直接回车跳过]: "
    read -r IMAGE_DESC
    
    # 8. 确认信息
    FULL_IMAGE_NAME="$DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}确认信息${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  用户:     ${GREEN}$DOCKER_USER${NC}"
    echo -e "  镜像名称: ${GREEN}$IMAGE_NAME${NC}"
    echo -e "  标签:     ${GREEN}$IMAGE_TAG${NC}"
    echo -e "  可见性:   ${GREEN}$VISIBILITY${NC}"
    echo -e "  完整名称: ${GREEN}$FULL_IMAGE_NAME${NC}"
    echo -e "  描述:     ${GREEN}${IMAGE_DESC:-（无）}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "确认推送到 Docker Hub? [Y/n]: " confirm
    
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        warning "已取消"
        exit 0
    fi
    
    # 9. 打标签
    echo ""
    info "正在打标签: $LOCAL_IMAGE -> $FULL_IMAGE_NAME"
    docker tag "$LOCAL_IMAGE" "$FULL_IMAGE_NAME"
    success "标签创建成功"
    
    # 10. 推送镜像
    echo ""
    info "正在推送镜像到 Docker Hub..."
    echo ""
    
    if docker push "$FULL_IMAGE_NAME"; then
        echo ""
        success "推送成功！"
    else
        echo ""
        error "推送失败"
        exit 1
    fi
    
    # 11. 也推送 latest 标签 (如果当前不是 latest)
    if [ "$IMAGE_TAG" != "latest" ]; then
        echo ""
        read -p "是否同时推送 latest 标签? [Y/n]: " push_latest
        if [[ "$push_latest" != "n" && "$push_latest" != "N" ]]; then
            LATEST_IMAGE="$DOCKER_USER/$IMAGE_NAME:latest"
            docker tag "$LOCAL_IMAGE" "$LATEST_IMAGE"
            docker push "$LATEST_IMAGE"
            success "latest 标签推送成功"
        fi
    fi
    
    # 12. 设置仓库可见性 (通过 Docker Hub API)
    if [ "$VISIBILITY" = "private" ]; then
        echo ""
        info "正在设置仓库为私有..."
        
        # 获取 token
        HUB_TOKEN=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\": \"$DOCKER_USER\", \"password\": \"$DOCKER_PASS\"}" \
            https://hub.docker.com/v2/users/login/ | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$HUB_TOKEN" ]; then
            # 设置仓库为私有
            RESULT=$(curl -s -X PATCH \
                -H "Authorization: Bearer $HUB_TOKEN" \
                -H "Content-Type: application/json" \
                -d '{"is_private": true}' \
                "https://hub.docker.com/v2/repositories/$DOCKER_USER/$IMAGE_NAME/")
            
            if echo "$RESULT" | grep -q '"is_private":true'; then
                success "仓库已设置为私有"
            else
                warning "自动设置私有失败，请手动设置"
                echo ""
                echo "  访问: https://hub.docker.com/r/$DOCKER_USER/$IMAGE_NAME/settings"
            fi
        else
            warning "无法自动设置可见性，请手动设置"
            echo ""
            echo "  访问: https://hub.docker.com/r/$DOCKER_USER/$IMAGE_NAME/settings"
        fi
    fi
    
    # 13. 完成
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ 推送成功完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  🔗 镜像地址:"
    echo "     https://hub.docker.com/r/$DOCKER_USER/$IMAGE_NAME"
    echo ""
    echo "  📋 拉取命令:"
    echo "     docker pull $FULL_IMAGE_NAME"
    echo ""
    echo "  🚀 运行命令:"
    echo "     docker run -d -p 8080:8080 $FULL_IMAGE_NAME"
    echo ""
}

# 运行
main "$@"
