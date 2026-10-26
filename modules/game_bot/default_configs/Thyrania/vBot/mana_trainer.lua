-- Thyrania: treino de magic level (gasta mana numa magia quando a mana passa de X%).
setDefaultTab("Cura")
UI.Separator()
UI.Label("Treino de mana:")
if type(storage.manaTrainer) ~= "table" then
  storage.manaTrainer = { spell = "utevo lux", percent = 90 }
end
local cfg = storage.manaTrainer

UI.Label("Magia:")
UI.TextEdit(cfg.spell or "utevo lux", function(widget, text)
  cfg.spell = text
end)
UI.Label("Usar quando a mana passar de (%):")
UI.TextEdit(tostring(cfg.percent or 90), function(widget, text)
  local n = tonumber(text)
  if n and n >= 1 and n <= 100 then cfg.percent = n end
end)

macro(500, "Treinar mana", function()
  if not cfg.spell or cfg.spell:len() == 0 then return end
  if manapercent() < (cfg.percent or 90) then return end
  if canCast and not canCast(cfg.spell) then return end
  say(cfg.spell)
  delay(1000)
end)
UI.Separator()
