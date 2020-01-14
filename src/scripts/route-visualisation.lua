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

-- --------------------------------------------------
-- UTILITIES

local function destroy_objects(t)
  for i=1,#t do
    destroy(t[i])
  end
end

local valid_types = {
  ['transport-belt'] = true,
  ['underground-belt'] = true,
  ['splitter'] = true
}

-- --------------------------------------------------
-- TRANSPORT BELT ITERATOR

local function iterate_batch(e)
  for pi,data in ipairs(global.belt_iterator) do
    local entities = data.entities
    local new_entities = {}
    for i=1,#entities do
      local t = entities[i]
      local entity = t.entity
      -- mark entity
      data.objects[#data.objects+1] = draw_sprite{
        sprite = 'rbt_route_belt_1',
        tint = {r=1, g=1, b=0},
        target = entity,
        surface = 1,
        players = {pi}
      }
      -- set up for next iteration
      local belt_neighbours = entity.belt_neighbours[t.direction]
      for i1=1,#belt_neighbours do
        local belt = belt_neighbours[1]
        if belt.type ~= 'loader' and belt.type ~= 'loader-1x1' then
          new_entities[#new_entities+1] = {entity=belt_neighbours[i1], direction=t.direction}
        end
      end
      if entity.type == 'underground-belt' then
        local neighbour = entity.neighbours
        if neighbour and neighbour.belt_to_ground_type == t.direction:gsub('s$', '') then -- underground belt
          new_entities[#new_entities+1] = {entity=neighbour, direction=t.direction}
        end
      end
      data.entities = new_entities
    end
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

        data[e.player_index] = {
          entities = {{entity=player.selected, direction='outputs'}},
          objects = {}
        }
        event.on_tick(iterate_batch, {name='belt_iterator_tick', player_index=e.player_index, skip_validation=true})
      end
    end
    data.last_thrown_tick = game.tick
  end
end)