-- build_release.lua
-- Build script for creating production release binaries

local function run_command(cmd, description)
    print("→ " .. description)
    print("  Running: " .. cmd)
    
    local result = os.execute(cmd)
    if result ~= 0 then
        print("  ❌ Failed: " .. description)
        os.exit(1)
    else
        print("  ✅ Success: " .. description)
    end
    print("")
end

local function create_directory(path)
    local cmd = "mkdir -p " .. path
    run_command(cmd, "Creating directory: " .. path)
end

local function copy_file(src, dst)
    local cmd = "cp " .. src .. " " .. dst
    run_command(cmd, "Copying " .. src .. " to " .. dst)
end

local function main()
    print("=== BUIDL RELEASE BUILD ===")
    print("Building production release binaries...")
    print("")
    
    -- Create release directory structure
    local release_dir = "./release"
    local bin_dir = release_dir .. "/bin"
    local config_dir = release_dir .. "/config"
    local docs_dir = release_dir .. "/docs"
    local scripts_dir = release_dir .. "/scripts"
    
    create_directory(release_dir)
    create_directory(bin_dir)
    create_directory(config_dir)
    create_directory(docs_dir)
    create_directory(scripts_dir)
    
    print("📦 Building main application binary...")
    run_command("hype build simple_buidl.lua -o buidl && mv buidl " .. bin_dir .. "/", "Building main application")
    
    print("📦 Building utility binaries...")
    run_command("hype build create_config_bundle.lua -o buidl-config && mv buidl-config " .. bin_dir .. "/", "Building config utility")
    run_command("hype build test_bundle.lua -o buidl-test && mv buidl-test " .. bin_dir .. "/", "Building test suite")
    
    print("📄 Copying configuration files...")
    copy_file(".env.example", config_dir .. "/.env.example")
    
    print("📄 Copying source files...")
    local src_dir = release_dir .. "/src"
    create_directory(src_dir)
    copy_file("main.lua", src_dir .. "/main.lua")
    copy_file("config.lua", src_dir .. "/config.lua")
    copy_file("ai_slack_bot.lua", src_dir .. "/ai_slack_bot.lua")
    copy_file("create_config.lua", src_dir .. "/create_config.lua")
    copy_file("test_suite.lua", src_dir .. "/test_suite.lua")
    copy_file("vector_db_bundle.lua", src_dir .. "/vector_db_bundle.lua")
    copy_file("privacy_conscious_embeddings.lua", src_dir .. "/privacy_conscious_embeddings.lua")
    copy_file("ai_response_generator.lua", src_dir .. "/ai_response_generator.lua")
    copy_file("openrouter_client.lua", src_dir .. "/openrouter_client.lua")
    
    print("📚 Copying documentation...")
    copy_file("CONFIG.md", docs_dir .. "/CONFIG.md")
    copy_file("TESTING.md", docs_dir .. "/TESTING.md")
    copy_file("PROJECT_PLAN.md", docs_dir .. "/PROJECT_PLAN.md")
    
    print("🔧 Creating utility scripts...")
    
    -- Create run script
    local run_script = [[#!/bin/bash
# Buidl Runner Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Check if config exists
if [ ! -f "$CONFIG_DIR/.env" ]; then
    echo "❌ Configuration file not found!"
    echo "Run: $BIN_DIR/buidl-config to create configuration template"
    exit 1
fi

# Change to config directory and run bot
cd "$CONFIG_DIR"
exec "$BIN_DIR/buidl"
]]
    
    local run_file = io.open(scripts_dir .. "/run.sh", "w")
    run_file:write(run_script)
    run_file:close()
    
    -- Create install script
    local install_script = [[#!/bin/bash
# Buidl Installation Script

set -e

INSTALL_DIR="${INSTALL_DIR:-/usr/local/buidl}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Buidl Installation ==="
echo "Installing to: $INSTALL_DIR"
echo ""

# Create installation directory
sudo mkdir -p "$INSTALL_DIR"

# Copy release files
echo "📦 Installing application files..."
sudo cp -r "$RELEASE_DIR/bin" "$INSTALL_DIR/"
sudo cp -r "$RELEASE_DIR/config" "$INSTALL_DIR/"
sudo cp -r "$RELEASE_DIR/docs" "$INSTALL_DIR/"
sudo cp -r "$RELEASE_DIR/scripts" "$INSTALL_DIR/"

# Make binaries executable
sudo chmod +x "$INSTALL_DIR/bin/"*
sudo chmod +x "$INSTALL_DIR/scripts/"*

# Create symlinks in system PATH
echo "🔗 Creating system symlinks..."
sudo ln -sf "$INSTALL_DIR/bin/buidl" /usr/local/bin/buidl
sudo ln -sf "$INSTALL_DIR/bin/buidl-config" /usr/local/bin/buidl-config
sudo ln -sf "$INSTALL_DIR/bin/buidl-test" /usr/local/bin/buidl-test
sudo ln -sf "$INSTALL_DIR/scripts/run.sh" /usr/local/bin/buidl-run

# Create data directory
sudo mkdir -p "$INSTALL_DIR/data"
sudo chmod 755 "$INSTALL_DIR/data"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Create configuration: buidl-config"
echo "2. Edit configuration: $INSTALL_DIR/config/.env"
echo "3. Run tests: buidl-test"
echo "4. Start bot: buidl-run"
echo ""
echo "Documentation available at: $INSTALL_DIR/docs/"
]]
    
    local install_file = io.open(scripts_dir .. "/install.sh", "w")
    install_file:write(install_script)
    install_file:close()
    
    -- Create uninstall script
    local uninstall_script = [[#!/bin/bash
# Buidl Uninstallation Script

INSTALL_DIR="${INSTALL_DIR:-/usr/local/buidl}"

echo "=== Buidl Uninstallation ==="
echo "Removing from: $INSTALL_DIR"
echo ""

# Remove symlinks
echo "🔗 Removing system symlinks..."
sudo rm -f /usr/local/bin/buidl
sudo rm -f /usr/local/bin/buidl-config
sudo rm -f /usr/local/bin/buidl-test
sudo rm -f /usr/local/bin/buidl-run

# Remove installation directory
echo "📦 Removing application files..."
sudo rm -rf "$INSTALL_DIR"

echo ""
echo "✅ Uninstallation complete!"
]]
    
    local uninstall_file = io.open(scripts_dir .. "/uninstall.sh", "w")
    uninstall_file:write(uninstall_script)
    uninstall_file:close()
    
    -- Make scripts executable
    run_command("chmod +x " .. scripts_dir .. "/*.sh", "Making scripts executable")
    
    print("📋 Creating release manifest...")
    local manifest = [[Buidl Release Manifest
=======================

Version: 1.0.0
Build Date: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[

Build Target: Production Release
Architecture: Cross-platform (Hype Framework)

Contents:
- bin/buidl               Main application binary
- bin/buidl-config        Configuration utility
- bin/buidl-test          Test suite runner
- config/.env.example     Configuration template
- config/config.lua       Configuration system
- docs/CONFIG.md          Configuration guide
- docs/TESTING.md         Testing documentation
- docs/PROJECT_PLAN.md    Project documentation
- scripts/run.sh          Application runner
- scripts/install.sh      Installation script
- scripts/uninstall.sh    Uninstallation script

Installation:
1. Run: ./scripts/install.sh
2. Configure: buidl-config
3. Test: buidl-test
4. Run: buidl-run

Requirements:
- Hype Runtime Environment
- Network access for OpenRouter API
- Slack bot token and signing secret
- OpenRouter API key

Support:
- Documentation: ./docs/
- Configuration: ./config/
- Testing: buidl-test
]]
    
    local manifest_file = io.open(release_dir .. "/MANIFEST.txt", "w")
    manifest_file:write(manifest)
    manifest_file:close()
    
    print("📦 Creating release archive...")
    run_command("cd " .. release_dir .. " && tar -czf ../buidl-v1.0.0.tar.gz .", "Creating release archive")
    
    print("=" .. string.rep("=", 50))
    print("🎉 BUIDL RELEASE BUILD COMPLETE!")
    print("=" .. string.rep("=", 50))
    print("")
    print("Release files created:")
    print("  📁 ./release/                 - Release directory")
    print("  📦 ./buidl-v1.0.0.tar.gz      - Release archive")
    print("")
    print("Installation:")
    print("  1. Extract: tar -xzf buidl-v1.0.0.tar.gz")
    print("  2. Install: cd release && ./scripts/install.sh")
    print("  3. Configure: buidl-config")
    print("  4. Run: buidl-run")
    print("")
    print("🚀 Ready for deployment!")
end

main()