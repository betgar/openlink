#!/bin/bash

set -e  # 出错时退出

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 构建单个平台的服务端
build_server_current() {
    log_info "构建服务端 (当前平台)..."
    
    if ! command_exists go; then
        log_error "go 未安装，无法构建服务端"
        exit 1
    fi
    
    cd "$ROOT_DIR"
    go build -o openlink cmd/server/main.go
    
    if [ $? -eq 0 ]; then
        log_success "服务端构建成功: $(pwd)/openlink"
        
        # 验证二进制是否可执行
        if [ -x "./openlink" ]; then
            log_info "二进制信息: $(file openlink)"
        fi
    else
        log_error "服务端构建失败"
        exit 1
    fi
}

# 构建所有平台的服务端
build_server_all() {
    log_info "构建服务端 (所有平台)..."
    
    if ! command_exists go; then
        log_error "go 未安装，无法构建服务端"
        exit 1
    fi
    
    if ! command_exists goreleaser; then
        log_error "goreleaser 未安装，无法构建多平台版本。请运行: brew install goreleaser/tap/goreleaser"
        exit 1
    fi
    
    cd "$ROOT_DIR"
    
    # 备份当前的 dist 目录，避免被 goreleaser 清理掉
    if [ -d "dist" ] && [ "$(ls -A dist/)" ]; then
        log_info "备份现有 dist/ 目录..."
        mv dist dist_backup
    fi
    
    # 使用 goreleaser 构建所有平台（快照模式，不发布），使用自定义输出目录
    goreleaser build --snapshot --clean --single-target=false --output-dir dist
    
    # 恢复原 dist 目录（如果有）
    if [ -d "dist_backup" ]; then
        log_info "合并现有 dist/ 和构建产物..."
        cp -r dist_backup/* dist/ 2>/dev/null || true
        rm -rf dist_backup
    fi
    
    if [ $? -eq 0 ]; then
        log_success "所有平台服务端构建成功"
        log_info "构建产物位于 dist/ 目录:"
        ls -la dist/
    else
        log_error "多平台服务端构建失败"
        exit 1
    fi
}

# 构建扩展并打包
build_extension() {
    log_info "构建扩展..."
    
    if ! command_exists npm; then
        log_error "npm 未安装，无法构建扩展"
        exit 1
    fi
    
    cd "$ROOT_DIR/extension"
    
    # 确保依赖安装
    npm install
    
    # 构建扩展
    npm run build
    
    if [ $? -ne 0 ]; then
        log_error "扩展构建失败"
        exit 1
    fi
    
    # 验证构建产物
    if [ -d "dist" ]; then
        log_success "扩展构建成功: $ROOT_DIR/extension/dist"
        log_info "构建产出的内容:"
        ls -la dist/
    else
        log_error "构建成功但 dist 目录不存在"
        exit 1
    fi
    
    # 生成 ZIP 文件用于分发
    log_info "打包扩展为 ZIP 文件..."
    
    cd dist
    
    if command_exists zip; then
        DATE=$(date +%Y%m%d_%H%M%S)
        ZIP_NAME="$ROOT_DIR/openlink-extension-$DATE.zip"
        zip -r "$ZIP_NAME" .
        
        if [ $? -eq 0 ]; then
            log_success "扩展打包成功: $ZIP_NAME"
        else
            log_error "扩展打包失败"
            exit 1
        fi
    else
        log_warn "zip 命令未找到，跳过打包。若需打包请使用: brew install zip"
    fi
}

# 构建服务端和扩展
build_all() {
    log_info "构建完整的 OpenLink..."
    
    # 构建服务端（当前平台）
    build_server_current
    echo ""
    
    # 构建扩展
    build_extension
    
    log_success "完整构建完成！"
}

# 清理构建产物
cleanup() {
    log_info "清理构建产物..."
    
    cd "$ROOT_DIR"
    
    # 清理服务端产物
    if [ -f "openlink" ] || [ -f "openlink.exe" ]; then
        rm -f openlink openlink.exe
        log_info "已删除: $ROOT_DIR/openlink"
    fi
    
    # 清理扩展输出的 ZIP 文件
    for zip_file in openlink-extension-*.zip; do
        if [ -f "$zip_file" ]; then
            rm "$zip_file"
            log_info "已删除: $ROOT_DIR/$zip_file"
        fi
    done
    
    # 询问是否清理 dist 目录
    if [ -d "dist" ]; then
        echo -n "是否清理 dist/ 目录? [y/N] "
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -rf "dist"
            log_info "已删除: $ROOT_DIR/dist/"
        else
            log_info "跳过删除: $ROOT_DIR/dist/"
        fi
    fi
    
    # 清理扩展产物 (询问是否删除以避免每次开发重置整个 dist 目录)
    if [ -d "extension/dist" ]; then
        echo -n "是否清理 extension/dist/ 目录? [y/N] "
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -rf "extension/dist"
            log_info "已删除: $ROOT_DIR/extension/dist/"
        else
            log_info "跳过删除: $ROOT_DIR/extension/dist/"
        fi
    fi
    
    log_success "清理完成"
}

# 显示帮助信息
show_help() {
    echo "OpenLink 本地构建脚本"
    echo "用法: ./scripts/build.sh [command]"
    echo ""
    echo "命令选项:"
    echo "  server        构建服务端 (当前平台)，输出: ./openlink"
    echo "  server-all    构建服务端 (所有平台)，输出: dist/"
    echo "  extension     构建扩展 + 打包成 zip"
    echo "  all           构建服务端和扩展 (完整构建)"
    echo "  clean         清理所有构建产物"
    echo "  help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./scripts/build.sh server        # 构建当前平台服务端"
    echo "  ./scripts/build.sh all           # 构建完整项目用于验证"
    echo "  ./scripts/build.sh clean         # 清理构建产物"
}

# 主函数
main() {
    case "${1:-}" in
        "server")
            build_server_current
            ;;
        "server-all")
            build_server_all
            ;;
        "extension")
            build_extension
            ;;
        "all")
            build_all
            ;;
        "clean")
            cleanup
            ;;
        "help"|"-h"|""|"--help")
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 检查参数数量并调用主函数
main "$@"