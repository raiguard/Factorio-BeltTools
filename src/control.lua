-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BELT TOOLS CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')

-- dependencies
local event = require('lualib.event')

-- modules
require('scripts.belt-brush')

-- locals


-- -----------------------------------------------------------------------------
-- UTILITIES

local function setup_player(player)
  global.players[player.index] = {
    belt_brush = {}
  }
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  global = {
    belt_brush = {},
    conditional_event_registry = {},
    players = {},
    settings = {
      capsule_end_wait = 3
    }
  }
  for i,p in pairs(game.players) do
    setup_player(p)
  end
end)

event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index))
end)

-- DEBUGGING
if __DebugAdapter then
  event.register('DEBUG-INSPECT-GLOBAL', function(e)
    local breakpoint -- put breakpoint here to inspect global at any time
  end)
end