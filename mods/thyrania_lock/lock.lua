-- Thyrania: opcao "Travar / destravar item" no clique direito de um item do inventario ou da mochila.
-- Item travado nao e vendido para NPC (o servidor confere). Extended opcode 121.
local OPCODE = 121
local NAME = 'Travar / destravar item'

local function isInventoryOrContainer(thing)
  if not thing or not thing:isItem() then return false end
  local pos = thing:getPosition()
  return pos and pos.x == 65535
end

local function onLock(menuPosition, lookThing, useThing, creatureThing)
  local item = useThing or lookThing
  if not isInventoryOrContainer(item) then return end
  local pos = item:getPosition()
  local protocol = g_game.getProtocolGame()
  if protocol then
    protocol:sendExtendedOpcode(OPCODE, string.format('%d,%d,%d,%d', pos.x, pos.y, pos.z, item:getId()))
  end
end

local function condition(menuPosition, lookThing, useThing, creatureThing)
  return isInventoryOrContainer(useThing or lookThing)
end

function init()
  if modules.game_interface and modules.game_interface.addMenuHook then
    modules.game_interface.addMenuHook('thyrania', NAME, onLock, condition)
  end
end

function terminate()
  if modules.game_interface and modules.game_interface.removeMenuHook then
    modules.game_interface.removeMenuHook('thyrania', NAME)
  end
end
