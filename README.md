# 🌍 t - A Translator CLI

[Chinese](https://github.com/i0Ek3/t/blob/main/README_zh-CN.md)

A powerful, feature-rich command-line translation tool built with Elixir. Supports 60+ languages, AI-powered translation, local models, and beautiful CLI output.

![Elixir](https://img.shields.io/badge/Elixir-1.19+-purple.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

### ✨ Features

- 🌐 **60+ Languages** - Translate between any supported language pair
- 🤖 **AI-Powered** - Multiple AI providers (Claude, Cohere, OpenAI)
- 💻 **Local Models** - Support for Ollama local models
- 📚 **Word Explanations** - Get definitions, phonetics, and part of speech
- 💡 **Example Sentences** - Learn with contextual examples, required AI mode
- 📜 **History Tracking** - Save and search translation history
- 📊 **Statistics** - Track your translation usage
- 🎨 **Beautiful Output** - Colorful, well-formatted CLI interface
- 🔄 **Auto Fallback** - Automatically switch between services
- ⚡ **Fast & Reliable** - Efficient caching and error handling

### 📋 Prerequisites

- **Elixir** 1.19 or higher
- **Erlang** 28 or higher
- (Optional) **Ollama** for local model support

#### Installing Elixir

**macOS:**
```bash
brew install elixir
```

**Ubuntu/Debian:**
```bash
sudo apt-get install elixir
```

**Windows:**
Download from [elixir-lang.org](https://elixir-lang.org/install.html)

**Verify installation:**
```bash
elixir --version
```

### 🚀 Installation

#### 1. Clone the repository

```bash
git clone https://github.com/i0Ek3/t.git
cd t
```

#### 2. Install dependencies & Build the executable

**Linux/macOS:**
```bash
./install.sh 

# or
make install
```

**Windows:**
```cmd
REM Using batch script
install.bat

REM Or using Make (if installed)
make install

REM Or manually
mix deps.get
mix escript.build
```

#### 3. (Optional) Add to PATH

**Linux/macOS:**
```bash
sudo cp t /usr/local/bin/
# or
echo 'export PATH="$PATH:'"$(pwd)"'"' >> ~/.bashrc
source ~/.bashrc
```

**Windows:**
Add the executable to PATH:
1. Press `Win + X` and select "System"
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "User variables", select "Path" and click "Edit"
5. Click "New" and add the project directory path
6. Click "OK" to save

Or run directly from the project directory:
```cmd
t.exe --help
```

### ⚙️ Configuration

On first run, a configuration file will be created at `~/.t/config.toml`.

#### Basic Configuration

```toml
[general]
default_target_language = "en"
enable_history = true

[translation]
default_mode = "api"  # "api" or "ai"
word_explanation_source = "dictionary"  # "dictionary", "ai", or "auto"
show_examples = true
```

#### API Configuration (Free)

```toml
[api]
provider = "libretranslate"  # "libretranslate", "mymemory", or "google"
libretranslate_url = "https://libretranslate.com/translate"
# or run libretranlate locally
```

#### AI Configuration

**Claude (Recommended):**
```toml
[ai.claude]
api_key = "your-claude-api-key"
model = "claude-sonnet-4-5-20250929"
```

Get free API key: [console.anthropic.com](https://console.anthropic.com/)

**Cohere (Free Tier Available):**

```toml
[ai.cohere]
api_key = "your-cohere-api-key"
model = "command"
```

Get free API key: [cohere.com](https://cohere.com/)

#### Local Model Configuration (Ollama)

First, install Ollama:
```bash
# macOS/Linux
curl -fsSL https://ollama.com/install.sh | sh

# Or visit https://ollama.com
```

Download a model:
```bash
ollama pull llama3
# or
ollama pull mistral
```

Configure in `config.toml`:
```toml
[ai.ollama]
enabled = true
base_url = "http://localhost:11434"
model = "llama3"  # or "mistral", "codellama", etc.
```

### 📖 Usage

> **Note for Windows users**: On Windows, use `t.exe` instead of `t`. For example: `t.exe "Hello" --to=zh`

#### Basic Translation

```bash
# Translate to English
t 你好 --to=en

# Translate with source language specified
t "Bonjour" --to=en

# Translate phrase
t "I love programming" --to=zh
```

#### AI Translation

```bash
# Use AI (Claude/Cohere with auto-fallback)
t 我希望我们可以度过那一天 --to=es -ai=true

# Use local Ollama model
t "Hello World" --to=fr -ai=local

# AI with word explanations
t "sophisticated" --to=zh -ai=true --explain=ai
```

#### Customization Options

```bash
# Use dictionary for word explanations
t "complex sentence" --to=zh --explain=dictionary
```

#### History Management

```bash
# Show last 10 translations
t --history

# Show last 20 translations
t --history 20

# Search history
t --search "hello"

# View statistics
t --stats

# Clear history
t --clear
```

#### Information

```bash
# List all supported languages
t --languages

# Show help
t --help

# Show version
t --version
```

### 🌍 Supported Languages

The tool supports 60+ languages including:

| Code | Language | Code | Language |
|------|----------|------|----------|
| en | English | zh | Chinese |
| es | Spanish | fr | French |
| de | German | ja | Japanese |
| ko | Korean | ru | Russian |
| ar | Arabic | pt | Portuguese |
| it | Italian | hi | Hindi |
| tr | Turkish | nl | Dutch |

Use `t --languages` for the complete list.

### 📊 Example Output

```
================================================================================
📝 Translation Result
================================================================================

Source: Chinese (zh)
  我爱编程

Target: English (en)
  I love programming

────────────────────────────────────────────────────────────────────────────────
📚 Word Explanations

  • programming
    Phonetic: /ˈproʊɡræmɪŋ/
    Definition: The process of writing computer programs
    Type: noun

────────────────────────────────────────────────────────────────────────────────
💡 Examples

  1.
    → I love programming in Python.
    → 我喜欢用Python编程。

  2.
    → Programming requires patience and practice.
    → 编程需要耐心和练习。

────────────────────────────────────────────────────────────────────────────────
Mode: ai • Provider: Claude (claude-sonnet-4-5-20250929) • Time: 1250ms
================================================================================
```

### 🔧 Advanced Usage

#### Using Different AI Providers

The tool automatically tries multiple AI providers in order:

1. **Claude** (if configured)
2. **Cohere** (if configured)
3. **OpenAI** (if configured)
4. **Falls back to free API** if all fail

#### Priority Configuration

Edit `config.toml`:
```toml
[ai]
providers = ["claude", "cohere", "openai"]
```

#### Custom LibreTranslate Instance

If you run your own LibreTranslate server:
```toml
[api]
provider = "libretranslate"
libretranslate_url = "http://localhost:5000/translate"
```

### 🎯 Use Cases

#### Learning Languages
```bash
# Get detailed word explanations
t "serendipity" --to=zh --explain=ai
```

#### Development Work
```bash
# Quick translation for UI text
t "Submit Form" --to=zh

# Batch translate from file (coming soon)
```

#### Content Creation
```bash
# AI translation for natural output
t "这是一篇关于..." --to=en -ai=true
```

### 🐛 Troubleshooting

#### "Config file not found"
The config file is created automatically on first run at `~/.t/config.toml`. Edit it to add your API keys.

#### "API key not configured"
Add your API key to `~/.t/config.toml`:
```toml
[ai.claude]
api_key = "sk-ant-..."
```

#### "Failed to connect to Ollama"
Make sure Ollama is running:
```bash
ollama serve
```

#### "Invalid language code"
Use `t --languages` to see all supported language codes. Common aliases work too (sp→es, cn→zh, jp→ja).

#### Rate Limiting

If you hit API rate limits, the tool will automatically fall back to alternative providers.

### 📁 File Locations

- **Config**: `~/.t/config.toml`
- **History**: `~/.t/.t_history.json`
- **Logs**: Logged to console

### 🔐 Privacy & Security

- All API keys are stored locally in `~/.t/config.toml`
- History is stored locally on your machine
- No data is sent to third parties except the translation services you configure
- You can disable history tracking in the config file

### 🛠️ Development

#### Running in Development

```bash
# Compile
mix compile

# Run tests (if available)
mix test

# Run with mix
mix escript.build && ./t "Hello" --to=zh

# Format code
mix format
```

#### Project Structure

```
t/
├── lib/
│   ├── t/
│   │   ├── application.ex      # App supervisor
│   │   ├── cli.ex              # CLI interface
│   │   ├── config.ex           # Config management
│   │   ├── history.ex          # History tracking
│   │   ├── language.ex         # Language codes
│   │   ├── output.ex           # Pretty printing
│   │   ├── translator.ex       # Main logic
│   │   └── engines/
│   │       ├── api_engine.ex   # Free APIs
│   │       ├── ai_engine.ex    # AI providers
│   │       └── dictionary_engine.ex
│   └── t.ex
├── config.toml.example         # Config template
├── mix.exs                     # Project config
└── README.md
```

### 📝 TODO

- [x] Support for more AI providers
- [ ] Add pronunciation/audio support
- [ ] Support batch translation from files
- [ ] Add more dictionary APIs
- [ ] Implement caching for repeated translations

### 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

### 🙏 Acknowledgments

- [LibreTranslate](https://libretranslate.com/) - Free translation API
- [Anthropic Claude](https://www.anthropic.com/) - AI translation
- [Cohere](https://cohere.com/) - AI with free tier
- [Ollama](https://ollama.com/) - Local LLM support
- [Free Dictionary API](https://dictionaryapi.dev/) - Word definitions

---

Made with ❤️ and Elixir
