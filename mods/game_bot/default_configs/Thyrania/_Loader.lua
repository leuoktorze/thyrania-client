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

-- Cada bloco fica em uma aba curta (Cura, Buffs, Comida, Mana...): no cliente 15.x uma aba comprida
-- demais, com barra de rolagem, deixava o layout recalculando sem parar (travava ou engasgava).
-- Auxiliador LEVE (teste da 15.x): só o essencial. Os módulos pesados do vBot (analyzer, supplies,
-- containers, playerlist, alarms...) ficam de fora até descobrirmos qual travava o cliente.
-- Para testar um deles, tire o "--" da frente do nome e reabra o cliente.
local luaFiles = {
  "main",
  "items",
  "vlib",
  "new_cavebot_lib",
  "thyrania_stubs",
  "configs", -- não mudar a ordem acima
  "extras",
  "thyrania_targetbot", -- Alvo: atacar e lootear sozinho (sem Cavebot)
  "Conditions",
  "Equipper",
  "HealBot",
  "new_healer",
  "mana_trainer",
  "AttackBot",
  "eat_food",
  "hold_target",
  -- "playerlist",
  -- "alarms",
  -- "combo",
  -- "Dropper",
  -- "Containers",
  -- "quiver_manager",
  -- "quiver_label",
  -- "tools",
  -- "antiRs",
  -- "equip",
  -- "exeta",
  -- "analyzer",
  -- "spy_level",
  -- "supplies",
}

-- Diagnóstico (teste 15.x): carrega um script a cada 3 segundos e anota no thyrania_trace.txt.
-- Se o cliente congelar, o último "carregando" do arquivo é o culpado.
local DIAG = false
if DIAG then
  for i, file in ipairs(luaFiles) do
    schedule(i * 3000, function()
      thyTrace("DIAG carregando " .. file)
      loadScript(file)
      thyTrace("DIAG ok " .. file)
    end)
  end
else
  for i, file in ipairs(luaFiles) do
    loadScript(file)
  end
end

setDefaultTab("Início")
