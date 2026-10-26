-- Thyrania: pinta o fundo/borda dos itens conforme a raridade (Incomum, Raro, Epico, Lendario).
-- O 8.60 nao manda a raridade junto com o item; entao, sempre que o inventario ou um container
-- muda, este mod pergunta ao servidor (extended opcode 120) e recebe "slot:raridade".
local OPCODE = 120
local COLORS = {
  [1] = '#1eff00', -- incomum
  [2] = '#0070dd', -- raro
  [3] = '#a335ee', -- epico
  [4] = '#ff8000', -- lendario
}
local pending = {}

local function send(key)
  local protocol = g_game.getProtocolGame()
  if protocol and g_game.isOnline() then
    protocol:sendExtendedOpcode(OPCODE, key)
  end
end

-- junta varias mudancas seguidas num pedido so
local function request(key)
  if pending[key] then return end
  pending[key] = scheduleEvent(function()
    pending[key] = nil
    send(key)
  end, 120)
end

local function paint(widget, tier)
  if not widget then return end
  local color = COLORS[tier or 0]
  if color then
    widget:setBorderWidth(1)
    widget:setBorderColor(color)
    widget:setBackgroundColor(color .. '44')
  elseif widget.thyraniaRarity then
    widget:setBorderWidth(0)
    widget:setBackgroundColor('alpha')
  end
  widget.thyraniaRarity = color and tier or nil
end

local function parse(list)
  local tiers = {}
  for slot, tier in string.gmatch(list or '', '(%d+):(%d+)') do
    tiers[tonumber(slot)] = tonumber(tier)
  end
  return tiers
end

local function onOpcode(protocol, opcode, buffer)
  local kind, list = buffer:match('^(%w+)|(.*)$')
  if not kind then return end
  local tiers = parse(list)
  if kind == 'i' then
    local panel = modules.game_inventory and modules.game_inventory.inventoryPanel
    if not panel then return end
    for slot = InventorySlotFirst or 1, InventorySlotLast or 10 do
      paint(panel:getChildById('slot' .. slot), tiers[slot])
    end
  else
    local id = tonumber(kind:match('^c(%d+)$'))
    local container = id and g_game.getContainer(id)
    if not container or not container.itemsPanel then return end
    for slot = 0, container:getCapacity() - 1 do
      paint(container.itemsPanel:getChildById('item' .. slot), tiers[slot])
    end
  end
end

local function onContainerChange(container)
  if container then
    request('c' .. container:getId())
  end
end

local function onInventoryChange()
  request('i')
end

local function onGameStart()
  request('i')
end

function init()
  ProtocolGame.registerExtendedOpcode(OPCODE, onOpcode)
  connect(Container, {
    onOpen = onContainerChange,
    onSizeChange = onContainerChange,
    onUpdateItem = onContainerChange,
    onAddItem = onContainerChange,
    onRemoveItem = onContainerChange,
  })
  connect(LocalPlayer, { onInventoryChange = onInventoryChange })
  connect(g_game, { onGameStart = onGameStart })
  if g_game.isOnline() then onGameStart() end
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE)
  disconnect(Container, {
    onOpen = onContainerChange,
    onSizeChange = onContainerChange,
    onUpdateItem = onContainerChange,
    onAddItem = onContainerChange,
    onRemoveItem = onContainerChange,
  })
  disconnect(LocalPlayer, { onInventoryChange = onInventoryChange })
  disconnect(g_game, { onGameStart = onGameStart })
  for _, event in pairs(pending) do removeEvent(event) end
  pending = {}
end
