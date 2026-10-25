-- Auxiliador do Thyrania: o Cavebot e o Targetbot do vBot NÃO são carregados (decisão do servidor:
-- sem bot que anda/caça sozinho). Alguns módulos do vBot ainda perguntam por eles; aqui ficam
-- versões "sempre desligadas" para que esses módulos funcionem sem eles.
CaveBot = CaveBot or {}
CaveBot.isOn = function() return false end
CaveBot.isOff = function() return true end
CaveBot.setOn = function() return false end
CaveBot.setOff = function() return true end
CaveBot.delay = function() return true end
CaveBot.walkTo = CaveBot.walkTo or function() return false end
CaveBot.GetLootContainers = CaveBot.GetLootContainers or function() return {} end
CaveBot.Extensions = {}

TargetBot = {}
TargetBot.isOn = function() return false end
TargetBot.isOff = function() return true end
TargetBot.setOn = function() return false end
TargetBot.setOff = function() return true end
TargetBot.isActive = function() return false end
TargetBot.isCaveBotActionAllowed = function() return true end
TargetBot.allowCaveBot = function() end
TargetBot.Danger = function() return 0 end
TargetBot.Looting = { getStatus = function() return "" end }
