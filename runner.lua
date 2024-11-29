-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- runner is a seperate application spawn by gui/cli in a dedicated process.
-- runner runs user tests. Once done, runner exits.
-- runner is needed because running tests from inside GUI will block the game
-- loop or will have a potential side effects (like drawing in the window)

-- runner send messages with events to communicate with the parent process.

include "api.lua"
include "throttler.lua"

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

local tests <const> = {}                            -- {id=1,name=..}

local publish_throttler <const> = new_throttler(50) -- max 50 messages per frame

-- key is a file:linedefined, value is always true:
local helpers <const> = {}

local function publish(msg)
	publish_throttler:throttle()
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
			-- file locator is file path with line no, eg. "/workdir/file.lua:10: "
			local file_locator_pattern = escaped_work_dir .. "[^ ]+:%d+: "
			local msg = err

			local file = string.match(err, file_locator_pattern)
			if file then
				msg = err:sub(#file + 1, #err)
				file = file:sub(1, #file - 2) -- drop ": "
			end
			err = {
				__traceback = { file },
				msg = msg,
			}
		end

		local function prepare_to_send(value)
			if value == nil then
				return nil
			end

			if type(value) == "number" then
				-- picotron is not able to send small numbers, like 0.000001
				return tostring(value)
			end

			if pod(value) == nil then
				if type(value) == "table" then
					-- picotron crashes on cyclic tables
					return "[not serializable - cyclic table]"
				end
				return "[not serializable]"
			end

			-- send the original value, Picotron will handle the serialization:
			return value
		end

		-- Ensure all values can be sent to different process:
		for key, value in pairs(err) do
			err[key] = prepare_to_send(value)
		end

		set_error_on_parents(parent, "nested test failed")
	end

	if err == nil then
		err = current_test.error
	end

	table.remove(tests, #tests)

	publish { event = "test_finished", test = current_test, error = err }
end

-- test_helper marks the calling function as a test helper function.
-- When printing file and line information in GUI, that function will be
-- skipped.
function test_helper()
	local info = debug.getinfo(2, "Sl")
	local info_string = string.format("%s:%d", info.short_src, info.linedefined)
	helpers[info_string] = true
end

---Generates stack traceback (skipping helpers)
---@return table
local function traceback()
	local trace = {}

	for level = 3, math.huge do
		local info = debug.getinfo(level, "Sl")
		if info == nil then break end
		local info_string = string.format("%s:%d", info.short_src, info.linedefined)
		if not helpers[info_string] then
			table.insert(trace, string.format("%s:%d", info.short_src, info.currentline))
		end
	end

	return trace
end

---Generates test error which stops current test execution and shows error to
---the user. In the GUI, the error will be presented together with a file name
---and line number where the `test_fail` function was executed. If you run
---`test_fail` from your own assert function, and want to see a place where this
---assert function was executed instead, please run the test_helper() function
---in the beginning of your assert function:
---```
---   function custom_assert(....)
---      test_helper() -- mark custom_assert function as test helper
---      if .... then
---         test_fail("message")
---      end
---   end
---```
---@param err string|table Error message as a string or a table. All table fields will be presented in the GUI. Table could contain special `msg` field which will always be presented first.
function test_fail(err)
	if type(err) != "table" then
		err = { msg = tostring(err) }
	end

	err.__traceback = traceback()

	error(err)
end

local originalPrint <const> = print

-- override picotron print, so all text is sent to the parent process
function print(text, x, y, color)
	if x == nil and y == nil and color == nil then
		publish { event = "print", test = tests[#tests], text = tostring(text) }
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
