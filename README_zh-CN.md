# 🌍 t - 命令行翻译工具

[English](https://github.com/i0Ek3/t/blob/main/README.md)

一个功能强大的命令行翻译工具，使用 Elixir 构建。支持 60+ 种语言、AI 驱动的翻译、本地模型和精美的 CLI 输出。

![Elixir](https://img.shields.io/badge/Elixir-1.19+-purple.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

### ✨ 特性

- 🌐 **60+ 种语言** - 支持任意语言对之间的翻译
- 🤖 **AI 驱动** - 多个 AI 提供商（Claude、Cohere、OpenAI）
- 💻 **本地模型** - 支持 Ollama 本地模型
- 📚 **单词解释** - 获取定义、音标和词性
- 💡 **例句** - 通过上下文例句学习
- 📜 **历史追踪** - 保存和搜索翻译历史
- 📊 **统计** - 跟踪您的翻译使用情况
- 🎨 **精美输出** - 彩色、格式良好的 CLI 界面
- 🔄 **自动回退** - 自动在服务之间切换
- ⚡ **快速可靠** - 高效缓存和错误处理

### 📋 前置要求

- **Elixir** 1.19 或更高版本
- **Erlang** 28 或更高版本
- （可选）**Ollama** 用于本地模型支持

#### 安装 Elixir

**macOS:**
```bash
brew install elixir
```

**Ubuntu/Debian:**
```bash
sudo apt-get install elixir
```

**Windows:**
从 [elixir-lang.org](https://elixir-lang.org/install.html) 下载

**验证安装:**
```bash
elixir --version
```

### 🚀 安装

#### 1. 克隆仓库

```bash
git clone https://github.com/i0Ek3/t.git
cd t
```

#### 2. 安装依赖并构建可执行文件

```bash
./install.sh

# 或者
make install
```

#### 3. （可选）添加到 PATH

**Linux/macOS:**
```bash
sudo cp t /usr/local/bin/
# 或
echo 'export PATH="$PATH:'"$(pwd)"'"' >> ~/.bashrc
source ~/.bashrc
```

**Windows:**
将项目目录添加到 PATH 环境变量。

### ⚙️ 配置

首次运行时，将在 `~/.t/config.toml` 创建配置文件。

#### 基本配置

```toml
[general]
default_target_language = "en"
enable_history = true

[translation]
default_mode = "api"  # "api" 或 "ai"
word_explanation_source = "dictionary"  # "dictionary"、"ai" 或 "auto"
show_examples = true
```

#### API 配置（免费）

```toml
[api]
provider = "libretranslate"  # "libretranslate"、"mymemory" 或 "google"
libretranslate_url = "https://libretranslate.com/translate"
# 或者在本地运行 libretranslate
```

#### AI 配置

**Claude（推荐）:**
```toml
[ai.claude]
api_key = "your-claude-api-key"
model = "claude-sonnet-4-5-20250929"
```

获取免费 API 密钥：[console.anthropic.com](https://console.anthropic.com/)

**Cohere（有免费层）:**

```toml
[ai.cohere]
api_key = "your-cohere-api-key"
model = "command"
```

获取免费 API 密钥：[cohere.com](https://cohere.com/)

#### 本地模型配置（Ollama）

首先，安装 Ollama：
```bash
# macOS/Linux
curl -fsSL https://ollama.com/install.sh | sh

# 或访问 https://ollama.com
```

下载模型：
```bash
ollama pull llama3
# 或
ollama pull mistral
```

在 `config.toml` 中配置：
```toml
[ai.ollama]
enabled = true
base_url = "http://localhost:11434"
model = "llama3"  # 或 "mistral"、"codellama" 等
```

### 📖 使用方法

#### 基本翻译

```bash
# 翻译成英语
t 你好 --to=en

# 指定源语言翻译
t "Bonjour" --to=en

# 翻译短语
t "I love programming" --to=zh
```

#### AI 翻译

```bash
# 使用 AI（Claude/Cohere 自动回退）
t 我希望我们可以度过那一天 --to=es -ai=true

# 使用本地 Ollama 模型
t "Hello World" --to=fr -ai=local

# AI 带单词解释
t "sophisticated" --to=zh -ai=true --explain=ai
```

#### 自定义选项

```bash
# 使用字典进行单词解释
t "complex sentence" --to=zh --explain=dictionary

# 隐藏例句
t 你好 --to=en --no-examples

# 显示例句（默认）
t Hello --to=zh --examples
```

#### 历史管理

```bash
# 显示最近 10 条翻译
t --history

# 显示最近 20 条翻译
t --history 20

# 搜索历史
t --search "hello"

# 查看统计
t --stats

# 清除历史
t --clear
```

#### 信息

```bash
# 列出所有支持的语言
t --languages

# 显示帮助
t --help

# 显示版本
t --version
```

### 🌍 支持的语言

该工具支持 60+ 种语言，包括：

| 代码 | 语言 | 代码 | 语言 |
|------|----------|------|----------|
| en | 英语 | zh | 中文 |
| es | 西班牙语 | fr | 法语 |
| de | 德语 | ja | 日语 |
| ko | 韩语 | ru | 俄语 |
| ar | 阿拉伯语 | pt | 葡萄牙语 |
| it | 意大利语 | hi | 印地语 |
| tr | 土耳其语 | nl | 荷兰语 |

使用 `t --languages` 查看完整列表。

### 📄 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件。

### 🙏 致谢

- [LibreTranslate](https://libretranslate.com/) - 免费翻译 API
- [Anthropic Claude](https://www.anthropic.com/) - AI 翻译
- [Cohere](https://cohere.com/) - 带免费层的 AI
- [Ollama](https://ollama.com/) - 本地 LLM 支持
- [Free Dictionary API](https://dictionaryapi.dev/) - 单词定义

---

Made with ❤️ and Elixir
