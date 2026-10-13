local _, AUI = ...
local MacroRanks = { pending = {} }
AUI:RegisterModule("MacroRanks", MacroRanks)

local function Rank(subtext)
    if type(subtext) ~= "string" then return end
    local label, number = subtext:match("^(.-)(%d+)%s*$")
    if label and label ~= "" then return label:lower(), tonumber(number) end
end

local commands = { cast=true, use=true, castsequence=true, castrandom=true, userandom=true, cancelaura=true, show=true, showtooltip=true }

function MacroRanks:UpdateBody(body, name, subtext)
    local label, rank = Rank(subtext)
    if not rank then return body end
    local function Token(token)
        local prefix, spell, old, suffix = token:match("^(%s*!?)(.-)%(([^()]*)%)(%s*)$")
        if not spell or spell:lower() ~= name:lower() then return token end
        local oldLabel, oldRank = Rank(old)
        if oldLabel ~= label or not oldRank or oldRank >= rank then return token end
        return prefix .. spell .. "(" .. subtext .. ")" .. suffix
    end
    return (body:gsub("([^\n]+)", function(line)
        local lead, command, gap, arguments = line:match("^(%s*[/#])([%a]+)(%s+)(.*)$")
        if not command or not commands[command:lower()] then return line end
        -- Conditions and sequence reset clauses are preserved as separate prefixes.
        arguments = arguments:gsub("([^,;]+)", function(segment)
            local prefix = ""
            while true do
                local head, rest = segment:match("^(%s*%b[]%s*)(.*)$")
                if not head then head, rest = segment:match("^(%s*reset=[^%s]+%s+)(.*)$") end
                if not head then break end
                prefix = prefix .. head; segment = rest
            end
            return prefix .. Token(segment)
        end)
        return lead .. command .. gap .. arguments
    end))
end

function MacroRanks:Process()
    if InCombatLockdown() then return end
    if not ProjectRuthlessDB.spellbook.autoUpdateRanks then self.pending = {}; return end
    local book = AUI.modules.Spellbook
    local account, character = GetNumMacros()
    local base = (Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS) or MAX_ACCOUNT_MACROS or 120
    local changed = 0
    for spellID in pairs(self.pending) do
        local info = C_Spell.GetSpellInfo(spellID)
        local subtext = C_Spell.GetSpellSubtext(spellID)
        if info and Rank(subtext) then
            local deferred = false
            for bank = 1, 2 do
                for slot = 1, (bank == 1 and account or character) do
                    local index = (bank == 1 and 0 or base) + slot
                    local name, icon, body = GetMacroInfo(index)
                    if name and body then
                        local updated = self:UpdateBody(body, info.name, subtext)
                        if updated ~= body and #updated <= 255 then
                            if book.selectedMacro == index and book.macroDirty then
                                deferred = true
                            else
                                book:BackupMacro(index, "Before automatic rank update")
                                EditMacro(index, nil, nil, updated)
                                changed = changed + 1
                                if book.selectedMacro == index and book.macroEditor then book:SelectMacro(index) end
                            end
                        end
                    end
                end
            end
            if not deferred then self.pending[spellID] = nil end
        end
    end
    if changed > 0 then AUI:Print(("Updated spell ranks in %d macro(s). Previous versions are in Macro History."):format(changed)) end
end

function MacroRanks:OnPlayerLogin()
    local events = CreateFrame("Frame")
    for _, event in ipairs({"LEARNED_SPELL_IN_SKILL_LINE", "SPELL_TEXT_UPDATE", "PLAYER_REGEN_ENABLED", "UPDATE_MACROS"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent", function(_, event, spellID)
        if event == "LEARNED_SPELL_IN_SKILL_LINE" and ProjectRuthlessDB.spellbook.autoUpdateRanks then self.pending[spellID] = true end
        if not self.scheduled and next(self.pending) then
            self.scheduled = true
            C_Timer.After(0, function() self.scheduled = false; self:Process() end)
        end
    end)
    self.events = events
end
