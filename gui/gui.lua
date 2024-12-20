-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- this file contains code controlling GUI of test runner

include "gui/text_output.lua"
include "gui/lights.lua"
include "gui/test_summary.lua"
include "gui/test_toolbar.lua"
include "gui/printed_lines.lua"
include "gui/tree.lua"

local width <const> = 280
local height <const> = 200

local gui, test_tree, lights, test_summary, runner_pid, selected_test_id

local printed_lines <const> = new_printed_lines()

local function print_line(test, message)
	printed_lines:print(test.id, message)

	local prefix = "  "
	local parent = test.parent
	while parent != nil do
		printed_lines:print(parent.id, prefix .. message)
		parent = parent.parent
		prefix = prefix .. "  "
	end
end

local function stop_test()
	if runner_pid != nil then
		send_message(
			2,
			{ event = "kill_process", proc_id = runner_pid, exit_code = 1 }
		)
		runner_pid = nil
	end
end

-- item has filename and fullpath attributes
local function start_test(item)
	if runner_pid != nil then
		return
	end

	gui = create_gui()

	cls(7)

	local test_file = item.filename
	local work_dir = item.fullpath:sub(1, #item.fullpath - #item.filename)

	window { title = item.fullpath }

	local function find_lua_file_in_text(text)
		return text:match("[^ ]*%.lua:%d+")
	end

	local text_output = attach_text_output(
		gui,
		{
			x = 0,
			y = 97,
			width = width,
			height = 103,
			bg_color = 0,
			lines_len = function()
				if selected_test_id == nil then return 0 end
				return printed_lines:lines_len(selected_test_id)
			end,
			get_line = function(line_no)
				return {
					text = printed_lines:line(selected_test_id, line_no),
					bg_color = 0,
					fg_color = 7,
				}
			end,
			is_link = function(line_no)
				local text = printed_lines:line(selected_test_id, line_no)
				return find_lua_file_in_text(text) != nil
			end,
			link_click = function(line_no, msg)
				local text = printed_lines:line(selected_test_id, line_no)

				local file = find_lua_file_in_text(text)
				if file != nil then
					file = file:gsub(":", "#")
					-- TODO if file is already open in text editor then this
					-- command does not go to the specific line number.
					-- Please note though, that in case of an unhandled error,
					-- Picotron also opens the text editor in the same way.
					create_process("/system/util/open.lua", { argv = { file } })
				end
			end
		}
	)

	test_summary = attach_test_summary(
		gui,
		{ x = 8, y = 102, width = 150, height = 10 }
	)

	local function select_test(test_id)
		selected_test_id = test_id

		if test_id != nil then
			text_output:scroll_to_line(1)

			test_summary:set_visible(false)
			lights:set_visible(false)
		else
			test_summary:set_visible(true)
			lights:set_visible(true)
		end
	end

	lights = attach_lights(
		gui,
		{
			x = 8,
			y = 115,
			width = 264,
			height = 79,
			select = function(selected_test)
				select_test(selected_test)
				test_tree:select_child(selected_test)
			end
		}
	)

	test_tree = attach_tree(
		gui,
		{
			x = 0,
			y = 16,
			width = width,
			height = 80,
			select = select_test
		}
	)

	attach_toolbar(
		gui,
		{
			x = 0,
			y = 0,
			width = width,
			height = 16,
			start_test = function()
				start_test(item)
			end,
			stop_test = stop_test,
			is_running = function()
				return runner_pid != nil
			end
		}
	)

	selected_test_id = nil
	printed_lines:reset()

	local function run_tests_in_seperate_process()
		runner_pid = create_process(
			"runner.lua",
			{
				argv = { test_file },
				path = work_dir,
				window_attribs = { autoclose = true }
			}
		)
	end

	run_tests_in_seperate_process()
end

-- test_started event is published by the runner process for each started test
on_event("test_started", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	lights:set_light(e.test.id, 5)

	local parent_id
	if e.test.parent != nil then parent_id = e.test.parent.id end
	test_tree:add_child(e.test.id, e.test.name .. " (running)", parent_id)

	print_line(e.test, "\f6> \f7" .. e.test.name)
	sfx(1)
end)

---@param v any
local function format_value(v)
	local s = pod(v)
	-- no need to escape ] because meta data is not serialized:
	return s:gsub("\\093", "]") -- TODO unescape all special characters
end

-- test_finished event is published by the runner process for each started test
on_event("test_finished", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	local err = e.error

	if err == nil then
		lights:set_light(e.test.id, 26)
		test_summary:inc_succeeded()
	else
		lights:set_light(e.test.id, 8)
		test_summary:inc_failed()
	end

	local color
	local message

	if err == nil then
		message = "\fbTest successful"
		color = "\fb"
	else
		if err.__traceback != nil and #err.__traceback > 0 then
			local file = err.__traceback[1]
			print_line(e.test, "\f8Error \f7at " .. file)

			-- print additional message provided by user
			if err.msg != nil then
				print_line(e.test, err.msg)
			end

			-- always print expected first
			if err.expect != nil then
				print_line(e.test, "\f5 expect=\f6" .. format_value(err.expect))
			end
			-- then actual
			if err.actual != nil then
				print_line(e.test, "\f5 actual=\f6" .. format_value(err.actual))
			end

			-- TODO sort alphabetically?
			for k, v in pairs(err) do
				if k != "msg" and k != "expect" and k != "actual" and k != "__traceback" then
					print_line(e.test, "\f5 " .. k .. "=\f6" .. format_value(v))
				end
			end
		end

		message = "\f8Test failed"
		color = "\f8"
	end

	print_line(e.test, message)
	print_line(e.test, "")

	test_tree:update_child_text(e.test.id, color .. e.test.name)
	-- update text for all parents
end)

-- print event is published by the runner process for each print command
-- executed by test
on_event("print", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	printed_lines:print(e.test.id, e.text)
end)

-- done event is published by the runner process when all test have finished
on_event("done", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	runner_pid = nil
end)

function _init()
	window {
		width = width,
		height = height,
		userdata "[gfx]08087770000070700000777000000700777007777070070077700000000000000000[/gfx]",
		title = "unitron",
		resizeable = false
	}

	-- menuitem {
	-- 	id = "open_file",
	-- 	label = "\^:7f4141417f616500 Open File",
	-- 	shortcut = "CTRL-O", -- ctrl-s is handled by window manager
	-- 	action = function()
	-- 		create_process(
	--         "/system/apps/filenav.p64",
	--         {
	--              intention="save_file_as",
	--              window_attribs={workspace = "current", autoclose=true}
	--         }
	--        )
	-- 	end
	-- }

	local run_from_the_browser = env().parent_pid == 1
	if run_from_the_browser then
		start_test {
			filename = "subject_test.lua",
			fullpath = "examples/subject_test.lua",
		}
	else
		gui = create_gui()
		local label = gui:attach {
			x = 59, y = 75, width = 200, height = 20,
		}
		function label:draw()
			print("Please drag'n'drop test file here", 0, 0, 7)
		end

		local examples_btn = gui:attach_button {
			label = "don't have it? open examples",
			x = 65,
			y = 105
		}
		function examples_btn:click()
			local dir = env().corun_program or env().prog_name
			if dir == "/ram/cart/main.lua" then
				dir = "/ram/cart"
			end
			dir = dir .. "/examples"

			create_process(
				"/system/apps/filenav.p64",
				{
					argv = { dir },
				}
			)
		end

		on_event("drop_items", function(msg)
			stop_test()
			local item = msg.items[1]
			start_test(item)
		end)
	end
end

function _update()
	if gui != nil then
		gui:update_all()
	end
end

function _draw()
	if gui != nil then
		cls()
		gui:draw_all()
		-- debug fps and memory usage:
		-- local debug_msg = string.format("%.2f", stat(1)) ..
		-- 	 " - " .. stat(7) .. "FPS, " .. ceil(stat(0) / 1024 / 1024) .. "MB"
		-- print(debug_msg, 150, 5, 1)
	end
end
