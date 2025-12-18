#!/bin/bash
# =============================================================================
# 🎨 Git GUI - 命令行图形化 Git 管理工具
# 
# 功能：可视化查看历史、回滚、提交、分支管理等
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# 打印函数
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# 清屏并显示标题
show_header() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
   ╔════════════════════════════════════════════════════════╗
   ║                                                        ║
   ║   🎨 Git GUI - 命令行图形化 Git 管理工具               ║
   ║                                                        ║
   ╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # 显示当前仓库信息
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local repo_name=$(basename "$(git rev-parse --show-toplevel)")
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        local remote=$(git remote get-url origin 2>/dev/null || echo "无远程仓库")
        local status_info=""
        
        # 统计更改
        local staged=$(git diff --cached --numstat 2>/dev/null | wc -l)
        local unstaged=$(git diff --numstat 2>/dev/null | wc -l)
        local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
        
        if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
            status_info=" ${YELLOW}[+$staged ~$unstaged ?$untracked]${NC}"
        else
            status_info=" ${GREEN}[clean]${NC}"
        fi
        
        echo -e "   ${DIM}仓库:${NC} ${BOLD}$repo_name${NC}  ${DIM}分支:${NC} ${GREEN}$branch${NC}$status_info"
        echo -e "   ${DIM}远程:${NC} $remote"
    else
        echo -e "   ${RED}⚠ 当前目录不是 Git 仓库${NC}"
    fi
    echo ""
}

# 检查是否在 Git 仓库中
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        error "当前目录不是 Git 仓库！"
        echo ""
        read -p "是否初始化 Git 仓库? [Y/n]: " init_choice
        if [[ "$init_choice" != "n" && "$init_choice" != "N" ]]; then
            git init
            success "Git 仓库已初始化"
        else
            exit 1
        fi
    fi
}

# 显示主菜单
show_main_menu() {
    echo -e "${BOLD}   📋 主菜单${NC}"
    echo ""
    echo -e "   ${CYAN}[1]${NC}  📜 查看提交历史"
    echo -e "   ${CYAN}[2]${NC}  📊 查看仓库状态"
    echo -e "   ${CYAN}[3]${NC}  ➕ 添加并提交更改"
    echo -e "   ${CYAN}[4]${NC}  ⏪ 回滚到历史版本"
    echo -e "   ${CYAN}[5]${NC}  🌿 分支管理"
    echo -e "   ${CYAN}[6]${NC}  🔄 推送/拉取"
    echo -e "   ${CYAN}[7]${NC}  📝 查看文件差异"
    echo -e "   ${CYAN}[8]${NC}  🏷️  标签管理"
    echo -e "   ${CYAN}[9]${NC}  🔧 高级操作"
    echo -e "   ${CYAN}[0]${NC}  🚪 退出"
    echo ""
}

# 1. 查看提交历史
view_history() {
    show_header
    echo -e "${BOLD}   📜 提交历史${NC}"
    echo ""
    
    # 获取提交数量
    local total=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    echo -e "   ${DIM}共 $total 个提交${NC}"
    echo ""
    
    # 显示图形化历史
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    git log --oneline --graph --decorate --color=always -20 | while IFS= read -r line; do
        echo "   $line"
    done
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "   ${CYAN}[1]${NC} 查看更多历史"
    echo -e "   ${CYAN}[2]${NC} 查看某个提交详情"
    echo -e "   ${CYAN}[3]${NC} 搜索提交"
    echo -e "   ${CYAN}[0]${NC} 返回主菜单"
    echo ""
    read -p "   请选择: " choice
    
    case $choice in
        1)
            show_header
            echo -e "${BOLD}   📜 完整提交历史${NC}"
            echo ""
            git log --oneline --graph --decorate --color=always | less -R
            ;;
        2)
            echo ""
            read -p "   输入提交 Hash (前几位即可): " hash
            if [ -n "$hash" ]; then
                show_header
                echo -e "${BOLD}   📝 提交详情: $hash${NC}"
                echo ""
                git show --stat --color=always "$hash" | less -R
            fi
            ;;
        3)
            echo ""
            read -p "   输入搜索关键词: " keyword
            if [ -n "$keyword" ]; then
                show_header
                echo -e "${BOLD}   🔍 搜索结果: $keyword${NC}"
                echo ""
                git log --oneline --grep="$keyword" --color=always | head -20
                echo ""
                read -p "   按回车继续..."
            fi
            ;;
    esac
}

# 2. 查看仓库状态
view_status() {
    show_header
    echo -e "${BOLD}   📊 仓库状态${NC}"
    echo ""
    
    # 暂存区
    local staged=$(git diff --cached --name-status 2>/dev/null)
    if [ -n "$staged" ]; then
        echo -e "   ${GREEN}● 暂存区 (将被提交):${NC}"
        echo "$staged" | while IFS=$'\t' read -r status file; do
            case $status in
                A) echo -e "      ${GREEN}+ 新增:${NC} $file" ;;
                M) echo -e "      ${YELLOW}~ 修改:${NC} $file" ;;
                D) echo -e "      ${RED}- 删除:${NC} $file" ;;
                R*) echo -e "      ${BLUE}→ 重命名:${NC} $file" ;;
                *) echo -e "      $status: $file" ;;
            esac
        done
        echo ""
    fi
    
    # 工作区
    local unstaged=$(git diff --name-status 2>/dev/null)
    if [ -n "$unstaged" ]; then
        echo -e "   ${YELLOW}● 工作区 (未暂存):${NC}"
        echo "$unstaged" | while IFS=$'\t' read -r status file; do
            case $status in
                M) echo -e "      ${YELLOW}~ 修改:${NC} $file" ;;
                D) echo -e "      ${RED}- 删除:${NC} $file" ;;
                *) echo -e "      $status: $file" ;;
            esac
        done
        echo ""
    fi
    
    # 未跟踪
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
    if [ -n "$untracked" ]; then
        echo -e "   ${RED}● 未跟踪文件:${NC}"
        echo "$untracked" | while read -r file; do
            echo -e "      ${DIM}? $file${NC}"
        done
        echo ""
    fi
    
    # 如果都没有
    if [ -z "$staged" ] && [ -z "$unstaged" ] && [ -z "$untracked" ]; then
        echo -e "   ${GREEN}✓ 工作区干净，没有待提交的更改${NC}"
        echo ""
    fi
    
    read -p "   按回车继续..."
}

# 3. 添加并提交
commit_changes() {
    show_header
    echo -e "${BOLD}   ➕ 添加并提交更改${NC}"
    echo ""
    
    # 显示当前状态
    local has_changes=false
    
    # 检查是否有更改
    if [ -n "$(git status --porcelain)" ]; then
        has_changes=true
        
        echo -e "   ${CYAN}[1]${NC} 添加所有更改 (git add -A)"
        echo -e "   ${CYAN}[2]${NC} 交互式添加 (选择文件)"
        echo -e "   ${CYAN}[3]${NC} 只提交已暂存的文件"
        echo -e "   ${CYAN}[0]${NC} 返回"
        echo ""
        read -p "   请选择: " choice
        
        case $choice in
            1)
                git add -A
                success "已添加所有更改"
                ;;
            2)
                interactive_add
                ;;
            3)
                # 继续提交
                ;;
            0)
                return
                ;;
        esac
        
        # 检查暂存区
        if [ -z "$(git diff --cached --name-only)" ]; then
            warning "暂存区为空，没有可提交的更改"
            read -p "   按回车继续..."
            return
        fi
        
        echo ""
        echo -e "   ${GREEN}将要提交的文件:${NC}"
        git diff --cached --name-status | while IFS=$'\t' read -r status file; do
            case $status in
                A) echo -e "      ${GREEN}+ $file${NC}" ;;
                M) echo -e "      ${YELLOW}~ $file${NC}" ;;
                D) echo -e "      ${RED}- $file${NC}" ;;
                *) echo -e "      $status $file" ;;
            esac
        done
        
        echo ""
        echo -e "   ${BOLD}提交信息类型:${NC}"
        echo -e "   ${CYAN}[1]${NC} 🎉 feat:     新功能"
        echo -e "   ${CYAN}[2]${NC} 🐛 fix:      修复 Bug"
        echo -e "   ${CYAN}[3]${NC} 📝 docs:     文档更新"
        echo -e "   ${CYAN}[4]${NC} 🎨 style:    代码格式"
        echo -e "   ${CYAN}[5]${NC} ♻️  refactor: 重构"
        echo -e "   ${CYAN}[6]${NC} 🔧 chore:    其他更改"
        echo -e "   ${CYAN}[7]${NC} ✏️  自定义消息"
        echo ""
        read -p "   请选择类型 [1-7]: " type_choice
        
        local prefix=""
        case $type_choice in
            1) prefix="🎉 feat: " ;;
            2) prefix="🐛 fix: " ;;
            3) prefix="📝 docs: " ;;
            4) prefix="🎨 style: " ;;
            5) prefix="♻️ refactor: " ;;
            6) prefix="🔧 chore: " ;;
            7) prefix="" ;;
            *) prefix="🔧 " ;;
        esac
        
        echo ""
        read -p "   输入提交信息: " message
        
        if [ -n "$message" ]; then
            git commit -m "${prefix}${message}"
            echo ""
            success "提交成功！"
        else
            warning "提交信息不能为空"
        fi
    else
        echo -e "   ${GREEN}✓ 没有需要提交的更改${NC}"
    fi
    
    echo ""
    read -p "   按回车继续..."
}

# 交互式添加文件
interactive_add() {
    echo ""
    echo -e "   ${BOLD}选择要添加的文件:${NC}"
    echo ""
    
    local files=()
    local i=1
    
    # 获取所有更改的文件
    # 使用 while read 配合 git status --porcelain -z 来正确处理带空格的文件名
    local i=1
    while IFS= read -r -d '' line; do
        # 提取状态和文件名
        # 状态在前两个字符，文件名从第4个字符开始
        local status="${line:0:2}"
        local file="${line:3}"
        
        files+=("$file")
        
        local status_text=""
        # 简单的状态映射
        if [[ "$status" == ?\? ]]; then
            status_text="${RED}[新文件]${NC}"
        elif [[ "$status" == *M* ]]; then
            status_text="${YELLOW}[修改]${NC}"
        elif [[ "$status" == *D* ]]; then
            status_text="${RED}[删除]${NC}"
        elif [[ "$status" == *A* ]]; then
            status_text="${GREEN}[添加]${NC}"
        else
            status_text="[${status}]"
        fi
        
        echo -e "   ${CYAN}[$i]${NC} $file $status_text"
        ((i++))
    done < <(git status --porcelain -z)
    
    echo ""
    echo -e "   ${CYAN}[a]${NC} 添加全部"
    echo -e "   ${CYAN}[0]${NC} 完成选择"
    echo ""
    read -p "   输入编号 (多个用空格分隔): " selections
    
    if [ "$selections" = "a" ]; then
        git add -A
        success "已添加所有文件"
    elif [ "$selections" != "0" ]; then
        for sel in $selections; do
            if [ "$sel" -gt 0 ] && [ "$sel" -le "${#files[@]}" ]; then
                local idx=$((sel - 1))
                git add "${files[$idx]}"
                success "已添加: ${files[$idx]}"
            fi
        done
    fi
}

# 4. 回滚到历史版本
rollback() {
    show_header
    echo -e "${BOLD}   ⏪ 回滚到历史版本${NC}"
    echo ""
    
    echo -e "   ${YELLOW}⚠ 警告：回滚操作会修改历史，请谨慎操作！${NC}"
    echo ""
    
    echo -e "   ${CYAN}[1]${NC} 🔄 软回滚 (保留更改在工作区)"
    echo -e "   ${CYAN}[2]${NC} ⚡ 硬回滚 (丢弃所有更改)"
    echo -e "   ${CYAN}[3]${NC} 📝 撤销某个提交 (创建新提交)"
    echo -e "   ${CYAN}[4]${NC} 🗑️  丢弃工作区更改"
    echo -e "   ${CYAN}[5]${NC} 📤 取消暂存"
    echo -e "   ${CYAN}[0]${NC} 返回"
    echo ""
    read -p "   请选择: " choice
    
    case $choice in
        1)
            echo ""
            echo -e "   ${DIM}最近的提交:${NC}"
            git log --oneline -10 | while IFS= read -r line; do
                echo "      $line"
            done
            echo ""
            read -p "   输入要回滚到的提交 Hash: " hash
            if [ -n "$hash" ]; then
                echo ""
                read -p "   确认软回滚到 $hash? [y/N]: " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    git reset --soft "$hash"
                    success "已软回滚到 $hash，更改保留在暂存区"
                fi
            fi
            ;;
        2)
            echo ""
            echo -e "   ${DIM}最近的提交:${NC}"
            git log --oneline -10 | while IFS= read -r line; do
                echo "      $line"
            done
            echo ""
            read -p "   输入要回滚到的提交 Hash: " hash
            if [ -n "$hash" ]; then
                echo ""
                echo -e "   ${RED}⚠ 这将丢弃所有未提交的更改！${NC}"
                read -p "   确认硬回滚到 $hash? 输入 'YES' 确认: " confirm
                if [ "$confirm" = "YES" ]; then
                    git reset --hard "$hash"
                    success "已硬回滚到 $hash"
                    
                    echo ""
                    read -p "   是否强制推送到远程? [y/N]: " push_confirm
                    if [[ "$push_confirm" == "y" || "$push_confirm" == "Y" ]]; then
                        git push --force
                        success "已强制推送到远程"
                    fi
                fi
            fi
            ;;
        3)
            echo ""
            echo -e "   ${DIM}最近的提交:${NC}"
            git log --oneline -10 | while IFS= read -r line; do
                echo "      $line"
            done
            echo ""
            read -p "   输入要撤销的提交 Hash: " hash
            if [ -n "$hash" ]; then
                git revert "$hash" --no-edit
                success "已创建撤销提交"
            fi
            ;;
        4)
            echo ""
            local changed_files=$(git diff --name-only)
            if [ -n "$changed_files" ]; then
                echo -e "   ${YELLOW}将丢弃以下文件的更改:${NC}"
                echo "$changed_files" | while read -r f; do
                    echo "      - $f"
                done
                echo ""
                read -p "   确认丢弃所有工作区更改? [y/N]: " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    git checkout -- .
                    success "已丢弃所有工作区更改"
                fi
            else
                info "工作区没有更改"
            fi
            ;;
        5)
            echo ""
            local staged_files=$(git diff --cached --name-only)
            if [ -n "$staged_files" ]; then
                echo -e "   ${GREEN}将取消暂存以下文件:${NC}"
                echo "$staged_files" | while read -r f; do
                    echo "      - $f"
                done
                echo ""
                read -p "   确认取消暂存? [Y/n]: " confirm
                if [[ "$confirm" != "n" && "$confirm" != "N" ]]; then
                    git reset HEAD
                    success "已取消暂存"
                fi
            else
                info "暂存区为空"
            fi
            ;;
    esac
    
    echo ""
    read -p "   按回车继续..."
}

# 5. 分支管理
branch_management() {
    show_header
    echo -e "${BOLD}   🌿 分支管理${NC}"
    echo ""
    
    # 显示所有分支
    echo -e "   ${DIM}本地分支:${NC}"
    git branch -v --color=always | while IFS= read -r line; do
        echo "      $line"
    done
    echo ""
    
    # 显示远程分支
    local remote_branches=$(git branch -r 2>/dev/null)
    if [ -n "$remote_branches" ]; then
        echo -e "   ${DIM}远程分支:${NC}"
        echo "$remote_branches" | while IFS= read -r line; do
            echo "      $line"
        done
        echo ""
    fi
    
    echo -e "   ${CYAN}[1]${NC} 创建新分支"
    echo -e "   ${CYAN}[2]${NC} 切换分支"
    echo -e "   ${CYAN}[3]${NC} 合并分支"
    echo -e "   ${CYAN}[4]${NC} 删除分支"
    echo -e "   ${CYAN}[5]${NC} 重命名当前分支"
    echo -e "   ${CYAN}[0]${NC} 返回"
    echo ""
    read -p "   请选择: " choice
    
    case $choice in
        1)
            echo ""
            read -p "   输入新分支名称: " branch_name
            if [ -n "$branch_name" ]; then
                read -p "   是否切换到新分支? [Y/n]: " switch
                if [[ "$switch" != "n" && "$switch" != "N" ]]; then
                    git checkout -b "$branch_name"
                else
                    git branch "$branch_name"
                fi
                success "分支 '$branch_name' 创建成功"
            fi
            ;;
        2)
            echo ""
            read -p "   输入要切换的分支名: " branch_name
            if [ -n "$branch_name" ]; then
                git checkout "$branch_name"
                success "已切换到分支 '$branch_name'"
            fi
            ;;
        3)
            echo ""
            read -p "   输入要合并的分支名: " branch_name
            if [ -n "$branch_name" ]; then
                git merge "$branch_name"
                success "已合并分支 '$branch_name'"
            fi
            ;;
        4)
            echo ""
            read -p "   输入要删除的分支名: " branch_name
            if [ -n "$branch_name" ]; then
                read -p "   确认删除分支 '$branch_name'? [y/N]: " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    git branch -d "$branch_name" 2>/dev/null || git branch -D "$branch_name"
                    success "分支 '$branch_name' 已删除"
                fi
            fi
            ;;
        5)
            echo ""
            read -p "   输入新名称: " new_name
            if [ -n "$new_name" ]; then
                git branch -m "$new_name"
                success "分支已重命名为 '$new_name'"
            fi
            ;;
    esac
    
    echo ""
    read -p "   按回车继续..."
}

# 6. 推送/拉取
push_pull() {
    show_header
    echo -e "${BOLD}   🔄 推送/拉取${NC}"
    echo ""
    
    local remote=$(git remote 2>/dev/null | head -1)
    local branch=$(git rev-parse --abbrev-ref HEAD)
    
    if [ -z "$remote" ]; then
        warning "没有配置远程仓库"
        echo ""
        read -p "   是否添加远程仓库? [Y/n]: " add_remote
        if [[ "$add_remote" != "n" && "$add_remote" != "N" ]]; then
            read -p "   输入远程仓库 URL: " remote_url
            if [ -n "$remote_url" ]; then
                git remote add origin "$remote_url"
                success "已添加远程仓库 origin"
                remote="origin"
            fi
        fi
    fi
    
    if [ -n "$remote" ]; then
        # 检查本地与远程差异
        git fetch "$remote" &>/dev/null || true
        local ahead=$(git rev-list --count "$remote/$branch..HEAD" 2>/dev/null || echo "?")
        local behind=$(git rev-list --count "HEAD..$remote/$branch" 2>/dev/null || echo "?")
        
        echo -e "   ${DIM}当前分支:${NC} $branch"
        echo -e "   ${DIM}远程仓库:${NC} $remote"
        echo -e "   ${DIM}状态:${NC} ↑$ahead 领先 | ↓$behind 落后"
        echo ""
    fi
    
    echo -e "   ${CYAN}[1]${NC} ⬆️  推送到远程 (push)"
    echo -e "   ${CYAN}[2]${NC} ⬇️  从远程拉取 (pull)"
    echo -e "   ${CYAN}[3]${NC} 🔄 获取远程更新 (fetch)"
    echo -e "   ${CYAN}[4]${NC} ⚡ 强制推送 (force push)"
    echo -e "   ${CYAN}[5]${NC} 📡 管理远程仓库"
    echo -e "   ${CYAN}[0]${NC} 返回"
    echo ""
    read -p "   请选择: " choice
    
    case $choice in
        1)
            echo ""
            info "正在推送..."
            if git push -u "$remote" "$branch"; then
                success "推送成功"
            else
                error "推送失败"
            fi
            ;;
        2)
            echo ""
            info "正在拉取..."
            if git pull "$remote" "$branch"; then
                success "拉取成功"
            else
                error "拉取失败，可能存在冲突"
            fi
            ;;
        3)
            echo ""
            info "正在获取远程更新..."
            git fetch --all
            success "获取完成"
            ;;
        4)
            echo ""
            echo -e "   ${RED}⚠ 强制推送会覆盖远程历史！${NC}"
            read -p "   确认强制推送? 输入 'FORCE' 确认: " confirm
            if [ "$confirm" = "FORCE" ]; then
                git push --force
                success "强制推送成功"
            fi
            ;;
        5)
            echo ""
            echo -e "   ${DIM}当前远程仓库:${NC}"
            git remote -v
            echo ""
            read -p "   是否修改远程 URL? [y/N]: " modify
            if [[ "$modify" == "y" || "$modify" == "Y" ]]; then
                read -p "   输入新的远程 URL: " new_url
                if [ -n "$new_url" ]; then
                    git remote set-url origin "$new_url"
                    success "远程 URL 已更新"
                fi
            fi
            ;;
    esac
    
    echo ""
    read -p "   按回车继续..."
}

# 7. 查看文件差异
view_diff() {
    show_header
    echo -e "${BOLD}   📝 查看文件差异${NC}"
    echo ""
    
    echo -e "   ${CYAN}[1]${NC} 查看工作区与暂存区差异"
    echo -e "   ${CYAN}[2]${NC} 查看暂存区与最新提交差异"
    echo -e "   ${CYAN}[3]${NC} 比较两个提交"
    echo -e "   ${CYAN}[4]${NC} 查看某个文件的历史更改"
    echo -e "   ${CYAN}[0]${NC} 返回"
    echo ""
    read -p "   请选择: " choice
    
    case $choice in
        1)
            if [ -n "$(git diff)" ]; then
                git diff --color=always | less -R
            else
                info "工作区没有更改"
                read -p "   按回车继续..."
            fi
            ;;
        2)
            if [ -n "$(git diff --cached)" ]; then
                git diff --cached --color=always | less -R
            else
                info "暂存区没有更改"
                read -p "   按回车继续..."
            fi
            ;;
        3)
            echo ""
            echo -e "   ${DIM}最近的提交:${NC}"
            git log --oneline -10
            echo ""
            read -p "   输入第一个提交 Hash: " hash1
            read -p "   输入第二个提交 Hash: " hash2
            if [ -n "$hash1" ] && [ -n "$hash2" ]; then
                git diff "$hash1" "$hash2" --color=always | less -R
            fi
            ;;
        4)
            echo ""
            read -p "   输入文件路径: " filepath
            if [ -n "$filepath" ]; then
                git log -p --follow --color=always -- "$filepath" | less -R
            fi
            ;;
    esac
}

# 8. 标签管理
tag_management() {
    show_header
    echo -e "${BOLD}   🏷️ 标签管理${NC}"
    echo ""
    
    # 显示现有标签
    local tags=$(git tag -l)
    if [ -n "$tags" ]; then
        echo -e "   ${DIM}现有标签:${NC}"
        git tag -l --sort=-version:refname | head -10 | while read -r tag; do
            local msg=$(git tag -l -n1 "$tag" | cut -d' ' -f2-)
            echo -e "      ${GREEN}$tag${NC} - $msg"
        done
        echo ""
    else
        info "暂无标签"
        echo ""
    fi
    
    echo -e "   ${CYAN}[1]${NC} 创建轻量标签"
    echo -e "   ${CYAN}[2]${NC} 创建附注标签 (推荐)"
    echo -e "   ${CYAN}[3]${NC} 删除标签"
    echo -e "   ${CYAN}[4]${NC} 推送标签到远程"
    echo -e "   ${CYAN}[0]${NC} 返回"
    echo ""
    read -p "   请选择: " choice
    
    case $choice in
        1)
            echo ""
            read -p "   输入标签名 (如 v1.0.0): " tag_name
            if [ -n "$tag_name" ]; then
                git tag "$tag_name"
                success "标签 '$tag_name' 创建成功"
            fi
            ;;
        2)
            echo ""
            read -p "   输入标签名 (如 v1.0.0): " tag_name
            read -p "   输入标签描述: " tag_msg
            if [ -n "$tag_name" ]; then
                git tag -a "$tag_name" -m "${tag_msg:-Release $tag_name}"
                success "附注标签 '$tag_name' 创建成功"
            fi
            ;;
        3)
            echo ""
            read -p "   输入要删除的标签名: " tag_name
            if [ -n "$tag_name" ]; then
                git tag -d "$tag_name"
                success "本地标签 '$tag_name' 已删除"
                read -p "   是否同时删除远程标签? [y/N]: " del_remote
                if [[ "$del_remote" == "y" || "$del_remote" == "Y" ]]; then
                    git push origin ":refs/tags/$tag_name"
                    success "远程标签已删除"
                fi
            fi
            ;;
        4)
            echo ""
            read -p "   推送所有标签? [Y/n]: " push_all
            if [[ "$push_all" != "n" && "$push_all" != "N" ]]; then
                git push --tags
                success "所有标签已推送"
            else
                read -p "   输入要推送的标签名: " tag_name
                if [ -n "$tag_name" ]; then
                    git push origin "$tag_name"
                    success "标签 '$tag_name' 已推送"
                fi
            fi
            ;;
    esac
    
    echo ""
    read -p "   按回车继续..."
}

# 9. 高级操作
advanced_ops() {
    show_header
    echo -e "${BOLD}   🔧 高级操作${NC}"
    echo ""
    
    echo -e "   ${CYAN}[1]${NC} 📦 储藏更改 (stash)"
    echo -e "   ${CYAN}[2]${NC} 📤 恢复储藏"
    echo -e "   ${CYAN}[3]${NC} 🍒 Cherry-pick 提交"
    echo -e "   ${CYAN}[4]${NC} 📝 修改最后一次提交"
    echo -e "   ${CYAN}[5]${NC} 🔍 查找引入 Bug 的提交 (bisect)"
    echo -e "   ${CYAN}[6]${NC} 📋 查看某行代码的作者 (blame)"
    echo -e "   ${CYAN}[7]${NC} 🗑️  清理未跟踪文件"
    echo -e "   ${CYAN}[8]${NC} ⚙️  查看/编辑 Git 配置"
    echo -e "   ${CYAN}[0]${NC} 返回"
    echo ""
    read -p "   请选择: " choice
    
    case $choice in
        1)
            echo ""
            read -p "   输入储藏描述 [可选]: " stash_msg
            if [ -n "$stash_msg" ]; then
                git stash push -m "$stash_msg"
            else
                git stash push
            fi
            success "更改已储藏"
            ;;
        2)
            echo ""
            local stashes=$(git stash list)
            if [ -n "$stashes" ]; then
                echo -e "   ${DIM}储藏列表:${NC}"
                git stash list | while IFS= read -r line; do
                    echo "      $line"
                done
                echo ""
                read -p "   输入储藏编号 (如 0): " stash_num
                git stash pop "stash@{$stash_num}"
                success "储藏已恢复"
            else
                info "没有储藏的更改"
            fi
            ;;
        3)
            echo ""
            read -p "   输入要 cherry-pick 的提交 Hash: " hash
            if [ -n "$hash" ]; then
                git cherry-pick "$hash"
                success "Cherry-pick 完成"
            fi
            ;;
        4)
            echo ""
            echo -e "   ${CYAN}[1]${NC} 只修改提交信息"
            echo -e "   ${CYAN}[2]${NC} 追加更改到最后提交"
            read -p "   请选择: " amend_choice
            case $amend_choice in
                1)
                    read -p "   输入新的提交信息: " new_msg
                    git commit --amend -m "$new_msg"
                    success "提交信息已修改"
                    ;;
                2)
                    git add -A
                    git commit --amend --no-edit
                    success "更改已追加到最后提交"
                    ;;
            esac
            ;;
        5)
            echo ""
            info "Git bisect 帮助你找到引入 Bug 的提交"
            echo ""
            echo -e "   ${CYAN}[1]${NC} 开始 bisect"
            echo -e "   ${CYAN}[2]${NC} 标记当前为好 (good)"
            echo -e "   ${CYAN}[3]${NC} 标记当前为坏 (bad)"
            echo -e "   ${CYAN}[4]${NC} 结束 bisect"
            read -p "   请选择: " bisect_choice
            case $bisect_choice in
                1) git bisect start; success "Bisect 已开始" ;;
                2) git bisect good; info "已标记为 good" ;;
                3) git bisect bad; info "已标记为 bad" ;;
                4) git bisect reset; success "Bisect 已结束" ;;
            esac
            ;;
        6)
            echo ""
            read -p "   输入文件路径: " filepath
            if [ -n "$filepath" ] && [ -f "$filepath" ]; then
                git blame --color-by-age "$filepath" | less -R
            else
                error "文件不存在"
            fi
            ;;
        7)
            echo ""
            local untracked=$(git clean -n -d)
            if [ -n "$untracked" ]; then
                echo -e "   ${YELLOW}将删除以下文件/目录:${NC}"
                echo "$untracked"
                echo ""
                read -p "   确认删除? 输入 'DELETE' 确认: " confirm
                if [ "$confirm" = "DELETE" ]; then
                    git clean -fd
                    success "清理完成"
                fi
            else
                info "没有需要清理的文件"
            fi
            ;;
        8)
            echo ""
            echo -e "   ${DIM}当前 Git 配置:${NC}"
            echo ""
            echo "   user.name:  $(git config user.name)"
            echo "   user.email: $(git config user.email)"
            echo ""
            read -p "   是否修改配置? [y/N]: " modify
            if [[ "$modify" == "y" || "$modify" == "Y" ]]; then
                read -p "   输入 user.name: " name
                read -p "   输入 user.email: " email
                [ -n "$name" ] && git config user.name "$name"
                [ -n "$email" ] && git config user.email "$email"
                success "配置已更新"
            fi
            ;;
    esac
    
    echo ""
    read -p "   按回车继续..."
}

# 主循环
main() {
    check_git_repo
    
    while true; do
        show_header
        show_main_menu
        read -p "   请选择 [0-9]: " choice
        
        case $choice in
            1) view_history ;;
            2) view_status ;;
            3) commit_changes ;;
            4) rollback ;;
            5) branch_management ;;
            6) push_pull ;;
            7) view_diff ;;
            8) tag_management ;;
            9) advanced_ops ;;
            0)
                echo ""
                echo -e "   ${GREEN}👋 再见！${NC}"
                echo ""
                exit 0
                ;;
            *)
                warning "无效选择，请重试"
                sleep 1
                ;;
        esac
    done
}

# 运行
main "$@"


