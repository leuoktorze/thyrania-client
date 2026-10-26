-- Thyrania: o 8.60 nao informa ao cliente quanto tempo de comida falta (regeneration time = 0),
-- entao o "comer sozinho" comia sem parar. Aqui ele come ate aparecer "You are full" e espera 1 min.
local fullUntil = 0
onTextMessage(function(mode, text)
  if text:lower():find("you are full") then
    fullUntil = now + 60000
  end
end)
function thyraniaHungry()
  if g_game.getFeature(GamePlayerRegenerationTime) then
    return player:getRegenerationTime() <= 400
  end
  return now >= fullUntil
end

setDefaultTab("Cura")
if voc() ~= 1 and voc() ~= 11 then
    if storage.foodItems then
        local t = {}
        for i, v in pairs(storage.foodItems) do
            if not table.find(t, v.id) then
                table.insert(t, v.id)
            end
        end
        local foodItems = { 3607, 3585, 3592, 3600, 3601 }
        for i, item in pairs(foodItems) do
            if not table.find(t, item) then
                table.insert(storage.foodItems, item)
            end
        end
    end
    macro(500, "Magia de comida", function()
        if thyraniaHungry() then
            cast("exevo pan", 60000)
        end
    end)
end

UI.Label("Eatable items:")
if type(storage.foodItems) ~= "table" then
  storage.foodItems = {3725, 3582, 3577}
end

local foodContainer = UI.Container(function(widget, items)
  storage.foodItems = items
end, true)
foodContainer:setHeight(35)
foodContainer:setItems(storage.foodItems)

macro(500, "Eat Food", function()
  if not thyraniaHungry() or not storage.foodItems[1] then return end
  -- search for food in containers
  for _, container in pairs(g_game.getContainers()) do
    for __, item in ipairs(container:getItems()) do
      for i, foodItem in ipairs(storage.foodItems) do
        if item:getId() == foodItem.id then
          g_game.use(item)
          delay(1500)
          return
        end
      end
    end
  end
end)
UI.Separator()