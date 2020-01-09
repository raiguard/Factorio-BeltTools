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

-- draw thin 3x3 tilegrid to aid with positioning
local function draw_grid(player, target)
  local objects = {}
  local function draw_line(from, to)
    objects[#objects+1] = rendering.draw_line{
      color = {},
      width = 1,
      from = from,
      to = to,
      surface = player.surface,
      players = {player}
    }
  end
  -- vertical
  for i=-0.5,0.5 do
    draw_line({x=target.x+i, y=target.y-1.5}, {x=target.x+i, y=target.y+1.5})
  end
  -- horizontal
  for i=-0.5,0.5 do
    draw_line({x=target.x-1.5, y=target.y+i}, {x=target.x+1.5, y=target.y+i})
  end
  return objects
end

event.on_player_used_capsule(function(e)
  local item = e.item
  if item and item.valid and item.name == 'bt-belt-brush' then
    local player = game.get_player(e.player_index)
    local global_data = global.belt_brush
    local data = global.players[e.player_index].belt_brush
    local queue = data.queue
    local tile = util.position.add(util.position.floor(e.position), {x=0.5,y=0.5})
    if not queue then -- new drag
      data.queue = {tile}
      data.grid = draw_grid(player, tile)
      event.on_tick(belt_brush_tick, {name='belt_brush_tick', player_index=e.player_index})
      global_data[e.player_index] = game.tick
    else -- currently dragging
      -- update on_tick data
      global_data[e.player_index] = game.tick
      if not util.position.equals(tile, queue[#queue]) then
        -- update grid position
        local grid = data.grid
        for i=1,#grid do
          rendering.destroy(grid[i])
        end
        data.grid = draw_grid(player, tile)
        -- check current tile for entities
        local entities = player.surface.find_entities(util.position.to_tile_area(e.position))
        if #entities > 0 then
          queue[#queue+1] = tile
        else
          -- place ghosts for queue
          for i=1,#queue do
            rendering.draw_circle{
              color = {r=1,g=1,b=1,a=0.5},
              radius = 0.1,
              filled = true,
              target = queue[i],
              surface = player.surface,
              players = {e.player_index}
            }
          end
          -- reset queue
          data.queue = {tile}
        end
      end
    end
  end
end)

event.register(finish_drag_event, function(e)
  game.print('finish dragging!')
  local data = global.players[e.player_index].belt_brush
  data.queue = nil
  local grid = data.grid
  for i=1,#grid do
    rendering.destroy(grid[i])
  end
end)