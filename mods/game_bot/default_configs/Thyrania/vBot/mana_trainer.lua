-- Thyrania: treino de magic level (gasta mana numa magia quando a mana passa de X%).
setDefaultTab("Mana")
UI.Separator()
UI.Label("Treino de mana:")
if type(storage.manaTrainer) ~= "table" then
  storage.manaTrainer = { spell = "utevo lux", percent = 90 }
end
local cfg = storage.manaTrainer

-- (sem caixa de texto no painel: no cliente 15.x a caixa de texto dentro do painel congelava o cliente)
local spellBtn, pctBtn
local function refreshButtons()
  spellBtn:setText("Magia: " .. tostring(cfg.spell))
  pctBtn:setText("Quando a mana passar de " .. tostring(cfg.percent) .. "%")
end
spellBtn = UI.Button("", function()
  modules.client_textedit.singlelineEditor(cfg.spell or "", function(text)
    if text and text:len() > 0 then cfg.spell = text end
    refreshButtons()
  end)
end)
pctBtn = UI.Button("", function()
  modules.client_textedit.singlelineEditor(tostring(cfg.percent or 90), function(text)
    local n = tonumber(text)
    if n and n >= 1 and n <= 100 then cfg.percent = n end
    refreshButtons()
  end)
end)
refreshButtons()

macro(500, "Treinar mana", function()
  if not cfg.spell or cfg.spell:len() == 0 then return end
  if manapercent() < (cfg.percent or 90) then return end
  if canCast and not canCast(cfg.spell) then return end
  say(cfg.spell)
  delay(1000)
end)
UI.Separator()
