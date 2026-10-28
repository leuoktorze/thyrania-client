-- Auxiliador do Thyrania: o Cavebot do vBot NÃO é carregado (decisão do servidor: sem bot que
-- anda sozinho pela hunt). O Targetbot (atacar e lootear sozinho) fica. Alguns módulos ainda
-- perguntam pelo Cavebot; aqui ficam versões "sempre desligadas" para eles funcionarem sem ele.
CaveBot = CaveBot or {}
CaveBot.isOn = function() return false end
CaveBot.isOff = function() return true end
CaveBot.setOn = function() return false end
CaveBot.setOff = function() return true end
CaveBot.delay = function() return true end
CaveBot.walkTo = function() return false end
CaveBot.Extensions = {}
