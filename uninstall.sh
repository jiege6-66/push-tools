#!/bin/bash
# =============================================================================
# 卸载 github-push 和 docker-push 命令
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }

INSTALL_DIR="/usr/local/bin"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🗑️  卸载 Push Tools${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    warning "需要 root 权限"
    echo "  请使用: sudo $0"
    exit 1
fi

for cmd in github-push docker-push; do
    if [ -f "$INSTALL_DIR/$cmd" ]; then
        rm -f "$INSTALL_DIR/$cmd"
        success "已删除: $cmd"
    else
        warning "未找到: $cmd"
    fi
done

echo ""
echo -e "${GREEN}✅ 卸载完成${NC}"
echo ""

