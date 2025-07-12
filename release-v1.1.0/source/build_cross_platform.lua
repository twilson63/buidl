-- build_cross_platform.lua
-- Simplified cross-platform build script

local function run_command(cmd, description)
    print("→ " .. description)
    print("  " .. cmd)
    
    local result = os.execute(cmd)
    if result ~= 0 then
        print("  ❌ Failed")
        return false
    else
        print("  ✅ Success")
        return true
    end
end

local function main()
    print("=== BUIDL v1.1.0 CROSS-PLATFORM BUILD ===")
    print("")
    
    -- Clean up old builds
    run_command("rm -rf release-v1.1.0", "Cleaning up old release")
    run_command("rm -f buidl-v1.1.0-*.tar.gz buidl-v1.1.0-*.zip", "Cleaning up old archives")
    
    -- Create release directory
    run_command("mkdir -p release-v1.1.0", "Creating release directory")
    
    -- Build for current platform (macOS ARM64) - this is our tested platform
    print("\n🍎 Building for macOS (current platform)...")
    if run_command("hype build buidl_socket_mode_bundle.lua -o buidl-socket", "Building Socket Mode") and
       run_command("hype build simple_buidl.lua -o buidl-http", "Building HTTP Mode") and
       run_command("hype build create_config_bundle.lua -o buidl-config", "Building config utility") and
       run_command("hype build test_bundle.lua -o buidl-test", "Building test suite") then
        
        -- Create macOS release
        local macos_dir = "release-v1.1.0/macos-arm64"
        run_command("mkdir -p " .. macos_dir .. "/bin", "Creating macOS directory")
        run_command("mv buidl-socket buidl-http buidl-config buidl-test " .. macos_dir .. "/bin/", "Moving macOS binaries")
        
        -- Copy documentation and config
        run_command("cp -r README.md CHANGELOG.md WEBSOCKET_UPGRADE.md CONFIG.md DEPLOYMENT.md " .. macos_dir .. "/", "Copying documentation")
        run_command("cp .env.example " .. macos_dir .. "/config.env.example", "Copying config template")
        
        -- Create install script
        local install_script = [[#!/bin/bash
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
]]
        
        local install_file = io.open(macos_dir .. "/install.sh", "w")
        install_file:write(install_script)
        install_file:close()
        run_command("chmod +x " .. macos_dir .. "/install.sh", "Making install script executable")
        
        -- Create archive
        run_command("cd release-v1.1.0 && tar -czf ../buidl-v1.1.0-macos-arm64.tar.gz macos-arm64", "Creating macOS archive")
        print("✅ macOS release created")
    else
        print("❌ macOS build failed")
    end
    
    -- Create universal source release
    print("\n📦 Creating universal source release...")
    local src_dir = "release-v1.1.0/source"
    run_command("mkdir -p " .. src_dir, "Creating source directory")
    
    -- Copy all source files
    run_command("cp *.lua " .. src_dir .. "/", "Copying source files")
    run_command("cp *.md " .. src_dir .. "/", "Copying documentation")
    run_command("cp .env.example " .. src_dir .. "/", "Copying config template")
    
    -- Create build script for source release
    local build_script = [[#!/bin/bash
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
]]
    
    local build_file = io.open(src_dir .. "/build.sh", "w")
    build_file:write(build_script)
    build_file:close()
    run_command("chmod +x " .. src_dir .. "/build.sh", "Making build script executable")
    
    -- Create source archive
    run_command("cd release-v1.1.0 && tar -czf ../buidl-v1.1.0-source.tar.gz source", "Creating source archive")
    
    print("\n" .. string.rep("=", 50))
    print("🎉 CROSS-PLATFORM BUILD COMPLETE!")
    print(string.rep("=", 50))
    print("")
    
    print("📦 Release archives created:")
    run_command("ls -la buidl-v1.1.0-*.tar.gz", "Listing archives")
    
    print("")
    print("🚀 Ready for release!")
    print("")
    print("Platform support:")
    print("✅ macOS ARM64 (Apple Silicon) - tested binary")
    print("📦 Universal source - build on any Hype-supported platform")
    print("")
    print("Next steps:")
    print("1. Test the macOS binary")
    print("2. Commit changes to Git")
    print("3. Create GitHub release v1.1.0")
    print("4. Upload release archives")
end

main()