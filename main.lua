-- (c) 2024 Jacek Olszak
-- This code is licensed under CC BY-NC-SA 4.0 License (see LICENSE for details)

if #env().argv == 0 then
	include "gui.lua"
else 
	include "cli.lua"
end