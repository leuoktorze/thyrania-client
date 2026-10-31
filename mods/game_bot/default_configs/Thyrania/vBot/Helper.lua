-- Auxiliador Thyrania (janela única, no estilo dos "helpers" de OT):
--   esquerda: liga/desliga, presets, tecla, auto haste, comer, reconectar, trocar gold
--   aba Cura: 3 magias de cura (HP abaixo de / mana mínima) e 4 potions/itens (HP ou mana abaixo de)
--   aba Ataque: 5 magias (mana %, monstros, prioridade) e 2 runas (monstros, prioridade),
--               virar para o alvo, combo na ordem, hotkey tem prioridade, alvo automático
-- As magias são escolhidas clicando no slot (lista da vocação, com ícone), sem digitar.
-- Tudo fica salvo por personagem (storage.thyHelper[nome]), com vários presets.
setDefaultTab("Início")

local SpellDB = modules.gamelib.SpellInfo["Default"]
local CD = modules.game_cooldown
local Spells = modules.gamelib.Spells
local ICONS = modules.gamelib.SpelllistSettings["Default"].iconFile
local RIGHT_BUTTON = 2 -- MouseRightButton

-- filhos por id (não usar widget.id direto: alguns ids batem com métodos do widget)
local function kid(w, id) return w:getChildById(id) end
local function find(w, id) return w:recursiveGetChildById(id) end

local function firstKey(t)
  for k in pairs(t) do return k end
end

local byWords = {}
for spellName, s in pairs(SpellDB) do
  s._name = spellName
  byWords[s.words] = s
end

-- vocação do cliente -> ids de vocação das magias (normal, promovida)
local VOC = {
  [1] = { 4, 8 }, [11] = { 4, 8 }, -- knight
  [2] = { 3, 7 }, [12] = { 3, 7 }, -- paladin
  [3] = { 1, 5 }, [13] = { 1, 5 }, -- sorcerer
  [4] = { 2, 6 }, [14] = { 2, 6 }, -- druid
  [5] = { 9, 10 }, [15] = { 9, 10 }, -- monk
}

-- área das magias de ataque mais comuns (o resto: alvo -> monstros na tela; sem alvo -> raio 3)
local AREA = {
  ["exori"] = { r = 1 }, ["exori gran"] = { r = 1 }, ["exori mas"] = { r = 2 },
  ["exori min"] = { wave = 1 },
  ["exevo gran mas flam"] = { r = 5 }, ["exevo gran mas frigo"] = { r = 5 },
  ["exevo gran mas vis"] = { r = 5 }, ["exevo gran mas tera"] = { r = 5 },
  ["exevo gran mas pox"] = { r = 5 }, ["exevo mas san"] = { r = 3 },
  ["exevo flam hur"] = { wave = 5 }, ["exevo frigo hur"] = { wave = 5 },
  ["exevo tera hur"] = { wave = 5 }, ["exevo vis hur"] = { wave = 5 },
  ["exevo gran frigo hur"] = { wave = 7 },
  ["exevo vis lux"] = { beam = 5 }, ["exevo gran vis lux"] = { beam = 8 },
  ["exevo max mort"] = { beam = 8 },
  ["exori mas pug"] = { r = 2 }, ["exori gran mas pug"] = { r = 3 },
}
-- runas de área: conta os monstros perto do alvo
local AREA_RUNES = { [3161] = 2, [3191] = 2, [3202] = 2, [3175] = 2, [3200] = 1, [3192] = 1 }
local FOOD = { 3582, 3577, 3578, 3583, 3725, 3723, 3724, 3600, 3607, 3606, 3579, 3585, 3587, 3595, 3601, 3593, 3584, 3592, 3586 }

-- ---------------------------------------------------------------- dados salvos
local function defaultPreset()
  local p = {
    haste = { on = false, pz = false, words = "utani hur" },
    eat = false, gold = false,
    heal = { spells = {}, items = {} },
    attack = { on = false, spells = {}, runes = {}, face = false, combo = false, hotkeyPrio = true, key = "" },
    target = { on = false, key = "" },
    bothKey = "",
  }
  return p
end

local function ensure(p)
  local d = defaultPreset()
  for k, v in pairs(d) do
    if p[k] == nil then p[k] = v end
  end
  for k, v in pairs(d.haste) do if p.haste[k] == nil then p.haste[k] = v end end
  for k, v in pairs(d.attack) do if p.attack[k] == nil then p.attack[k] = v end end
  for k, v in pairs(d.target) do if p.target[k] == nil then p.target[k] = v end end
  for i = 1, 3 do p.heal.spells[i] = p.heal.spells[i] or { words = "", hp = 80, mana = 0 } end
  for i = 1, 4 do p.heal.items[i] = p.heal.items[i] or { id = 0, kind = i <= 2 and "hp" or "mana", pct = i <= 2 and 50 or 40 } end
  for i = 1, 5 do p.attack.spells[i] = p.attack.spells[i] or { words = "", mana = 5, count = 1, prio = i } end
  for i = 1, 2 do p.attack.runes[i] = p.attack.runes[i] or { id = 0, count = 1, prio = 5 + i } end
  return p
end

storage.thyHelper = type(storage.thyHelper) == "table" and storage.thyHelper or {}
local charName = name()
local S = storage.thyHelper[charName]
if type(S) ~= "table" then
  S = { enabled = false, current = "Padrao", toggleKey = "", reconnect = false, presets = {} }
  storage.thyHelper[charName] = S
end
S.presets = type(S.presets) == "table" and S.presets or {}
if not S.presets[S.current] then
  S.current = firstKey(S.presets) or "Padrao"
  S.presets[S.current] = S.presets[S.current] or defaultPreset()
end
local P = ensure(S.presets[S.current])

-- ---------------------------------------------------------------- utilidades
local function myVoc()
  return VOC[player:getVocation()]
end

local function vocCanUse(s)
  local v = myVoc()
  if not v then return true end
  for _, id in ipairs(s.vocations or {}) do
    if id == v[1] or id == v[2] then return true end
  end
  return false
end

local function spellReady(s)
  if CD.isCooldownIconActive and CD.isCooldownIconActive(s.id) then return false end
  for g in pairs(s.group or {}) do
    if CD.isGroupCooldownIconActive(g) then return false end
  end
  return true
end

local lastSaid = {}
local lastAny = 0
local function trySay(words, guardMs)
  if now - lastAny < 200 then return false end
  if lastSaid[words] and now - lastSaid[words] < (guardMs or 600) then return false end
  lastSaid[words] = now
  lastAny = now
  say(words)
  return true
end

local function hasItem(id)
  if id <= 100 then return false end
  local ok, c = pcall(function() return player:getInventoryCount(id, 0) end)
  if ok and c and c > 0 then return true end
  return findItem(id) ~= nil
end

local function chebyshev(a, b)
  return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

local function monsters()
  local list, p = {}, pos()
  for _, c in ipairs(getSpectators()) do
    if c:isMonster() and c:getHealthPercent() > 0 then
      local cp = c:getPosition()
      local t = c.getType and c:getType() or 1
      if cp and cp.z == p.z and t < 3 then
        list[#list + 1] = c
      end
    end
  end
  return list
end

-- direção (0 N, 1 E, 2 S, 3 W) do jogador para uma posição
local function dirTo(from, to)
  local dx, dy = to.x - from.x, to.y - from.y
  if math.abs(dx) > math.abs(dy) then
    return dx > 0 and 1 or 3
  end
  return dy > 0 and 2 or 0
end

-- quantos monstros estão na frente (onda/beam) na direção dir
local function countFront(list, dir, len, isBeam)
  local p, n = pos(), 0
  for _, c in ipairs(list) do
    local cp = c:getPosition()
    local dx, dy = cp.x - p.x, cp.y - p.y
    local fwd, lat
    if dir == 0 then fwd, lat = -dy, dx elseif dir == 2 then fwd, lat = dy, dx
    elseif dir == 1 then fwd, lat = dx, dy else fwd, lat = -dx, dy end
    if fwd >= 1 and fwd <= len then
      local width = isBeam and 0 or math.floor((fwd + 1) / 2)
      if math.abs(lat) <= width then n = n + 1 end
    end
  end
  return n
end

-- ---------------------------------------------------------------- liga/desliga
local ui -- janela
local function setStatus(text)
  if ui then find(ui, "statusLabel"):setText(text or "") end
end

local function refreshSwitch()
  if not ui then return end
  find(ui, "enabled"):setOn(S.enabled)
  find(ui, "enabled"):setText(S.enabled and "Auxiliador: Ligado" or "Auxiliador: Desligado")
end

local function setEnabled(v)
  S.enabled = v
  refreshSwitch()
end

local function setAutoTarget(v)
  P.target.on = v
  if TargetBot then
    if v then TargetBot.setOn() else TargetBot.setOff() end
  end
  if ui then find(ui, "autoTarget"):setChecked(v) end
end

local function setAttack(v)
  P.attack.on = v
  if ui then find(ui, "attackOn"):setChecked(v) end
end

-- ---------------------------------------------------------------- cura
local lastPotion = 0
macro(100, function()
  if not S.enabled then return end
  local hpP, mpP = hppercent(), manapercent()
  for _, h in ipairs(P.heal.spells) do
    if h.words ~= "" and hpP <= h.hp and mpP >= h.mana then
      local s = byWords[h.words]
      if not s or (level() >= s.level and mana() >= s.mana and spellReady(s)) then
        if trySay(h.words, 500) then return end
      end
    end
  end
  if now - lastPotion < 1000 then return end
  for _, it in ipairs(P.heal.items) do
    if it.id > 100 then
      local value = it.kind == "mana" and mpP or hpP
      if value <= it.pct and hasItem(it.id) then
        lastPotion = now
        useWith(it.id, player)
        return
      end
    end
  end
end)

-- ---------------------------------------------------------------- ataque
local manualUntil = 0
local comboPos = 0
local lastAttack = 0

onTalk(function(name, level, mode, text)
  if name ~= player:getName() then return end
  text = text:lower()
  if byWords[text] and not (lastSaid[text] and now - lastSaid[text] < 400) then
    manualUntil = now + 1200 -- o jogador soltou uma magia na mão: o auxiliador espera
  end
end)

local function spellCandidate(entry, list, t)
  local s = byWords[entry.words]
  if s then
    if level() < s.level or mana() < s.mana or not spellReady(s) then return false end
  end
  if manapercent() < entry.mana then return false end
  local tp, p = t:getPosition(), pos()
  local area = AREA[entry.words]
  local n
  if area and area.r then
    n = 0
    for _, c in ipairs(list) do
      if chebyshev(c:getPosition(), p) <= area.r then n = n + 1 end
    end
  elseif area and (area.wave or area.beam) then
    local want = dirTo(p, tp)
    if P.attack.face and player:getDirection() ~= want then
      turn(want)
      return "turned"
    end
    n = countFront(list, player:getDirection(), area.wave or area.beam, area.beam ~= nil)
  else
    if s and s.range and s.range > 0 and chebyshev(tp, p) > s.range then return false end
    if s and not s.needTarget and (not s.range or s.range <= 0) then
      n = 0
      for _, c in ipairs(list) do
        if chebyshev(c:getPosition(), p) <= 3 then n = n + 1 end
      end
    else
      n = #list
    end
  end
  return n >= entry.count
end

local function runeCandidate(entry, list, t)
  if not hasItem(entry.id) then return false end
  local rs = Spells.getRuneSpellByItem and Spells.getRuneSpellByItem(entry.id)
  if rs and rs.group and CD.isGroupCooldownIconActive(rs.group) then return false end
  local radius = AREA_RUNES[entry.id]
  local n
  if radius then
    n = 0
    local tp = t:getPosition()
    for _, c in ipairs(list) do
      if chebyshev(c:getPosition(), tp) <= radius then n = n + 1 end
    end
  else
    n = #list
  end
  return n >= entry.count
end

macro(100, function()
  if not S.enabled or not P.attack.on then return end
  if isInPz() then return end
  local t = target()
  if not t then return end
  if P.attack.hotkeyPrio and now < manualUntil then return end
  if now - lastAttack < 250 then return end
  if CD.isGroupCooldownIconActive(1) then return end

  local entries = {}
  for i, e in ipairs(P.attack.spells) do
    if e.words ~= "" then entries[#entries + 1] = { kind = "spell", e = e, prio = e.prio, idx = i } end
  end
  for i, e in ipairs(P.attack.runes) do
    if e.id > 100 then entries[#entries + 1] = { kind = "rune", e = e, prio = e.prio, idx = 10 + i } end
  end
  if #entries == 0 then return end
  table.sort(entries, function(a, b)
    if a.prio == b.prio then return a.idx < b.idx end
    return a.prio < b.prio
  end)

  local list = monsters()
  local start = P.attack.combo and comboPos or 0
  for k = 1, #entries do
    local i = ((start + k - 1) % #entries) + 1
    local en = entries[i]
    local ok
    if en.kind == "spell" then
      ok = spellCandidate(en.e, list, t)
      if ok == "turned" then lastAttack = now return end
      if ok and trySay(en.e.words, 600) then
        comboPos = i
        lastAttack = now
        return
      end
    else
      ok = runeCandidate(en.e, list, t)
      if ok then
        useWith(en.e.id, t)
        comboPos = i
        lastAttack = now
        return
      end
    end
  end
end)

-- ---------------------------------------------------------------- movimento / funções
macro(500, function()
  if not S.enabled or not P.haste.on or P.haste.words == "" then return end
  if hasHaste() or (isInPz() and not P.haste.pz) then return end
  local s = byWords[P.haste.words]
  if s and (level() < s.level or mana() < s.mana or not spellReady(s)) then return end
  trySay(P.haste.words, 2000)
end)

macro(15000, function()
  if not S.enabled or not P.eat then return end
  if player:getRegenerationTime() > 400 then return end
  for _, container in pairs(g_game.getContainers()) do
    for _, item in ipairs(container:getItems()) do
      if table.find(FOOD, item:getId()) then
        return g_game.use(item)
      end
    end
  end
  for _, id in ipairs(FOOD) do
    if hasItem(id) then
      return g_game.useInventoryItem(id)
    end
  end
end)

macro(1000, function()
  if not S.enabled or not P.gold then return end
  for _, container in pairs(g_game.getContainers()) do
    for _, item in ipairs(container:getItems()) do
      local id = item:getId()
      if (id == 3031 or id == 3035) and item:getCount() == 100 then
        return g_game.use(item)
      end
    end
  end
end)

-- ---------------------------------------------------------------- teclas
local waitingKey -- função que recebe a tecla
onKeyDown(function(keys)
  if waitingKey then
    local cb = waitingKey
    waitingKey = nil
    cb(keys == "Escape" and "" or keys)
    return
  end
  if keys == "" then return end
  if S.toggleKey ~= "" and keys == S.toggleKey then
    setEnabled(not S.enabled)
  end
  if P.bothKey ~= "" and keys == P.bothKey then
    local v = not (P.attack.on and P.target.on)
    setAttack(v)
    setAutoTarget(v)
  else
    if P.attack.key ~= "" and keys == P.attack.key then setAttack(not P.attack.on) end
    if P.target.key ~= "" and keys == P.target.key then setAutoTarget(not P.target.on) end
  end
end)

-- ---------------------------------------------------------------- janela
local function setSlotSpell(slot, words)
  local s = byWords[words or ""]
  if s and s.clientId then
    kid(slot, "icon"):setImageSource(ICONS)
    kid(slot, "icon"):setImageClip(Spells.getImageClip(s.clientId))
    kid(slot, "icon"):setVisible(true)
    kid(slot, "empty"):setVisible(false)
    slot:setTooltip(s._name .. "\n" .. s.words .. "\n(botão direito limpa)")
  elseif words and words ~= "" then
    kid(slot, "icon"):setVisible(false)
    kid(slot, "empty"):setVisible(true)
    kid(slot, "empty"):setText(words:sub(1, 5))
    slot:setTooltip(words)
  else
    kid(slot, "icon"):setVisible(false)
    kid(slot, "empty"):setVisible(true)
    kid(slot, "empty"):setText("...")
    slot:setTooltip("Clique para escolher a magia")
  end
end

-- filter(s) -> true se a magia entra na lista
local function openPicker(filter, onPick)
  local win = UI.createWindow("ThyHelperSpellPicker")
  local spells = {}
  for _, s in pairs(SpellDB) do
    if s.type == "Instant" and vocCanUse(s) and filter(s) then
      spells[#spells + 1] = s
    end
  end
  table.sort(spells, function(a, b)
    if a.level == b.level then return a._name < b._name end
    return a.level < b.level
  end)
  for _, s in ipairs(spells) do
    local w = UI.createWidget("ThyHelperSpellEntry", kid(win, "spellList"))
    if s.clientId then
      kid(w, "icon"):setImageSource(ICONS)
      kid(w, "icon"):setImageClip(Spells.getImageClip(s.clientId))
    end
    kid(w, "name"):setText(s._name .. "  (lv " .. s.level .. ")")
    kid(w, "words"):setText(s.words .. "  -  " .. s.mana .. " mana")
    w.onClick = function()
      onPick(s.words)
      win:destroy()
    end
  end
  if #spells == 0 then
    kid(win, "hint"):setText("Nenhuma magia disponível para a sua vocação.")
  end
end

local function isGroup(s, g) return s.group and s.group[g] ~= nil end
local FILTER_HEAL = function(s) return isGroup(s, 2) end
local FILTER_ATTACK = function(s) return isGroup(s, 1) end
local FILTER_HASTE = function(s) return s.words:find("utani") ~= nil or s.words:find("utamo tempo san") ~= nil end

local function bindSpellSlot(slot, getWords, setWords, filter)
  setSlotSpell(slot, getWords())
  slot.onMouseRelease = function(widget, mousePos, button)
    if button == RIGHT_BUTTON then
      setWords("")
      setSlotSpell(slot, "")
    else
      openPicker(filter, function(words)
        setWords(words)
        setSlotSpell(slot, words)
      end)
    end
    return true
  end
end

local function bindSpin(spin, get, set)
  spin:setValue(get())
  spin.onValueChange = function(widget, value) set(value) end
end

local function bindCheck(check, get, set)
  check:setChecked(get())
  check.onCheckChange = function(widget, checked) set(checked) end
end

local function keyText(k)
  return (k and k ~= "") and k or "Nenhuma"
end

local function bindKey(button, get, set)
  button:setText(keyText(get()))
  button.onClick = function()
    button:setText("aperte...")
    setStatus("Aperte a tecla (Esc limpa).")
    waitingKey = function(k)
      set(k)
      button:setText(keyText(k))
      setStatus(k ~= "" and ("Tecla definida: " .. k) or "Tecla removida.")
    end
  end
end

local buildPresetList -- declarado abaixo

local function fillWindow()
  if not ui then return end
  local L, H, A = find(ui, "left"), find(ui, "heal"), find(ui, "attack")
  refreshSwitch()
  bindKey(find(L, "toggleKey"), function() return S.toggleKey end, function(k) S.toggleKey = k end)

  bindSpellSlot(find(L, "hasteSlot"), function() return P.haste.words end, function(w) P.haste.words = w end, FILTER_HASTE)
  bindCheck(find(L, "autoHaste"), function() return P.haste.on end, function(v) P.haste.on = v end)
  bindCheck(find(L, "hastePz"), function() return P.haste.pz end, function(v) P.haste.pz = v end)
  bindCheck(find(L, "autoEat"), function() return P.eat end, function(v) P.eat = v end)
  bindCheck(find(L, "autoReconnect"), function() return g_settings.getBoolean("autoReconnect", false) end, function(v) g_settings.set("autoReconnect", v) end)
  bindCheck(find(L, "changeGold"), function() return P.gold end, function(v) P.gold = v end)

  find(H, "healSpells"):destroyChildren()
  for i, h in ipairs(P.heal.spells) do
    local row = UI.createWidget("ThyHelperHealRow", find(H, "healSpells"))
    bindSpellSlot(kid(row, "slot"), function() return h.words end, function(w) h.words = w end, FILTER_HEAL)
    bindSpin(kid(row, "hp"), function() return h.hp end, function(v) h.hp = v end)
    bindSpin(kid(row, "mana"), function() return h.mana end, function(v) h.mana = v end)
  end
  find(H, "potions"):destroyChildren()
  for i, it in ipairs(P.heal.items) do
    local row = UI.createWidget("ThyHelperPotionRow", find(H, "potions"))
    kid(row, "slot"):setItemId(it.id)
    kid(row, "slot").onItemChange = function(widget) it.id = widget:getItemId() end
    kid(row, "kind"):setText(it.kind == "mana" and "Mana" or "HP")
    kid(row, "kind").onClick = function()
      it.kind = it.kind == "mana" and "hp" or "mana"
      kid(row, "kind"):setText(it.kind == "mana" and "Mana" or "HP")
    end
    bindSpin(kid(row, "pct"), function() return it.pct end, function(v) it.pct = v end)
  end

  find(A, "spells"):destroyChildren()
  for i, e in ipairs(P.attack.spells) do
    local row = UI.createWidget("ThyHelperAtkRow", find(A, "spells"))
    bindSpellSlot(kid(row, "slot"), function() return e.words end, function(w) e.words = w end, FILTER_ATTACK)
    bindSpin(kid(row, "mana"), function() return e.mana end, function(v) e.mana = v end)
    bindSpin(kid(row, "count"), function() return e.count end, function(v) e.count = v end)
    bindSpin(kid(row, "prio"), function() return e.prio end, function(v) e.prio = v end)
  end
  find(A, "runes"):destroyChildren()
  for i, e in ipairs(P.attack.runes) do
    local row = UI.createWidget("ThyHelperRuneRow", find(A, "runes"))
    kid(row, "slot"):setItemId(e.id)
    kid(row, "slot").onItemChange = function(widget) e.id = widget:getItemId() end
    bindSpin(kid(row, "count"), function() return e.count end, function(v) e.count = v end)
    bindSpin(kid(row, "prio"), function() return e.prio end, function(v) e.prio = v end)
  end
  bindCheck(find(A, "face"), function() return P.attack.face end, function(v) P.attack.face = v end)
  bindCheck(find(A, "combo"), function() return P.attack.combo end, function(v) P.attack.combo = v end)
  bindCheck(find(A, "hotkeyPrio"), function() return P.attack.hotkeyPrio end, function(v) P.attack.hotkeyPrio = v end)
  bindCheck(find(A, "autoTarget"), function() return P.target.on end, function(v) setAutoTarget(v) end)
  bindCheck(find(A, "attackOn"), function() return P.attack.on end, function(v) P.attack.on = v end)
  bindKey(find(A, "targetKey"), function() return P.target.key end, function(k) P.target.key = k end)
  bindKey(find(A, "attackKey"), function() return P.attack.key end, function(k) P.attack.key = k end)
  bindKey(find(A, "bothKey"), function() return P.bothKey end, function(k) P.bothKey = k end)
  find(A, "bothKey"):setTooltip("Uma tecla que liga/desliga o Alvo automático e o Ataque juntos")
end

local function switchPreset(name)
  if not S.presets[name] then return end
  S.current = name
  P = ensure(S.presets[name])
  fillWindow()
  setStatus("Preset: " .. name)
end

buildPresetList = function()
  if not ui then return end
  local combo = find(ui, "preset")
  combo.onOptionChange = nil
  combo:clearOptions()
  local names = {}
  for n in pairs(S.presets) do names[#names + 1] = n end
  table.sort(names)
  for _, n in ipairs(names) do combo:addOption(n) end
  combo:setCurrentOption(S.current)
  combo.onOptionChange = function(widget, text) switchPreset(text) end
end

local function showTab(which)
  find(ui, "heal"):setVisible(which == "heal")
  find(ui, "attack"):setVisible(which == "attack")
  find(ui, "tabHeal"):setOn(which == "heal")
  find(ui, "tabAttack"):setOn(which == "attack")
  find(ui, "tabHeal"):setColor(which == "heal" and "#ffffff" or "#909090")
  find(ui, "tabAttack"):setColor(which == "attack" and "#ffffff" or "#909090")
end

local function askName(title, cb)
  UI.SinglelineEditorWindow("", { title = title }, function(text)
    text = (text or ""):trim()
    if text ~= "" then cb(text) end
  end)
end

local function openWindow()
  if ui then
    ui:show()
    ui:raise()
    ui:focus()
    return
  end
  ui = UI.createWindow("ThyHelperWindow")
  find(ui, "closeButton").onClick = function() ui:hide() end
  find(ui, "enabled").onClick = function() setEnabled(not S.enabled) end
  find(ui, "tabHeal").onClick = function() showTab("heal") end
  find(ui, "tabAttack").onClick = function() showTab("attack") end
  find(ui, "presetNew").onClick = function()
    askName("Nome do preset novo", function(n)
      if S.presets[n] then return setStatus("Já existe um preset com esse nome.") end
      S.presets[n] = defaultPreset()
      switchPreset(n)
      buildPresetList()
    end)
  end
  find(ui, "presetRename").onClick = function()
    askName("Novo nome para '" .. S.current .. "'", function(n)
      if S.presets[n] then return setStatus("Já existe um preset com esse nome.") end
      S.presets[n] = S.presets[S.current]
      S.presets[S.current] = nil
      S.current = n
      buildPresetList()
      setStatus("Preset renomeado: " .. n)
    end)
  end
  find(ui, "presetDelete").onClick = function()
    local count = 0
    for _ in pairs(S.presets) do count = count + 1 end
    if count <= 1 then return setStatus("Precisa ter pelo menos um preset.") end
    UI.ConfirmationWindow("Apagar preset", "Apagar o preset '" .. S.current .. "'?", function()
      S.presets[S.current] = nil
      switchPreset(firstKey(S.presets))
      buildPresetList()
    end)
  end
  buildPresetList()
  fillWindow()
  showTab("heal")
  setStatus("Preset: " .. S.current)
end

-- painel no Início do auxiliador
UI.Label("Auxiliador Thyrania")
UI.Button("Abrir o Auxiliador", function() openWindow() end)
local quick = UI.Button(S.enabled and "Ligado (clique p/ desligar)" or "Desligado (clique p/ ligar)", function(widget)
  setEnabled(not S.enabled)
end)
local oldSet = setEnabled
setEnabled = function(v)
  oldSet(v)
  quick:setText(v and "Ligado (clique p/ desligar)" or "Desligado (clique p/ ligar)")
  quick:setColor(v and "#5fd35f" or "#e06060")
end
setEnabled(S.enabled)
if P.target.on and TargetBot then TargetBot.setOn() end
UI.Separator()
