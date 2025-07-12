-- test_kv2.lua
-- Test different ways to access Hype key-value store

print("Testing Hype key-value store (attempt 2)...")

-- Try requiring kv
local status1, kv = pcall(require, "kv")
if status1 and kv then
    print("✓ kv module loaded via require('kv')")
else
    print("✗ Failed to require kv:", kv)
end

-- Try requiring database
local status2, db = pcall(require, "database")
if status2 and db then
    print("✓ database module loaded via require('database')")
else
    print("✗ Failed to require database:", db)
end

-- Try requiring storage
local status3, storage = pcall(require, "storage")
if status3 and storage then
    print("✓ storage module loaded via require('storage')")
else
    print("✗ Failed to require storage:", storage)
end

-- Check if there are any hype-specific globals
print("\nChecking for hype-specific globals:")
for k, v in pairs(_G) do
    if type(k) == "string" and (k:find("hype") or k:find("store") or k:find("db")) then
        print("  " .. k .. ": " .. type(v))
    end
end

-- List all available packages
print("\nAvailable packages:")
for k, v in pairs(package.loaded) do
    print("  " .. k .. ": " .. type(v))
end