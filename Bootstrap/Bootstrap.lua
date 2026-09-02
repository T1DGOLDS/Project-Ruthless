local capture = {
    entries = {},
    forwardOnly = false,
}
_G.ProjectRuthlessEarlyCapture = capture

seterrorhandler(function(message)
    if not capture.forwardOnly then
        local ok = pcall(function()
            capture.entries[#capture.entries + 1] = {
                time = date("%Y-%m-%d %H:%M:%S"),
                message = tostring(message or "unknown error"),
                stack = debugstack and debugstack(2, 20, 20) or "stack unavailable",
                count = 1,
                early = true,
            }
        end)
        if not ok then
            capture.entries = capture.entries or {}
        end
    end

    -- Project Ruthless owns presentation of captured errors. Do not forward to
    -- Blizzard's blocking popup handler.
end)

local fallback = CreateFrame("Frame")
fallback:RegisterEvent("PLAYER_LOGIN")
fallback:SetScript("OnEvent", function()
    if not capture.forwardOnly and #capture.entries > 0 then
        print("|cff7f5af0Project Ruthless|r: Addons are causing lots of Lua errors, but the main error viewer did not load.")
    end
end)
