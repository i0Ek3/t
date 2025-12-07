# Makefile

.PHONY: help install build clean test run deps format check install-system uninstall

# 默认目标
.DEFAULT_GOAL := help

# 颜色定义
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Language detection
LANG_ARG := $(filter zh en,$(MAKECMDGOALS))
ifeq ($(LANG_ARG),zh)
    LANG_INDEX := 2
else
    LANG_INDEX := 1
endif

help: ## Show help message | 显示帮助信息
	@echo "$(CYAN)t - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {split($$2, desc, " \\| "); printf "  $(GREEN)%-15s$(NC) %s\n", $$1, desc[$(LANG_INDEX)] ? desc[$(LANG_INDEX)] : desc[1]}'
	@echo ""

# Dummy targets for language arguments
en:
	@:

install: ## Install (deps + build) | 一键安装（依赖 + 构建）
	@echo "$(CYAN)Installing t...$(NC)"
	@mix deps.get
	@mix escript.build
	@echo "$(GREEN)✅ Installation complete!$(NC)"
	@echo "Run: $(YELLOW)./t --help$(NC)"

build: ## Build executable | 构建可执行文件
	@echo "$(CYAN)Building executable...$(NC)"
	@mix escript.build
	@echo "$(GREEN)✅ Build complete: ./t$(NC)"

deps: ## Install dependencies | 安装依赖
	@echo "$(CYAN)Installing dependencies...$(NC)"
	@mix deps.get
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

clean: ## Clean build files | 清理构建文件
	@echo "$(CYAN)Cleaning build files...$(NC)"
	@mix clean
	@rm -f t
	@echo "$(GREEN)✅ Clean complete$(NC)"

test: ## Run tests | 运行测试（如果有）
	@echo "$(CYAN)Running tests...$(NC)"
	@mix test

format: ## Format code | 格式化代码
	@echo "$(CYAN)Formatting code...$(NC)"
	@mix format
	@echo "$(GREEN)✅ Code formatted$(NC)"

check: ## Check code | 检查代码（编译 + 格式检查）
	@echo "$(CYAN)Checking code...$(NC)"
	@mix compile --warnings-as-errors
	@mix format --check-formatted
	@echo "$(GREEN)✅ Code check passed$(NC)"

run: build ## Run example | 构建并运行示例
	@echo "$(CYAN)Running example...$(NC)"
	@./t 你好 -to=en

install-system: build ## Install to system path (requires sudo) | 安装到系统路径（需要 sudo）
	@echo "$(CYAN)Installing to /usr/local/bin...$(NC)"
	@sudo cp t /usr/local/bin/
	@echo "$(GREEN)✅ Installed! Use: t --help$(NC)"

uninstall: ## Uninstall from system path | 从系统路径卸载
	@echo "$(CYAN)Uninstalling from /usr/local/bin...$(NC)"
	@sudo rm -f /usr/local/bin/t
	@echo "$(GREEN)✅ Uninstalled$(NC)"

config: ## Open config file | 打开配置文件
	@if [ -f "$$HOME/.t/config.toml" ]; then \
		$$EDITOR $$HOME/.t/config.toml || vim $$HOME/.t/config.toml; \
	else \
		echo "$(YELLOW)Config file not found. Run ./t first.$(NC)"; \
	fi

history: build ## View translation history | 查看翻译历史
	@./t --history

stats: build ## View statistics | 查看统计信息
	@./t --stats

languages: build ## List supported languages | 列出支持的语言
	@./t --languages

# 开发相关
dev-setup: ## Setup dev environment | 开发环境设置
	@echo "$(CYAN)Setting up development environment...$(NC)"
	@mix deps.get
	@mix compile
	@echo "$(GREEN)✅ Development environment ready$(NC)"

dev-watch: ## Watch for changes | 监听文件变化并重新构建
	@echo "$(CYAN)Watching for changes...$(NC)"
	@while true; do \
		inotifywait -r -e modify lib/ 2>/dev/null || fswatch -o lib/; \
		clear; \
		make build; \
	done

# 快捷命令
tr: build ## Quick translate to English | 快捷命令：翻译到英文（需要传入文本）
	@$(if $(filter help,$(MAKECMDGOALS)),,./t "$(TEXT)" -to=en)

zh: build ## Quick translate to Chinese | 快捷命令：翻译到中文（需要传入文本）
	@$(if $(filter help,$(MAKECMDGOALS)),,./t "$(TEXT)" -to=zh)

# 示例用法：
# make tr TEXT="你好"
# make zh TEXT="Hello"

# 打包和发布
package: clean build ## Package project | 打包项目
	@echo "$(CYAN)Packaging project...$(NC)"
	@mkdir -p dist
	@cp t dist/
	@cp README.md dist/
	@cp README_zh-CN.md dist/
	@cp config.toml.example dist/
	@tar -czf t-v0.2.0.tar.gz dist/
	@rm -rf dist
	@echo "$(GREEN)✅ Package created: t-v0.2.0.tar.gz$(NC)"

# 版本信息
version: build ## Show version info | 显示版本信息
	@./t --version

# Docker 相关（可选）
docker-build: ## Build Docker image | 构建 Docker 镜像
	@echo "$(CYAN)Building Docker image...$(NC)"
	@docker build -t t .
	@echo "$(GREEN)✅ Docker image built$(NC)"

docker-run: ## Run Docker container | 运行 Docker 容器
	@docker run -it --rm t

# 文档生成
docs: ## Generate documentation | 生成文档
	@echo "$(CYAN)Generating documentation...$(NC)"
	@mix docs
	@echo "$(GREEN)✅ Documentation generated$(NC)"

# 性能分析
profile: build ## Run performance analysis | 性能分析
	@echo "$(CYAN)Running performance analysis...$(NC)"
	@time ./t "This is a test sentence" -to=zh

# 全面检查（CI/CD 用）
ci: deps check test ## CI pipeline | CI 流程：依赖 + 检查 + 测试
	@echo "$(GREEN)✅ CI checks passed$(NC)"

# 更新依赖
update-deps: ## Update dependencies | 更新依赖
	@echo "$(CYAN)Updating dependencies...$(NC)"
	@mix deps.update --all
	@echo "$(GREEN)✅ Dependencies updated$(NC)"

# 显示项目信息
info: ## Show project info | 显示项目信息
	@echo "$(CYAN)Project Information:$(NC)"
	@echo "  Name: t"
	@echo "  Version: 0.1.0"
	@echo "  Elixir: $$(elixir --version | grep Elixir | awk '{print $$2}')"
	@echo "  Config: ~/.t/config.toml"
	@echo "  History: ~/.t/.t_history.json"
	@echo ""
	@echo "$(CYAN)Quick Commands:$(NC)"
	@echo "  make install        - Install everything"
	@echo "  make run            - Run example"
	@echo "  make tr TEXT='你好'  - Quick t to English"
	@echo "  make help           - Show all commands"