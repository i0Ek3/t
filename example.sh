#!/bin/bash

# t - 使用示例脚本
# 展示各种功能的使用方法

set -e

# 颜色定义
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 可执行文件路径
TRANSLATE="./t"

# 检查可执行文件是否存在
if [ ! -f "$TRANSLATE" ]; then
    echo -e "${YELLOW}Executable not found. Building...${NC}"
    make build
fi

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                     t - Usage Examples                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

pause() {
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
    echo ""
}

# 示例 1：基础翻译
echo -e "${GREEN}Example 1: Basic Translation${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE 你好世界 -to=en"
echo ""
$TRANSLATE 你好世界 -to=en
pause

# 示例 2：指定源语言
echo -e "${GREEN}Example 2: Translation with Source Language${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE Bonjour -to=en -from=fr"
echo ""
$TRANSLATE Bonjour -to=en -from=fr
pause

# 示例 3：翻译短语
echo -e "${GREEN}Example 3: Translate Phrase${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE \"I love programming\" -to=zh"
echo ""
$TRANSLATE "I love programming" -to=zh
pause

# 示例 4：AI 翻译（如果配置了）
echo -e "${GREEN}Example 4: AI Translation (if configured)${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE 我希望我们可以度过那一天 -to=es -ai=true"
echo ""
echo -e "${YELLOW}Note: This requires API key in config file${NC}"
echo -e "${YELLOW}If not configured, it will fall back to free API${NC}"
echo ""
$TRANSLATE 我希望我们可以度过那一天 -to=es -ai=true
pause

# 示例 5：使用字典解释
echo -e "${GREEN}Example 5: Translation with Dictionary Explanations${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE sophisticated -to=zh --explain=dictionary"
echo ""
$TRANSLATE sophisticated -to=zh --explain=dictionary
pause

# 示例 6：不显示例句
echo -e "${GREEN}Example 6: Translation without Examples${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE 你好 -to=en --no-examples"
echo ""
$TRANSLATE 你好 -to=en --no-examples
pause

# 示例 7：查看支持的语言
echo -e "${GREEN}Example 7: List Supported Languages${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE --languages"
echo ""
$TRANSLATE --languages
pause

# 示例 8：查看历史记录
echo -e "${GREEN}Example 8: View Translation History${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE --history 5"
echo ""
$TRANSLATE --history 5
pause

# 示例 9：搜索历史记录
echo -e "${GREEN}Example 9: Search History${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE --search hello"
echo ""
$TRANSLATE --search hello
pause

# 示例 10：查看统计信息
echo -e "${GREEN}Example 10: View Statistics${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE --stats"
echo ""
$TRANSLATE --stats
pause

# 示例 11：多语言链式翻译
echo -e "${GREEN}Example 11: Multiple Translations${NC}"
echo -e "${CYAN}Commands:${NC}"
echo "  $TRANSLATE Hello -to=zh"
echo "  $TRANSLATE Hello -to=fr"
echo "  $TRANSLATE Hello -to=es"
echo "  $TRANSLATE Hello -to=ja"
echo ""
$TRANSLATE Hello -to=zh
echo ""
$TRANSLATE Hello -to=fr
echo ""
$TRANSLATE Hello -to=es
echo ""
$TRANSLATE Hello -to=ja
pause

# 示例 12：长文本翻译
echo -e "${GREEN}Example 12: Long Text Translation${NC}"
echo -e "${CYAN}Command:${NC} $TRANSLATE \"The quick brown fox jumps over the lazy dog...\" -to=zh"
echo ""
$TRANSLATE "The quick brown fox jumps over the lazy dog. This is a common sentence used to test typewriters and keyboards." -to=zh
pause

# 总结
echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Examples Complete!                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GREEN}You've seen the main features of Translator CLI!${NC}"
echo ""
echo -e "${CYAN}Quick Reference:${NC}"
echo "  • Basic:      $TRANSLATE <text> -to=<lang>"
echo "  • AI:         $TRANSLATE <text> -to=<lang> -ai=true"
echo "  • History:    $TRANSLATE --history"
echo "  • Languages:  $TRANSLATE --languages"
echo "  • Help:       $TRANSLATE --help"
echo ""
echo -e "${CYAN}Configuration:${NC}"
echo "  • Config file: ~/.t/config.toml"
echo "  • Edit with:   nano ~/.t/config.toml"
echo ""
echo -e "${GREEN}Happy translating! 🌍${NC}"
echo ""