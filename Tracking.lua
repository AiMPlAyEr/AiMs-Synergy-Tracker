AST             = AST or {}
AST.Tracking    = {}

T = AST.Tracking
local em            = EVENT_MANAGER
local LIBUNIT     = LibStub:GetLibrary("LibUnits")

--support functions
local function ConvertTime(nd, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
	return math.floor((nd - GetGameTimeMilliseconds()/1000) * mult + 0.5)/mult
end

local function GetUnitName(unitId)
    local unit = LIBUNIT:GetDisplayNameForUnitId(unitId)

    if unit ~= "" or unit ~= nil then
        return zo_strformat("<<1>>", unit)
    else
        return ""
    end
end

function T.synergyCheck(eventCode, result, _, abilityName, _, _, _, sourceType, _, targetType, _, _, _, _, sourceUnitId, targetUnitId, abilityId)
    local start = GetFrameTimeSeconds()

    if (sourceType == COMBAT_UNIT_TYPE_PLAYER or sourceType == COMBAT_UNIT_TYPE_GROUP) and AST.SV.trackerui then
        if AST.Data.SynergyData[abilityId].group == 1 then
            if result == 2240 then AST.Data.TrackerTimer[1] = start + AST.Data.SynergyData[abilityId].cooldown end
        else
            AST.Data.TrackerTimer[AST.Data.SynergyData[abilityId].group] = start + AST.Data.SynergyData[abilityId].cooldown
        end
    end

    if result == ACTION_RESULT_EFFECT_GAINED and AST.SV.healerui then
        if AST.SV.healer.tanksonly then
            if role ~= LFG_GROUP_TANK then return; end
        end

        if AST.SV.healer.ddsonly then
            if role ~= LFG_GROUP_DPS then return; end
        end

        local usedBy    = GetUnitName(targetUnitId)
        local role      = GetGroupMemberAssignedRole(usedBy)

        for k, v in ipairs(AST.Data.HealerTimer) do
            if v.name == usedBy then
                if AST.Data.SynergyData[abilityId].group == AST.SV.healer.firstsynergy then
                    AST.Data.HealerTimer[k].firstsynergy = start + AST.Data.SynergyData[abilityId].cooldown
                elseif (AST.Data.SynergyData[abilityId].group == AST.SV.healer.secondsynergy and not AST.SV.healer.ignoresynergy) then
                    AST.Data.HealerTimer[k].secondsynergy = start + AST.Data.SynergyData[abilityId].cooldown
                end
            end
        end
        --d("Synergy activated! ID: "..abilityId.." From: "..usedBy.." Result: "..result.." Source: "..sourceType)
    end

    em:RegisterForUpdate(AST.name.."Update", AST.SV.interval, T.countDown)
end

function T.countDown()
    local count, counttotal, counter, countAll = 0, 0, 0, 0

    if AST.SV.trackerui then
        for k, v in ipairs(AST.Data.TrackerTimer) do
            local element   = ASTGrid:GetNamedChild("SynergyTimer"..k)
            local icon      = ASTGrid:GetNamedChild("SynergyIcon"..k)

            if ConvertTime(v, 1) <= 0.1 then
                element:SetText("0.0")
                element:SetColor(255, 255, 255, 1)
                icon:SetColor(1, 1, 1, 1)

                if AST.SV.textures then icon:SetAlpha(AST.SV.alpha) end

                counter = counter + 1
            else
                if AST.SV.interval == 1000 then
                    element:SetText(ConvertTime(AST.Data.TrackerTimer[k], 0))
                else
                    element:SetText(string.format("%.1f", ConvertTime(AST.Data.TrackerTimer[k], 1)))
                end

                element:SetColor(255, 0, 0, 1)
                icon:SetColor(0.5, 0.5, 0.5, 1)
            end

            countAll = countAll + 1
        end

    end

    if AST.SV.healerui then
        for k, v in ipairs(AST.Data.HealerTimer) do
            local z, x = (k * 2 - 1), k * 2

            local firElement = ASTHealerUI:GetNamedChild("HealerTimer"..z)
            local secElement = ASTHealerUI:GetNamedChild("HealerTimer"..x)

            if k <= 10 then
                if ConvertTime(v.firstsynergy, 1) <= 0.1 then
                    firElement:SetText("0")
                    firElement:SetColor(255, 255, 255, 1)
                    count = count + 1
                else
                    firElement:SetText(ConvertTime(AST.Data.HealerTimer[k].firstsynergy, 0))
                    firElement:SetColor(255, 0, 0, 1)
                end
                if not AST.SV.healer.ignoresynergy then
                    if ConvertTime(v.secondsynergy, 1) <= 0.1 then
                        secElement:SetText("0")
                        secElement:SetColor(255, 255, 255, 1)
                        count = count + 1
                    else
                        secElement:SetText(ConvertTime(AST.Data.HealerTimer[k].secondsynergy, 0))
                        secElement:SetColor(255, 0, 0, 1)
                    end
                end

                counttotal = counttotal + 2
            end
        end
    end

    if counter == countAll and count == counttotal then em:UnregisterForUpdate(AST.name.."Update") end
end