-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BELT BRUSH

-- dependencies
local event = require('lualib.event')
local util = require('lualib.util')

local finish_drag_event = event.generate_id('belt_brush_finish_drag')

local function belt_brush_tick(e)
  local players = global.players
  local global_data = global.belt_brush
  local tick = game.tick
  local end_wait = global.settings.capsule_end_wait
  for i,last_tick in ipairs(global_data) do
    if tick > last_tick + end_wait then
      global_data[i] = nil
      event.deregister(defines.events.on_tick, belt_brush_tick, {name='belt_brush_tick', player_index=i})
      event.raise(finish_drag_event, {player_index=i})
    end
  end
end

event.on_player_used_capsule(function(e)
  local item = e.item
  if item and item.valid and item.name == 'bt-belt-brush' then
    local player = game.get_player(e.player_index)
    local global_data = global.belt_brush
    local data = global.players[e.player_index].belt_brush
    local queue = data.queue
    if not queue then -- new drag
      data.queue = {util.position.floor(e.position)}
      event.on_tick(belt_brush_tick, {name='belt_brush_tick', player_index=e.player_index})
      global_data[e.player_index] = game.tick
    else -- currently dragging
      -- update on_tick data
      global_data[e.player_index] = game.tick
      -- check if we have changed tiles
      local tile = util.position.floor(e.position)
      if not util.position.equals(tile, queue[#queue]) then
        -- check current tile for entities
        local entities = player.surface.find_entities(util.position.to_tile_area(e.position))
        if #entities > 0 then
          queue[#queue+1] = tile
        else
          queue[1] = tile
        end
      end
    end
  end
end)

event.register(finish_drag_event, function(e)
  game.print('finish dragging!')
  global.players[e.player_index].belt_brush.queue = nil
end)