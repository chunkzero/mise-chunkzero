local archiver = require("archiver")
local cmd = require("cmd")
local file = require("file")
local http = require("http")
local registry = require("registry")

local function sha256(path)
    local output
    if RUNTIME.osType == "windows" then
        output = cmd.exec('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath \'' .. path
            .. '\').Hash"')
    elseif RUNTIME.osType == "darwin" then
        output = cmd.exec("shasum -a 256 '" .. path .. "'")
    else
        output = cmd.exec("sha256sum '" .. path .. "'")
    end
    return output:match("^%s*(%x+)"):lower()
end

function PLUGIN:BackendInstall(ctx)
    local entry
    for _, candidate in ipairs(registry.load(ctx.tool).versions) do
        if candidate.version == ctx.version then
            entry = candidate
        end
    end
    if not entry then
        error(ctx.tool .. " " .. ctx.version .. " isn't in the chunkzero registry")
    end
    local platform = registry.platform()
    local asset = entry.assets[platform]
    if not asset then
        error(ctx.tool .. " " .. ctx.version .. " has no " .. platform .. " build")
    end

    local archive = file.join_path(ctx.download_path, ctx.tool .. "-" .. ctx.version .. "-" .. platform .. ".tar.gz")
    http.download_file({ url = asset.url }, archive)
    local actual = sha256(archive)
    if actual ~= asset.sha256 then
        error("checksum mismatch for " .. asset.url .. ": expected " .. asset.sha256 .. ", got " .. actual)
    end
    -- Archives hold one top-level directory with the executable and the runtime files it loads relative to itself.
    archiver.decompress(archive, ctx.install_path, { strip_components = 1 })
    return {}
end
