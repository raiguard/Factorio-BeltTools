-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BELT TOOLS CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')

-- DEBUGGING
if __DebugAdapter then
  event.register('DEBUG-INSPECT-GLOBAL', function(e)
    local breakpoint -- put breakpoint here to inspect global at any time
  end)
end