#!/bin/bash

# t Installation Script
# Usage: ./install.sh

set -e

echo "=========================="
echo "      🌍 t Installer"
echo "=========================="
echo ""

# Check if Elixir is installed
if ! command -v elixir &> /dev/null; then
    echo "❌ Error: Elixir not detected"
    echo "Please install Elixir first: https://elixir-lang.org/install.html"
    exit 1
fi

echo "✓ Elixir version: $(elixir --version | head -n 1)"
echo ""

# Get dependencies
echo "📦 Fetching dependencies..."
mix deps.get

# Compile project
echo "🔨 Compiling project..."
mix compile

# Build executable
echo "🏗️  Building executable..."
mix clean
mix escript.build

echo ""
echo "✅ Installation successful!"
echo ""

# Ask if user wants to install to system path
read -p "Install t to /usr/local/bin? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -w "/usr/local/bin" ]; then
        mv t /usr/local/bin/
        echo "✓ Installed to /usr/local/bin/t"
    else
        sudo mv t /usr/local/bin/
        echo "✓ Installed to /usr/local/bin/t (requires sudo)"
    fi
    echo ""
    echo "You can now use the 't' command from anywhere"
else
    echo "Skipped system installation"
    echo "You can run the program with './t'"
    echo "Or manually copy: sudo cp t /usr/local/bin/"
fi

echo ""
echo "🎉 Next steps:"
echo "  1. Run 't --help' to view help"
echo "  2. Edit ~/.t/config.toml to add API keys (optional)"
echo "  3. Start translating: t 你好 --to=en"
echo ""
echo "Documentation: See README.md for detailed usage"
