#!/bin/bash
#===============================================================================
# wechat-publisher - 微信公众号发布脚本
# 
# 使用方式: ./publish.sh <markdown_file> [theme] [highlight]
# 示例: 
#   ./publish.sh article.md lapis solarized-light
#   ./publish.sh article.md
#===============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
THEME="${WENYAN_THEME:-lapis}"
HIGHLIGHT="${WENYAN_HIGHLIGHT:-solarized-light}"
HUMANIZE="${WECHAT_HUMANIZE:-true}"
INTENSITY="${WECHAT_HUMANIZE_INTENSITY:-medium}"
TEMP_DIR="/tmp/wechat-publisher-$$"

# 帮助信息
show_help() {
    cat << EOF
${BLUE}wechat-publisher - 微信公众号发布工具${NC}

${YELLOW}使用方法:${NC}
    $0 <markdown_file> [theme] [highlight]

${YELLOW}参数:${NC}
    markdown_file    Markdown 文件路径（必填）
    theme           主题名称（可选，默认: lapis）
    highlight       代码高亮主题（可选，默认: solarized-light）

${YELLOW}可用主题:${NC}
    lapis        蓝色优雅 - 技术文章、教程
    phycat       绿色清新 - 博客、随笔
    default      经典简约 - 通用场景
    orange       橙色活力 - 产品介绍
    purple       紫色神秘 - 设计、创意

${YELLOW}可用代码高亮:${NC}
    solarized-light, monokai, github, atom-one-dark, 
    dracula, nord, vs2015, highlightjs, prism

${YELLOW}环境变量:${NC}
    WENYAN_THEME              主题名称
    WENYAN_HIGHLIGHT          代码高亮主题
    WECHAT_HUMANIZE           是否启用 AI 去痕 (true/false)
    WECHAT_HUMANIZE_INTENSITY 去痕强度 (light/medium/heavy)
    WECHAT_APP_ID             微信 AppID
    WECHAT_APP_SECRET         微信 AppSecret

${YELLOW}示例:${NC}
    $0 article.md lapis solarized-light
    WENYAN_THEME=phycat $0 article.md
    WECHAT_HUMANIZE=false $0 article.md

EOF
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 清理函数
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    # 检查 wenyan-cli
    if ! command -v wenyan &> /dev/null; then
        log_error "wenyan-cli 未安装，请运行: npm install -g @wenyan-md/cli"
        exit 1
    fi
    
    # 检查 wechat-publisher
    if ! command -v python3 &> /dev/null; then
        log_error "python3 未安装"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 检查配置文件
check_config() {
    log_info "检查配置文件..."
    
    # 尝试从 ~/.openclaw/.env 加载配置
    ENV_FILE="$HOME/.openclaw/.env"
    if [[ -f "$ENV_FILE" ]]; then
        log_info "从 $ENV_FILE 加载环境变量"
        set -a
        source "$ENV_FILE"
        set +a
    fi
    
    # 检查必要配置
    if [[ -z "$WECHAT_APP_ID" ]] && [[ -z "${WECHAT_PUBLISHER_WECHAT_APP_ID:-}" ]]; then
        log_warning "未设置 WECHAT_APP_ID"
    fi
    
    if [[ -z "$WECHAT_APP_SECRET" ]] && [[ -z "${WECHAT_PUBLISHER_WECHAT_APP_SECRET:-}" ]]; then
        log_warning "未设置 WECHAT_APP_SECRET"
    fi
}

# 解析 frontmatter
parse_frontmatter() {
    local file="$1"
    local title=""
    local cover=""
    
    if [[ -f "$file" ]]; then
        # 使用 sed 提取 frontmatter
        title=$(sed -n '/^---$/,/^---$/p' "$file" | grep -A1 '^title:' | tail -1 | sed 's/^[[:space:]]*//' | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//")
        cover=$(sed -n '/^---$/,/^---$/p' "$file" | grep -A1 '^cover:' | tail -1 | sed 's/^[[:space:]]*//' | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//")
    fi
    
    echo "$title|$cover"
}

# 主流程
main() {
    # 解析参数
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    if [[ $# -lt 1 ]]; then
        log_error "缺少必填参数：markdown_file"
        show_help
        exit 1
    fi
    
    local markdown_file="$1"
    [[ $# -ge 2 ]] && THEME="$2"
    [[ $# -ge 3 ]] && HIGHLIGHT="$3"
    
    # 检查文件是否存在
    if [[ ! -f "$markdown_file" ]]; then
        log_error "文件不存在: $markdown_file"
        exit 1
    fi
    
    # 转换为绝对路径
    markdown_file="$(cd "$(dirname "$markdown_file")" && pwd)/$(basename "$markdown_file")"
    log_info "Markdown 文件: $markdown_file"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    local output_html="$TEMP_DIR/output.html"
    
    # 检查依赖
    check_dependencies
    
    # 检查配置
    check_config
    
    # 解析 frontmatter 获取标题和封面
    local fm_result
    fm_result=$(parse_frontmatter "$markdown_file")
    local article_title
    local article_cover
    article_title=$(echo "$fm_result" | cut -d'|' -f1)
    article_cover=$(echo "$fm_result" | cut -d'|' -f2)
    
    if [[ -n "$article_title" ]]; then
        log_info "文章标题: $article_title"
    else
        article_title="$(basename "$markdown_file" .md)"
        log_warning "未在 frontmatter 中找到标题，使用文件名: $article_title"
    fi
    
    if [[ -n "$article_cover" ]]; then
        log_info "封面图: $article_cover"
    else
        log_warning "未在 frontmatter 中找到封面图"
    fi
    
    # Step 1: 使用 wenyan-cli 转换 Markdown 为 HTML
    log_info "${BLUE}Step 1:${NC} 使用 wenyan-cli 转换 Markdown → HTML"
    log_info "主题: $THEME, 代码高亮: $HIGHLIGHT"
    
    # wenyan render 输出到 stdout，需要重定向到文件
    wenyan render \
        -f "$markdown_file" \
        -t "$THEME" \
        --highlight "$HIGHLIGHT" \
        > "$output_html" 2>&1
        
    if [[ ! -f "$output_html" ]] || [[ ! -s "$output_html" ]]; then
        log_error "wenyan 转换失败，未生成输出文件"
        cat "$output_html" 2>/dev/null || true
        exit 1
    fi
    
    log_success "wenyan 转换完成: $output_html"
    
    # Step 2: 使用 wechat-publisher 发布到微信草稿箱
    log_info "${BLUE}Step 2:${NC} 发布到微信公众号草稿箱"
    
    # 构建发布命令
    local publish_cmd="python3 -m wechat_publisher publish \"$output_html\""
    
    [[ -n "$article_title" ]] && publish_cmd="$publish_cmd --title \"$article_title\""
    [[ -n "$article_cover" ]] && publish_cmd="$publish_cmd --cover \"$article_cover\""
    
    if [[ "$HUMANIZE" != "true" ]]; then
        publish_cmd="$publish_cmd --no-humanize"
        log_info "AI 去痕: 禁用"
    else
        publish_cmd="$publish_cmd --intensity $INTENSITY"
        log_info "AI 去痕: 启用 (强度: $INTENSITY)"
    fi
    
    # 执行发布命令
    log_info "执行: $publish_cmd"
    cd /root/.openclaw/workspace/article/skills/wechat-publisher && PYTHONPATH=src $publish_cmd
    
    log_success "发布完成！"
    log_info "请前往微信公众号后台草稿箱查看: https://mp.weixin.qq.com/"
}

main "$@"
