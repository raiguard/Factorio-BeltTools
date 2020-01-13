-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BELT TOOLS CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__.debugadapter')

-- dependencies
local event = require('lualib.event')

-- modules
require('scripts.belt-brush')
require('scripts.route-visualisation')

-- locals


-- -----------------------------------------------------------------------------
-- UTILITIES

local function setup_player(player)
  global.players[player.index] = {
    belt_brush = {
      objects = {},
      queue={}
    }
  }
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  global = util.merge{
    global,
    {
      belt_brush = {},
      players = {},
      settings = {
        capsule_end_wait = 3
      }
    }
  }
  for i,p in pairs(game.players) do
    setup_player(p)
  end
end)

event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index))
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- DEBUGGING
if __DebugAdapter then
  event.register('DEBUG-INSPECT-GLOBAL', function(e)
    local breakpoint -- put breakpoint here to inspect global at any time
  end)
end