#!/bin/bash
# Buidl Installation Script for macOS

INSTALL_DIR="/usr/local/buidl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing Buidl v1.1.0 for macOS ==="
echo "Installing to: $INSTALL_DIR"

# Create directories
sudo mkdir -p "$INSTALL_DIR/bin"
sudo mkdir -p "$INSTALL_DIR/config"

# Copy binaries
sudo cp "$SCRIPT_DIR/bin/"* "$INSTALL_DIR/bin/"
sudo chmod +x "$INSTALL_DIR/bin/"*

# Copy config template
sudo cp "$SCRIPT_DIR/config.env.example" "$INSTALL_DIR/config/.env.example"

# Create symlinks
sudo ln -sf "$INSTALL_DIR/bin/buidl-socket" /usr/local/bin/buidl
sudo ln -sf "$INSTALL_DIR/bin/buidl-http" /usr/local/bin/buidl-http
sudo ln -sf "$INSTALL_DIR/bin/buidl-config" /usr/local/bin/buidl-config
sudo ln -sf "$INSTALL_DIR/bin/buidl-test" /usr/local/bin/buidl-test

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. buidl-config          # Create configuration"
echo "2. nano ~/.buidl.env     # Edit configuration"
echo "3. buidl-test            # Run tests"
echo "4. buidl                 # Start bot (WebSocket mode)"
echo ""
echo "Alternative HTTP mode: buidl-http"
