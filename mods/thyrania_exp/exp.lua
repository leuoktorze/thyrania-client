-- Thyrania: bonus de exp ativos. O servidor manda pelo extended opcode 123:
-- "boost=segundos;boostpct=50;vip=10;itens=3;stamina=50"
-- Aparece na janela Skills ("Bonus de Exp") e, enquanto o boost com tempo estiver ativo, na tela.
local OPCODE = 123
local info = nil
local boostEnd = 0
local label = nil
local ticker = nil

local function fmtTime(sec)
  sec = math.max(0, sec)
  return string.format('%dh%02d', math.floor(sec / 3600), math.floor(sec % 3600 / 60))
end

local function ensureLabel()
  if label and not label:isDestroyed() then return label end
  local map = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
  if not map then return nil end
  label = g_ui.createWidget('Label', map)
  label:setId('thyraniaExpBoost')
  label:addAnchor(AnchorTop, 'parent', AnchorTop)
  label:addAnchor(AnchorRight, 'parent', AnchorRight)
  label:setMarginTop(28)
  label:setMarginRight(8)
  label:setPhantom(true)
  label:setFont('verdana-11px-antialised')
  label:setColor('#7dff7d')
  label:setBackgroundColor('#00000088')
  label:setTextAutoResize(true)
  label:hide()
  return label
end

local function skillsRow()
  local skills = modules.game_skills
  local window = skills and skills.skillsWindow
  if not window or window:isDestroyed() then
    window = rootWidget:recursiveGetChildById('skillWindow')
  end
  return window and window:recursiveGetChildById('thyraniaExpBonus')
end

local function update()
  if not info then return end
  local left = boostEnd - os.time()
  local parts, total = {}, 1
  if left > 0 then
    total = total * (1 + info.boostpct / 100)
    parts[#parts + 1] = string.format('Boost +%d%% (%s)', info.boostpct, fmtTime(left))
  end
  if info.vip > 0 then
    total = total * (1 + info.vip / 100)
    parts[#parts + 1] = string.format('VIP +%d%%', info.vip)
  end
  if info.itens > 0 then
    total = total * (1 + info.itens / 100)
    parts[#parts + 1] = string.format('Itens raros +%d%%', info.itens)
  end
  if info.stamina > 0 then
    total = total * (1 + info.stamina / 100)
    parts[#parts + 1] = string.format('Stamina +%d%%', info.stamina)
  end
  local pct = math.floor((total - 1) * 100 + 0.5)

  local row = skillsRow()
  if row then
    local value = row:getChildById('value')
    if value then
      value:setText(pct > 0 and ('+' .. pct .. '%') or '-')
      value:setColor(left > 0 and '#7dff7d' or (pct > 0 and '#ffffff' or '#888888'))
    end
    row:setTooltip(#parts > 0 and table.concat(parts, '\n') or 'Nenhum bonus de exp ativo')
  end

  local l = ensureLabel()
  if l then
    if left > 0 then
      l:setText(string.format(' Exp +%d%%  |  boost %s ', pct, fmtTime(left)))
      l:show()
      l:raise()
    else
      l:hide()
    end
  end
end

local function onInfo(protocol, opcode, buffer)
  local t = {}
  for k, v in string.gmatch(buffer or '', '(%w+)=(%-?%d+)') do
    t[k] = tonumber(v)
  end
  info = { boostpct = t.boostpct or 50, vip = t.vip or 0, itens = t.itens or 0, stamina = t.stamina or 0 }
  boostEnd = os.time() + (t.boost or 0)
  update()
end

local function onGameEnd()
  info = nil
  if label and not label:isDestroyed() then label:hide() end
end

function init()
  ProtocolGame.registerExtendedOpcode(OPCODE, onInfo)
  connect(g_game, { onGameEnd = onGameEnd })
  ticker = cycleEvent(update, 1000)
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE)
  disconnect(g_game, { onGameEnd = onGameEnd })
  if ticker then removeEvent(ticker) ticker = nil end
  if label and not label:isDestroyed() then label:destroy() end
  label = nil
end
