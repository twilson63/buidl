#!/bin/bash
# Build script for Buidl from source

echo "=== Building Buidl from Source ==="

# Check for Hype framework
if ! command -v hype &> /dev/null; then
    echo "❌ Hype framework not found!"
    echo "Install from: https://github.com/twilson63/hype"
    exit 1
fi

echo "✅ Hype framework found"

# Build binaries
echo "🏗️ Building binaries..."
hype build src/buidl_socket_mode.lua -o buidl
hype build src/simple_buidl.lua -o buidl-http
hype build src/create_config_bundle.lua -o buidl-config
hype build src/test_bundle.lua -o buidl-test

echo "✅ Build complete!"
echo ""
echo "Binaries created:"
echo "- buidl         (WebSocket Socket Mode - recommended)"
echo "- buidl-http    (HTTP Events API - fallback)"
echo "- buidl-config  (Configuration utility)"
echo "- buidl-test    (Test suite)"
echo ""
echo "Next steps:"
echo "1. ./buidl-config"
echo "2. Edit config/.env"
echo "3. ./buidl-test"
echo "4. ./buidl"
