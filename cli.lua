-- (c) 2024 Jacek Olszak
-- This code is licensed under CC BY-NC-SA 4.0 License (see LICENSE for details)

local work_dir = env().path
local test_file = env().argv[1]

print("Running " .. test_file .. "...")

local executed = 0
local failed = 0

on_event("test_started", function(e)
	executed += 1
end)

on_event("test_finished", function(e)
	if e.error != nil then
		failed += 1
	end
end)

on_event("print", function(e)
	printh("test " .. e.test.id .. ": " .. e.text) -- print to stdout, because Picotron's terminal has limited size. 
end)

on_event("done", function(e)
	if failed > 0 then
		print(string.format("\f8Failed tests: %d/%d", failed, executed))
		exit(1)
	elseif executed > 0 then
		print(string.format("\fbAll %d tests successful", executed))
		exit(0)
	else
		print(string.format("\f3No tests found"))
		exit(0)
	end
end)


runner_pid = create_process("runner.lua",
	{ argv = { test_file }, path = work_dir, window_attribs = { autoclose = true } })


function _update() -- run in the background
end

