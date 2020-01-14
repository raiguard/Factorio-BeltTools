-- DEBUGGING TOOL
if mods['debugadapter'] then
  data:extend{
    {
    type = 'custom-input',
    name = 'DEBUG-INSPECT-GLOBAL',
    key_sequence = 'CONTROL + SHIFT + ENTER'
    }
  }
end

local empty_sound = {filename='__RaiBeltTools__/sound/empty.ogg'}
local function capsule(name, icon, cooldown)
  return {
    type = 'capsule',
    name = name,
    icons = {
      {icon='__RaiBeltTools__/graphics/black.png', icon_size=1, scale=64},
      {icon=icon, icon_size=32, mipmap_count=2}
    },
    subgroup = 'capsule',
    order = 'zz',
    flags = {'hidden', 'only-in-cursor', 'not-stackable'},
    radius_color = {a=0},
    stack_size = 1,
    capsule_action = {
      type = 'throw',
      uses_stack = false,
      attack_parameters = {
        type = 'projectile',
        ammo_category = 'capsule',
        cooldown = cooldown,
        range = 1000,
        ammo_type = {
          category = 'capsule',
          target_type = 'position',
          action = {
            type = 'direct',
            action_delivery = {
              type = 'instant',
              target_effects = {
                type = 'damage',
                damage = {type='physical', amount=0}
              }
            }
          }
        }
      }
    }
  }
end

-- local function dummy_entity(name, icon, picture)
--   return
--   {
--     type = 'simple-entity',
--     name = 'belt-brush-dummy',
--     picture = picture,
--     build_sound = empty_sound,
--     mined_sound = empty_sound,
--     flags = {'hidden'}
--   },
--   {
--     type = 'item',
--     name = name,
--     icons = {
--       {icon='__BeltTools__/data/graphics/black.png', icon_size=1, scale=64},
--       {icon=icon, icon_size=32, mipmap_count=2}
--     },
--     stack_size = 1,
--     flags = {'hidden', 'not-stackable'},
--     place_result = name
--   }
-- end

data:extend{
  capsule('rbt-belt-brush', '__base__/graphics/icons/fast-transport-belt.png', 1),
  capsule('rbt-route-visualisation', '__base__/graphics/icons/express-transport-belt.png', 10)
}

-- ROUTE VISUALISATION SPRITES
-- forward, left, right, down

-- for i,s in ipairs{'', 'F', 'R', 'FR', 'B', 'FB', 'RB', 'FRB', 'L', 'FL', 'RL', 'FRL', 'BL', 'FBL', 'RBL', 'FRBL'} do
for i=1,16 do
  data:extend{
    {
      type = 'sprite',
      name = 'rbt_route_belt_'..i,
      filename = '__RaiBeltTools__/graphics/visualisation/belts.png',
      x = (32*(i-1)),
      size = 32,
      flags = {'terrain'}
    }
  }
end