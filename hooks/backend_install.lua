local archiver = require("archiver")
local cmd = require("cmd")
local file = require("file")
local http = require("http")
local registry = require("registry")

local function sha256(path)
    local output
    if RUNTIME.osType == "windows" then
        local quoted = "'" .. path:gsub("'", "''") .. "'"
        output = cmd.exec('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath ' .. quoted
            .. ').Hash"')
    else
        local quoted = "'" .. path:gsub("'", "'\\''") .. "'"
        -- Hashing stdin keeps the output free of the filename, which sha256sum would escape.
        output = cmd.exec((RUNTIME.osType == "darwin" and "shasum -a 256 < " or "sha256sum < ") .. quoted)
    end
    local digest = output:match("^%s*(%x+)")
    if not digest or #digest ~= 64 then
        error("couldn't compute the sha256 of " .. path .. ": " .. output)
    end
    return digest:lower()
end

function PLUGIN:BackendInstall(ctx)
    local tool, channel = registry.parse(ctx.tool)
    if channel and registry.channel(ctx.version) ~= channel then
        error(ctx.tool .. " only installs " .. channel .. " versions, not " .. ctx.version)
    end
    local entry
    for _, candidate in ipairs(registry.load(tool).versions) do
        if candidate.version == ctx.version then
            entry = candidate
        end
    end
    if not entry then
        error(tool .. " " .. ctx.version .. " isn't in the chunkzero registry")
    end
    local platform = registry.platform()
    local asset = entry.assets[platform]
    if not asset or not asset.sha256:match("^%x+$") or #asset.sha256 ~= 64 then
        error(tool .. " " .. ctx.version .. " has no " .. platform .. " build")
    end

    local archive = file.join_path(ctx.download_path, tool .. "-" .. ctx.version .. "-" .. platform .. ".tar.gz")
    http.download_file({ url = asset.url }, archive)
    local actual = sha256(archive)
    if actual ~= asset.sha256:lower() then
        error("checksum mismatch for " .. asset.url .. ": expected " .. asset.sha256 .. ", got " .. actual)
    end
    -- Archives hold one top-level directory with the executable and the runtime files it loads relative to itself.
    archiver.decompress(archive, ctx.install_path, { strip_components = 1 })
    return {}
end
