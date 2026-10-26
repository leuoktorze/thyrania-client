-- Thyrania: mostra no canto da tela o progresso das tasks (o servidor manda pelo extended opcode 122
-- a cada kill: "Nome:kills:total;Nome:kills:total").
local OPCODE = 122
local label = nil

local function ensureLabel()
  if label and not label:isDestroyed() then return label end
  local map = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
  if not map then return nil end
  label = g_ui.createWidget('Label', map)
  label:setId('thyraniaTaskTracker')
  label:addAnchor(AnchorTop, 'parent', AnchorTop)
  label:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  label:setMarginTop(28)
  label:setMarginLeft(8)
  label:setPhantom(true)
  label:setFont('verdana-11px-antialised')
  label:setColor('#ffd34d')
  label:setBackgroundColor('#00000088')
  label:setTextAutoResize(true)
  label:setTextAlign(AlignLeft)
  label:hide()
  return label
end

local function onTasks(protocol, opcode, buffer)
  local l = ensureLabel()
  if not l then return end
  local lines = {}
  for name, kills, total in string.gmatch(buffer or '', '([^:;]+):(%d+):(%d+)') do
    kills, total = tonumber(kills), tonumber(total)
    lines[#lines + 1] = string.format('%s  %d/%d%s', name, kills, total, kills >= total and '  (pronta!)' or '')
  end
  if #lines == 0 then
    l:hide()
    return
  end
  l:setText(' Tasks\n ' .. table.concat(lines, '\n ') .. ' ')
  l:show()
  l:raise()
end

local function onGameEnd()
  if label and not label:isDestroyed() then
    label:hide()
  end
end

function init()
  ProtocolGame.registerExtendedOpcode(OPCODE, onTasks)
  connect(g_game, { onGameEnd = onGameEnd })
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE)
  disconnect(g_game, { onGameEnd = onGameEnd })
  if label and not label:isDestroyed() then
    label:destroy()
  end
  label = nil
end
