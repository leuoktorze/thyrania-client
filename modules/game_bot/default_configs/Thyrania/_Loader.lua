-- Auxiliador do Thyrania (baseado no vBot 4.8).
-- Liberado: cura (HealBot), ataque/rotação de magias (AttackBot), condições (haste, utamo...),
-- comida, troca de gold, equipar rings/amulets e ferramentas.
-- Alvo (Targetbot): ataca e looteia sozinho. Fora: Cavebot (andar sozinho), editor de scripts e servidor de bot.
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/vBot", true, false)
for i, file in ipairs(configFiles) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
    g_ui.importStyle(file)
  end
end

local function loadScript(name)
  return dofile("/vBot/" .. name .. ".lua")
end

local luaFiles = {
  "main",
  "items",
  "vlib",
  "new_cavebot_lib",
  "thyrania_stubs",
  "configs", -- não mudar a ordem acima
  "extras",
  "thyrania_targetbot", -- TargetBot sem Cavebot
  "playerlist",
  "alarms",
  "Conditions",
  "Equipper",
  "combo",
  "HealBot",
  "new_healer",
  "mana_trainer", -- treino de magic level
  "AttackBot",
  "Dropper",
  "Containers",
  "quiver_manager",
  "quiver_label",
  "tools",
  "antiRs",
  "eat_food",
  "equip",
  "exeta",
  "analyzer",
  "spy_level",
  "supplies",
  "hold_target",
}

for i, file in ipairs(luaFiles) do
  loadScript(file)
end

setDefaultTab("Início")
