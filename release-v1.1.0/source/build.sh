#!/bin/bash
# Build Buidl from source

echo "=== Building Buidl v1.1.0 from Source ==="

# Check for Hype framework
if ! command -v hype &> /dev/null; then
    echo "❌ Hype framework not found!"
    echo "Install from: https://github.com/twilson63/hype"
    echo "Or run: curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install.sh | bash"
    exit 1
fi

echo "✅ Hype framework found"
echo "Version: $(hype version)"

# Build all binaries
echo ""
echo "🏗️ Building binaries..."

echo "Building WebSocket Socket Mode (recommended)..."
hype build buidl_socket_mode_bundle.lua -o buidl-socket

echo "Building HTTP Events API mode (fallback)..."
hype build simple_buidl.lua -o buidl-http

echo "Building configuration utility..."
hype build create_config_bundle.lua -o buidl-config

echo "Building test suite..."
hype build test_bundle.lua -o buidl-test

echo ""
echo "✅ Build complete!"
echo ""
echo "Binaries created:"
echo "- buidl-socket   (WebSocket Socket Mode - recommended)"
echo "- buidl-http     (HTTP Events API - fallback)"
echo "- buidl-config   (Configuration utility)"
echo "- buidl-test     (Test suite)"
echo ""
echo "Quick start:"
echo "1. ./buidl-config        # Create configuration"
echo "2. nano .env             # Edit with your tokens"
echo "3. ./buidl-test          # Run tests"
echo "4. ./buidl-socket        # Start bot"
echo ""
echo "For help: cat README.md"
