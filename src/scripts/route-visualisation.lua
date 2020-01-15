-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BELT ROUTE VISUALISATION

-- dependencies
local event = require('lualib.event')
local util = require('lualib.util')

-- locals
local draw_sprite = rendering.draw_sprite
local draw_line = rendering.draw_line
local destroy = rendering.destroy
local table_remove = table.remove
local bor = bit32.bor
local lshift = bit32.lshift
local op_dir = util.oppositedirection

-- --------------------------------------------------
-- UTILITIES

local function destroy_objects(t)
  for _,o in pairs(t) do
    destroy(o)
  end
end

local valid_types = {
  ['transport-belt'] = true,
  ['underground-belt'] = true,
  ['splitter'] = true
}

-- --------------------------------------------------
-- TRANSPORT BELT PROPEGATOR

-- local function get_directions_splitter(current_entity)
--   local neighbours = current_entity[2]
--   local sprite = 0
--   sprite = neighbours.left_output_target and bor(sprite, lshift(1, 0)) or sprite
--   sprite = neighbours.right_output_target and bor(sprite, lshift(1, 2)) or sprite
--   sprite = neighbours.right and bor(sprite, lshift(1, 4)) or sprite
--   sprite = neighbours.left and bor(sprite, lshift(1, 6)) or sprite
--   return sprite
-- end

local bitwise_marker_entry = {
  [0x00] = 1,
  [0x01] = 2,
  [0x04] = 3,
  [0x05] = 4,
  [0x10] = 5,
  [0x11] = 6,
  [0x14] = 7,
  [0x15] = 8,
  [0x40] = 9,
  [0x41] = 10,
  [0x44] = 11,
  [0x45] = 12,
  [0x50] = 13,
  [0x51] = 14,
  [0x54] = 15,
  [0x55] = 16
}

local function get_neighbour_sides(s_dir, s_pos, s_neighbours)
  local output = {inputs={}, outputs={}}
  local def_dir = defines.direction
  for dir,t in pairs(s_neighbours) do
    for _,entity in ipairs(t) do
      local pos = entity.position
      if s_dir == def_dir.north then
        output[dir][pos.x < s_pos.x and 'left' or 'right'] = entity
      elseif s_dir == def_dir.east then
        output[dir][pos.y < s_pos.y and 'left' or 'right'] = entity
      elseif s_dir == def_dir.south then
        output[dir][pos.x < s_pos.x and 'right' or 'left'] = entity
      elseif s_dir == def_dir.west then
        output[dir][pos.y < s_pos.y and 'right' or 'left'] = entity
      end
    end
  end
  return output
end

local function iterate_batch(e)
  for pi,data in ipairs(global.belt_iterator) do
    local entities = data.entities
    local objects = data.objects
    local new_entities = {}
    for i=1,#entities do
      local t = entities[i]
      local entity = t.entity
      local entity_direction = entity.direction
      local entity_type = entity.type
      local unit_number = entity.unit_number
      local belt_neighbours = entity.belt_neighbours
      -- MARKING
      local sprite = 0
      local sprite_type
      if entity_type == 'splitter' then
        sprite_type = 'splitter'
        -- figure out which belts are on which sides
        local neighbours = get_neighbour_sides(entity_direction, entity.position, belt_neighbours)
        sprite = neighbours.outputs.left and bor(sprite, lshift(1, 0)) or sprite
        sprite = neighbours.outputs.right and bor(sprite, lshift(1, 2)) or sprite
        sprite = neighbours.inputs.right and bor(sprite, lshift(1, 4)) or sprite
        sprite = neighbours.inputs.left and bor(sprite, lshift(1, 6)) or sprite
      else
        sprite_type = 'belt'
        for _,neighbour in ipairs(belt_neighbours.inputs) do
          if t.direction == 'input' or objects[neighbour.unit_number] then
            sprite = bor(sprite, lshift(1, op_dir((neighbour.direction - entity_direction) % 8)))
          end
        end
        if #belt_neighbours.outputs > 0 then
          sprite = bor(sprite, lshift(1, 0))
        end
      end
      local propegate = true
      if objects[unit_number] then
        propegate = false
        destroy(objects[unit_number])
      end
      objects[unit_number] = draw_sprite{
        sprite = 'rbt_route_'..sprite_type..'_'..bitwise_marker_entry[sprite],
        orientation = entity_direction / 8,
        tint = {r=1, g=1, b=0},
        target = entity,
        surface = 1,
        players = {pi}
      }
      -- ITERATION
      if propegate then
        -- set up for next iteration
        local belt_neighbours = belt_neighbours[t.direction..'s']
        for i1=1,#belt_neighbours do
          local belt = belt_neighbours[1]
          if belt.type ~= 'loader' and belt.type ~= 'loader-1x1' then
            new_entities[#new_entities+1] = {entity=belt_neighbours[i1], direction=t.direction}
          end
        end
        if entity.type == 'underground-belt' then
          local neighbour = entity.neighbours
          if neighbour and neighbour.belt_to_ground_type == t.direction then -- underground belt
            new_entities[#new_entities+1] = {entity=neighbour, direction=t.direction}
          end
        end
      end
    end
    if #new_entities == 0 then
      event.deregister(defines.events.on_tick, iterate_batch, {name='belt_iterator_tick', player_index=pi})
    end
    data.entities = new_entities
  end
end

-- --------------------------------------------------
-- EVENT HANDLERS

event.on_player_used_capsule(function(e)
  local item = e.item
  if item and item.valid and item.name == 'rbt-route-visualisation' then
    local data = global.belt_iterator
    if game.tick - (data.last_thrown_tick or 0) > 10 then
      local player = game.get_player(e.player_index)
      local selected = player.selected
      if selected and selected.valid and valid_types[selected.type] then
        if data[e.player_index] then
          -- destroy objects
          destroy_objects(data[e.player_index].objects)
        end
        -- get initial entities
        local entities = {}
        for _,entity in ipairs(player.selected.belt_neighbours.inputs) do
          entities[#entities+1] = {entity=entity, direction='input'}
        end
        entities[#entities+1] = {entity=player.selected, direction='output'}
        data[e.player_index] = {
          entities = entities,
          objects = {}
        }
        event.on_tick(iterate_batch, {name='belt_iterator_tick', player_index=e.player_index, skip_validation=true})
      end
    end
    data.last_thrown_tick = game.tick
  end
end)