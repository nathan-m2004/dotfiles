#!/bin/bash
hyprctl repl "
local sp = hl.get_active_special_workspace()
if sp then
    local name = sp.name:gsub('^special:', '')
    hl.dispatch(hl.dsp.workspace.toggle_special(name))
end
"
