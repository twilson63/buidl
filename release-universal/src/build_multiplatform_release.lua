-- build_multiplatform_release.lua
-- Cross-platform release build script for all supported platforms

local function run_command(cmd, description)
    print("→ " .. description)
    print("  Running: " .. cmd)
    
    local result = os.execute(cmd)
    if result ~= 0 then
        print("  ❌ Failed: " .. description)
        return false
    else
        print("  ✅ Success: " .. description)
        return true
    end
end

local function create_directory(path)
    local cmd = "mkdir -p " .. path
    return run_command(cmd, "Creating directory: " .. path)
end

local function copy_file(src, dst)
    local cmd = "cp " .. src .. " " .. dst
    return run_command(cmd, "Copying " .. src .. " to " .. dst)
end

local function build_for_platform(platform, arch, output_suffix)
    print("🏗️ Building for " .. platform .. "/" .. arch .. "...")
    
    local target_flag = "-t " .. platform
    if arch then
        target_flag = target_flag .. "-" .. arch
    end
    
    local bin_dir = "./release-" .. platform .. "/bin"
    create_directory(bin_dir)
    
    -- Build main application
    local build_cmd = "hype build buidl_socket_mode.lua " .. target_flag .. " -o buidl" .. output_suffix .. " && mv buidl" .. output_suffix .. " " .. bin_dir .. "/"
    if not run_command(build_cmd, "Building main application for " .. platform) then
        return false
    end
    
    -- Build HTTP version as fallback
    build_cmd = "hype build simple_buidl.lua " .. target_flag .. " -o buidl-http" .. output_suffix .. " && mv buidl-http" .. output_suffix .. " " .. bin_dir .. "/"
    if not run_command(build_cmd, "Building HTTP version for " .. platform) then
        return false
    end
    
    -- Build utilities
    build_cmd = "hype build create_config_bundle.lua " .. target_flag .. " -o buidl-config" .. output_suffix .. " && mv buidl-config" .. output_suffix .. " " .. bin_dir .. "/"
    if not run_command(build_cmd, "Building config utility for " .. platform) then
        return false
    end
    
    build_cmd = "hype build test_bundle.lua " .. target_flag .. " -o buidl-test" .. output_suffix .. " && mv buidl-test" .. output_suffix .. " " .. bin_dir .. "/"
    if not run_command(build_cmd, "Building test suite for " .. platform) then
        return false
    end
    
    return true
end

local function create_install_script(platform, release_dir)
    local script_ext = ""
    local script_content = ""
    local bin_ext = ""
    
    if platform == "windows" then
        script_ext = ".bat"
        bin_ext = ".exe"
        script_content = [[@echo off
REM Buidl Installation Script for Windows

set "INSTALL_DIR=%PROGRAMFILES%\Buidl"
if defined BUIDL_INSTALL_DIR set "INSTALL_DIR=%BUIDL_INSTALL_DIR%"

echo === Buidl Installation ===
echo Installing to: %INSTALL_DIR%
echo.

REM Create installation directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy release files
echo Installing application files...
xcopy /E /I /Y bin "%INSTALL_DIR%\bin\"
xcopy /E /I /Y config "%INSTALL_DIR%\config\"
xcopy /E /I /Y docs "%INSTALL_DIR%\docs\"
xcopy /E /I /Y scripts "%INSTALL_DIR%\scripts\"

REM Add to PATH (requires admin)
echo Adding to system PATH...
setx /M PATH "%PATH%;%INSTALL_DIR%\bin"

echo.
echo Installation complete!
echo.
echo Next steps:
echo 1. Create configuration: buidl-config
echo 2. Edit configuration: %INSTALL_DIR%\config\.env
echo 3. Run tests: buidl-test
echo 4. Start bot: buidl
echo.
echo Documentation available at: %INSTALL_DIR%\docs\
pause
]]
    else
        script_ext = ".sh"
        script_content = [[#!/bin/bash
# Buidl Installation Script for ]] .. platform .. [[ 

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
sudo ln -sf "$INSTALL_DIR/bin/buidl]] .. bin_ext .. [[" /usr/local/bin/buidl
sudo ln -sf "$INSTALL_DIR/bin/buidl-config]] .. bin_ext .. [[" /usr/local/bin/buidl-config
sudo ln -sf "$INSTALL_DIR/bin/buidl-test]] .. bin_ext .. [[" /usr/local/bin/buidl-test

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
echo "4. Start bot: buidl"
echo ""
echo "Documentation available at: $INSTALL_DIR/docs/"
]]
    end
    
    local script_path = release_dir .. "/scripts/install" .. script_ext
    local file = io.open(script_path, "w")
    file:write(script_content)
    file:close()
    
    if platform ~= "windows" then
        run_command("chmod +x " .. script_path, "Making install script executable")
    end
end

local function create_platform_release(platform, arch)
    local output_suffix = ""
    if platform == "windows" then
        output_suffix = ".exe"
    end
    
    print("\n🌍 Creating release for " .. platform .. "/" .. (arch or "universal") .. "...")
    
    -- Build binaries for platform
    if not build_for_platform(platform, arch, output_suffix) then
        print("❌ Failed to build for " .. platform)
        return false
    end
    
    local release_dir = "./release-" .. platform
    local config_dir = release_dir .. "/config"
    local docs_dir = release_dir .. "/docs"
    local scripts_dir = release_dir .. "/scripts"
    
    -- Create directory structure
    create_directory(config_dir)
    create_directory(docs_dir)
    create_directory(scripts_dir)
    
    -- Copy configuration files
    copy_file(".env.example", config_dir .. "/.env.example")
    
    -- Copy documentation
    copy_file("README.md", release_dir .. "/README.md")
    copy_file("CONFIG.md", docs_dir .. "/CONFIG.md")
    copy_file("TESTING.md", docs_dir .. "/TESTING.md")
    copy_file("DEPLOYMENT.md", docs_dir .. "/DEPLOYMENT.md")
    copy_file("WEBSOCKET_UPGRADE.md", docs_dir .. "/WEBSOCKET_UPGRADE.md")
    copy_file("PROJECT_PLAN.md", docs_dir .. "/PROJECT_PLAN.md")
    
    -- Copy source files for reference
    local src_dir = release_dir .. "/src"
    create_directory(src_dir)
    copy_file("slack_socket_mode.lua", src_dir .. "/slack_socket_mode.lua")
    copy_file("buidl_socket_mode.lua", src_dir .. "/buidl_socket_mode.lua")
    copy_file("config.lua", src_dir .. "/config.lua")
    copy_file("vector_db_bundle.lua", src_dir .. "/vector_db_bundle.lua")
    copy_file("privacy_conscious_embeddings.lua", src_dir .. "/privacy_conscious_embeddings.lua")
    copy_file("ai_response_generator.lua", src_dir .. "/ai_response_generator.lua")
    copy_file("openrouter_client.lua", src_dir .. "/openrouter_client.lua")
    
    -- Create platform-specific install script
    create_install_script(platform, release_dir)
    
    -- Create manifest
    local manifest = [[Buidl v1.1.0 Release - ]] .. platform .. [[/]] .. (arch or "universal") .. [[
===================================================================

Version: 1.1.0
Build Date: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
Platform: ]] .. platform .. [[/]] .. (arch or "universal") .. [[
Build Target: Production Release

NEW IN v1.1.0:
- WebSocket support with Slack Socket Mode
- Real-time bidirectional communication
- Improved performance (50-200ms latency vs 500-2000ms HTTP)
- Simplified deployment (no webhook URLs needed)
- Enhanced security (outbound-only connections)

Contents:
- bin/buidl]] .. output_suffix .. [[                    Main application (WebSocket mode)
- bin/buidl-http]] .. output_suffix .. [[               HTTP Events API version (fallback)
- bin/buidl-config]] .. output_suffix .. [[             Configuration utility
- bin/buidl-test]] .. output_suffix .. [[               Test suite runner
- config/.env.example              Configuration template
- docs/                            Complete documentation
- scripts/install]] .. (platform == "windows" and ".bat" or ".sh") .. [[               Platform-specific installer
- src/                             Source code for reference

Installation:
]] .. (platform == "windows" and "1. Run: scripts\\install.bat (as Administrator)" or "1. Run: ./scripts/install.sh") .. [[
2. Configure: buidl-config
3. Test: buidl-test
4. Start: buidl

Requirements:
- Slack App with Socket Mode enabled (recommended) or HTTP Events API
- App-Level Token (xapp-) for Socket Mode OR Signing Secret for HTTP mode
- Bot Token (xoxb-)
- OpenRouter API key
- Network access for AI processing

WebSocket Mode Setup:
1. Enable Socket Mode in Slack app settings
2. Generate App-Level Token with connections:write scope
3. Add SLACK_APP_TOKEN and BOT_USER_ID to configuration
4. Use main 'buidl' binary for WebSocket mode

HTTP Mode Setup (Fallback):
1. Configure webhook URL in Slack app settings
2. Use 'buidl-http' binary for HTTP Events API mode
3. Ensure public webhook endpoint is accessible

Support:
- Documentation: ./docs/
- WebSocket upgrade guide: ./docs/WEBSOCKET_UPGRADE.md
- GitHub: https://github.com/twilson63/buidl
]]
    
    local manifest_file = io.open(release_dir .. "/MANIFEST.txt", "w")
    manifest_file:write(manifest)
    manifest_file:close()
    
    -- Create platform-specific archive
    local archive_name = "buidl-v1.1.0-" .. platform
    if arch then
        archive_name = archive_name .. "-" .. arch
    end
    archive_name = archive_name .. ".tar.gz"
    
    if platform == "windows" then
        archive_name = "buidl-v1.1.0-" .. platform
        if arch then
            archive_name = archive_name .. "-" .. arch
        end
        archive_name = archive_name .. ".zip"
        
        run_command("cd " .. release_dir .. " && zip -r ../" .. archive_name .. " .", "Creating Windows release archive")
    else
        run_command("cd " .. release_dir .. " && tar -czf ../" .. archive_name .. " .", "Creating " .. platform .. " release archive")
    end
    
    print("✅ " .. platform .. " release created: " .. archive_name)
    return true
end

local function main()
    print("=== BUIDL MULTI-PLATFORM RELEASE BUILD ===")
    print("Building production releases for all supported platforms...")
    print("")
    
    -- Clean up old releases
    run_command("rm -rf release-*", "Cleaning up old release directories")
    run_command("rm -f buidl-v1.1.0-*.tar.gz buidl-v1.1.0-*.zip", "Cleaning up old archives")
    
    -- Supported platforms
    local platforms = {
        {name = "linux", arch = "amd64"},
        {name = "linux", arch = "arm64"}, 
        {name = "darwin", arch = "amd64"},
        {name = "darwin", arch = "arm64"},
        {name = "windows", arch = "amd64"}
    }
    
    local successful_builds = {}
    local failed_builds = {}
    
    -- Build for each platform
    for _, platform in ipairs(platforms) do
        local platform_name = platform.name .. "-" .. platform.arch
        
        if create_platform_release(platform.name, platform.arch) then
            table.insert(successful_builds, platform_name)
        else
            table.insert(failed_builds, platform_name)
        end
    end
    
    -- Create universal release with all source
    print("\n🌍 Creating universal source release...")
    local universal_dir = "./release-universal"
    create_directory(universal_dir)
    create_directory(universal_dir .. "/src")
    create_directory(universal_dir .. "/docs")
    create_directory(universal_dir .. "/config")
    
    -- Copy all source files
    copy_file("*.lua", universal_dir .. "/src/")
    copy_file("README.md", universal_dir .. "/README.md")
    copy_file("*.md", universal_dir .. "/docs/")
    copy_file(".env.example", universal_dir .. "/config/.env.example")
    
    -- Create build script for universal release
    local build_script = [[#!/bin/bash
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
]]
    
    local build_file = io.open(universal_dir .. "/build.sh", "w")
    build_file:write(build_script)
    build_file:close()
    run_command("chmod +x " .. universal_dir .. "/build.sh", "Making build script executable")
    
    run_command("cd " .. universal_dir .. " && tar -czf ../buidl-v1.1.0-source.tar.gz .", "Creating universal source archive")
    
    print("\n" .. string.rep("=", 60))
    print("🎉 MULTI-PLATFORM RELEASE BUILD COMPLETE!")
    print(string.rep("=", 60))
    print("")
    
    print("✅ Successful builds (" .. #successful_builds .. "):")
    for _, build in ipairs(successful_builds) do
        print("  - " .. build)
    end
    
    if #failed_builds > 0 then
        print("")
        print("❌ Failed builds (" .. #failed_builds .. "):")
        for _, build in ipairs(failed_builds) do
            print("  - " .. build)
        end
    end
    
    print("")
    print("📦 Release archives created:")
    local files = io.popen("ls -la buidl-v1.1.0-*.tar.gz buidl-v1.1.0-*.zip 2>/dev/null || true")
    for line in files:lines() do
        print("  " .. line)
    end
    files:close()
    
    print("")
    print("🚀 Ready for GitHub release!")
    print("")
    print("Next steps:")
    print("1. Test each platform archive")
    print("2. Create GitHub release v1.1.0")
    print("3. Upload all platform archives")
    print("4. Update release notes with WebSocket features")
end

main()