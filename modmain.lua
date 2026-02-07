GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
-- 伤害构成 V1.2：可自定义统计时长、公告名称；超级模式仍按时间统计，死亡时只显示前五名

-- 获取当前模组配置（仅在服务端有效，客户端无 ModConfigData）
local function GetConfig()
    local ok, val = pcall(function()
        return {
            damage_history_seconds = GetModConfigData("damage_history_seconds"),
            announcement_name = GetModConfigData("announcement_name"),
            super_mode = GetModConfigData("super_mode"),
        }
    end)
    if not ok or not val then
        return {
            damage_history_seconds = 600,
            announcement_name = "伤害构成（近10分钟）",
            super_mode = false,
        }
    end
    return val
end

-- 获取伤害来源的显示名称（中文/游戏内名称）
local function GetCauseDisplayName(cause)
    if not cause or cause == "" then
        return "未知"
    end
    local key = string.upper(cause)
    if key == "NIL" or key == "UNKNOWN" then
        return "未知"
    end
    return STRINGS.NAMES and STRINGS.NAMES[key] or cause
end

-- 清理超过时间窗口的伤害记录（普通/超级模式都按配置的统计时长清理，避免无限累积崩溃）
local function PruneOldDamage(inst)
    if not inst._injury_causation_history then return end
    local cfg = GetConfig()

    local now = GetTime()
    local cutoff = now - (cfg.damage_history_seconds or 600)
    local i = 1
    while i <= #inst._injury_causation_history do
        if inst._injury_causation_history[i].time < cutoff then
            table.remove(inst._injury_causation_history, i)
        else
            i = i + 1
        end
    end
end

-- 记录一次受到的伤害
local function OnHealthDelta(inst, data)
    if not data or not (data.amount and data.amount < 0) then return end
    if not TheNet:GetIsServer() then return end

    if not inst._injury_causation_history then
        inst._injury_causation_history = {}
    end

    local cause = "unknown"
    if data.afflicter and data.afflicter.prefab then
        cause = data.afflicter.prefab
    elseif data.cause and type(data.cause) == "string" then
        cause = data.cause
    end

    local amount = math.abs(data.amount)
    if amount <= 0 then return end

    table.insert(inst._injury_causation_history, {
        cause = cause,
        amount = amount,
        time = GetTime(),
    })

    PruneOldDamage(inst)
end

-- 玩家死亡时汇总并发送伤害构成到聊天
local function OnDeath(inst, data)
    if not TheNet:GetIsServer() then return end
    if not inst._injury_causation_history or #inst._injury_causation_history == 0 then return end

    local cfg = GetConfig()
    PruneOldDamage(inst)
    if #inst._injury_causation_history == 0 then return end

    -- 按来源汇总伤害
    local byCause = {}
    local total = 0
    for _, entry in ipairs(inst._injury_causation_history) do
        local c = entry.cause or "unknown"
        byCause[c] = (byCause[c] or 0) + entry.amount
        total = total + entry.amount
    end

    if total <= 0 then return end

    -- 按伤害从高到低排序
    local list = {}
    for cause, amount in pairs(byCause) do
        table.insert(list, { cause = cause, amount = amount })
    end
    table.sort(list, function(a, b) return a.amount > b.amount end)

    -- 超级模式：只取前五名
    local maxItems = cfg.super_mode and 5 or nil
    local parts = {}
    local count = 0
    for _, item in ipairs(list) do
        if maxItems and count >= maxItems then break end
        local pct = math.floor(0.5 + 100 * item.amount / total)
        if pct > 0 then
            table.insert(parts, GetCauseDisplayName(item.cause) .. " " .. tostring(pct) .. "%")
            count = count + 1
        end
    end

    if #parts == 0 then return end

    local playerName = inst:GetDisplayName() and inst:GetDisplayName() or "玩家"
    local title = (cfg.announcement_name and cfg.announcement_name ~= "") and cfg.announcement_name or "伤害构成"
    local msg = playerName .. " " .. title .. "：" .. table.concat(parts, "，")
    TheNet:Announce(msg)
end

-- 仅对玩家生效：初始化伤害记录表并监听事件
AddPlayerPostInit(function(inst)
    inst._injury_causation_history = {}
    inst:ListenForEvent("healthdelta", OnHealthDelta)
    inst:ListenForEvent("death", OnDeath)
end)
