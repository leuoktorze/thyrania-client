-- Thyrania: só o TargetBot (atacar sozinho os monstros por perto). O Cavebot (andar sozinho) não existe.
-- Mesmo trecho do vBot/cavebot.lua original, sem a parte do Cavebot.
setDefaultTab("Alvo")
TargetBot = {} -- global namespace
importStyle("/targetbot/looting.otui")
importStyle("/targetbot/target.otui")
importStyle("/targetbot/creature_editor.otui")
dofile("/targetbot/creature.lua")
dofile("/targetbot/creature_attack.lua")
dofile("/targetbot/creature_editor.lua")
dofile("/targetbot/creature_priority.lua")
dofile("/targetbot/looting.lua")
dofile("/targetbot/walking.lua")
-- main targetbot file, must be last
dofile("/targetbot/target.lua")
