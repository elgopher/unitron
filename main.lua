-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

if #env().argv == 0 then
	include "gui/gui.lua"
else
	include "cli.lua"
end
