-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- runner is a seperate application spawn by gui/cli in a dedicated process.
-- runner runs user tests. Once done, runner exits.
-- runner is needed because running tests from inside GUI will block the game
-- loop or will have a potential side effects (like drawing in the window)

-- runner send messages with events to communicate with the parent process.

include "api.lua"

local work_dir            = env().path

local parent_pid <const>  = env().parent_pid
local test_file <const>   = env().argv[1]
local dir_in_file <const> = string.match(test_file, ".+/")
if dir_in_file then
	work_dir = dir_in_file
end

-- TODO Do not pass run_tests function to test script in _ENV
-- TODO all assert functions should not be global, but passed to script only

local id_sequence = 0

local tests <const> = {} -- {id=1,name=..}

local function publish(msg)
	send_message(parent_pid, msg)
end

local function set_error_on_parents(parent, err)
	while parent != nil do
		parent.error = err
		parent = parent.parent
	end
end

---Starts a test with given name and code
---@param name any Name of test
---@param test function Test code
function test(name, test)
	local parent
	if #tests > 0 then
		parent = tests[#tests]
	end

	id_sequence += 1
	local current_test = {
		id = id_sequence,
		name = tostring(name),
		parent = parent,
	}
	table.insert(tests, current_test)

	publish { event = "test_started", test = current_test }

	local success, err = pcall(test)
	if not success then
		if type(err) == "string" then
			local escaped_work_dir = work_dir:gsub("([%W])", "%%%1")
			local file = ""
			local msg = err
			if string.match(err, escaped_work_dir) then
				file = string.gsub(err, "(%d+):.*", "%1") -- drop message
				msg = string.gsub(err, file .. ": ", "")
			end
			err = {
				assert = "generic",
				original_error = err,
				file = file,
				msg = msg,
			}
		end

		set_error_on_parents(parent, "nested test failed")
	end

	if err == nil then
		err = current_test.error
	end

	table.remove(tests, #tests)

	publish { event = "test_finished", test = current_test, error = err }
end

local originalPrint <const> = print

-- override picotron print, so all text is sent to the parent process
function print(text, x, y, color)
	if x == nil and y == nil and color == nil then
		publish { event = "print", test = tests[#tests], text = text }
	end

	originalPrint(text, x, y, color)
end

cd(work_dir)

test("root", function()
	local ok = include(test_file)
	if not ok then
		publish { event = "fatal_error", error = test_file .. " not found" }
		return
	end
end)

publish { event = "done", root_test_id = 1 }
