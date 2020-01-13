-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BELT BRUSH

-- dependencies
local event = require('lualib.event')
local util = require('lualib.util')

-- locals
local draw_circle = rendering.draw_circle
local draw_line = rendering.draw_line
local draw_sprite = rendering.draw_sprite

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
  local function create_line(from, to)
    objects[#objects+1] = draw_line{
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
    create_line({x=target.x+i, y=target.y-1.5}, {x=target.x+i, y=target.y+1.5})
  end
  -- horizontal
  for i=-0.5,0.5 do
    create_line({x=target.x-1.5, y=target.y+i}, {x=target.x+1.5, y=target.y+i})
  end
  return objects
end

-- returns the direction that pos2 is in with respect to pos1
-- cardinal directions only
local function offset_to_direction(pos1, pos2)
  return ((pos1.x > pos2.x and pos1.y == pos2.y) and defines.direction.west)
  or ((pos1.x < pos2.x and pos1.y == pos2.y) and defines.direction.east)
  or ((pos1.y > pos2.y and pos1.x == pos2.x) and defines.direction.north)
  or defines.direction.south
end

local function set_entity(name, player, position, direction, direct_spawn, underground_type)
  player.surface.create_entity{
    name = direct_spawn and name or 'entity-ghost',
    position=position,
    direction = direction,
    force = player.force,
    player = player,
    raise_built = true,
    create_build_effect_smoke = false,
    type = underground_type,
    inner_name = direct_spawn and nil or name
  }
end

local function spawn_error_text(player, position, text)
  player.surface.create_entity{
    name = 'flying-text',
    position=position,
    force = player.force,
    player = player,
    text = text,
    render_player_index = player.index
  }
  player.play_sound{path='utility/cannot_build'}
end

local function draw_indicator(player, position)
  return rendering.draw_circle{
    color = {r=1,g=1,b=1,a=0.5},
    radius = 0.1,
    filled = true,
    target = position,
    surface = player.surface,
    players = {player.index}
  }
end

event.on_player_used_capsule(function(e)
  local item = e.item
  if item and item.valid and item.name == 'rbt-belt-brush' then
    local player = game.get_player(e.player_index)
    local is_editor = player.controller_type == defines.controllers.editor
    local global_data = global.belt_brush
    local data = global.players[e.player_index].belt_brush
    local queue = data.queue
    local tile = util.position.add(util.position.floor(e.position), {x=0.5,y=0.5})
    if queue == false then
      -- update on_tick data
      global_data[e.player_index] = game.tick
      -- don't do anything else
      return
    end -- drag was invalidated
    if #queue == 0 then -- new drag
      -- check to be sure it's on a blank tile
      local entities = player.surface.find_entities(util.position.to_tile_area(e.position))
      if #entities > 0 then
        player.print{'rbt-message.start-on-empty-tile'}
        return
      end
      data.queue = {tile}
      data.grid = draw_grid(player, tile)
      event.on_tick(belt_brush_tick, {name='belt_brush_tick', player_index=e.player_index})
      global_data[e.player_index] = game.tick
      -- draw indicator
      data.objects[1] = draw_indicator(player, tile)
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
          -- check if any entities will collide with the belt
          for i=1,#entities do
            local entity = entities[i]
            if entity.prototype.collision_mask['object-layer'] then
              -- check queue length
              if #queue > 1 then
                -- iterate over the queue to make sure the direction is good
                local cur_dir = offset_to_direction(queue[#queue], tile)
                for i2=2,#queue do
                  if offset_to_direction(queue[i2-1], queue[i2]) ~= cur_dir then
                    spawn_error_text(player, tile, {'rbt-message.invalid-drag'})
                    data.queue = false
                    return
                  end
                end
                goto add_position
              else
                set_entity('underground-belt', player, queue[1], offset_to_direction(queue[1], tile), is_editor, 'input')
                goto clear_indicators
              end
            end
          end
        else
          -- check queue length
          if #queue > 1 then
            -- iterate over the queue to make sure the direction is good
            local cur_dir = offset_to_direction(queue[#queue], tile)
            for i2=2,#queue do
              if offset_to_direction(queue[i2-1], queue[i2]) ~= cur_dir then
                spawn_error_text(player, tile, {'rbt-message.invalid-drag'})
                data.queue = false
                return
              end
            end
            set_entity('underground-belt', player, tile, offset_to_direction(queue[#queue], tile), is_editor, 'output')
            data.queue = {}
            queue = data.queue
          else
            -- set previous tile to be a belt
            set_entity('transport-belt', player, queue[1], offset_to_direction(queue[1], tile), is_editor)
            data.queue = {}
            queue = data.queue
          end
        end
        ::clear_indicators::
        for i=1,#data.objects do
          rendering.destroy(data.objects[i])
        end
        data.objects = {}
        ::add_position::
        queue[#queue+1] = tile
        -- draw indicator
        data.objects[#data.objects+1] = draw_indicator(player, tile)
      end
    end
  end
end)

event.register(finish_drag_event, function(e)
  game.print('finish dragging!')
  local data = global.players[e.player_index].belt_brush
  data.queue = {}
  for i=1,#data.objects do
    rendering.destroy(data.objects[i])
  end
  data.objects = {}
  local grid = data.grid
  for i=1,#grid do
    rendering.destroy(grid[i])
  end
  data.grid = {}
end)