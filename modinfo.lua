name = "伤害构成"
description = "玩家死亡时在聊天框显示伤害构成（可自定义统计时长、公告名称；超级模式死亡时只显示前五名）。"
author = "橙小幸"
version = "1.4.1"

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

client_only_mod = false
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- 配置选项
configuration_options = {
    {
        name = "damage_history_seconds",
        label = "统计时长（秒）",
        hover = "只统计最近多少秒内的伤害；普通/超级模式均按此时长统计。",
        options = {
            { description = "1 分钟", data = 60 },
            { description = "3 分钟", data = 180 },
            { description = "5 分钟", data = 300 },
            { description = "10 分钟", data = 600 },
            { description = "30 分钟", data = 1800 },
            { description = "60 分钟", data = 3600 },
        },
        default = 600,
    },
    {
        name = "announcement_name",
        label = "公告名称",
        hover = "死亡时发送的公告中，显示在玩家名后面的标题文字。",
        options = {
            { description = "伤害构成（近10分钟）", data = "伤害构成（近10分钟）" },
            { description = "伤害构成", data = "伤害构成" },
            { description = "死因分析", data = "死因分析" },
            { description = "伤害来源统计", data = "伤害来源统计" },
            { description = "死亡伤害构成", data = "死亡伤害构成" },
        },
        default = "伤害构成（近10分钟）",
    },
    {
        name = "super_mode",
        label = "超级模式",
        hover = "开启后仍按上方「统计时长」限制记录，死亡时只显示伤害最高的前五名。",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
}
