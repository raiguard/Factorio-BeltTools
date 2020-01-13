-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BELT ROUTE VISUALISATION

-- dependencies
local event = require('lualib.event')
local util = require('lualib.util')

-- locals
local draw_sprite = rendering.draw_sprite
local draw_line = rendering.draw_line
local destroy = rendering.destroy

-- --------------------------------------------------
-- UTILITIES

local function destroy_objects(t)
  for i=1,#t do
    destroy(t[i])
  end
end

-- --------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  global.route_visualisation = {}
end)

event.on_player_used_capsule(function(e)
  local item = e.item
  if item and item.valid and item.name == 'rbt-route-visualisation' then
    local data = global.route_visualisation
    if game.tick - (data.last_thrown_tick or 0) > 10 then
      -- clear previous objects, if any
      if data.objects then destroy_objects(data.objects) end
      data.iteration = {}
    end
    data.last_thrown_tick = game.tick
  end
end)