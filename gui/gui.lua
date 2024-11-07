-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

local gui, test_tree

include "gui/tree.lua"
include "gui/textarea.lua"
include "gui/lights.lua"
include "gui/test_summary.lua"


local run_btn, stop_btn, toggle_btn
local test_tree
local lights
local test_summary

local runner_pid
local function stop_test()
	if runner_pid != nil then
		send_message(2, { event = "kill_process", proc_id = runner_pid, exit_code = 1 })
		runner_pid = nil
	end
end

local width = 280
local height = 200

local icon_color = 8
local enabled_color = 0
local disabled_color = 13
local toolbar_color = 6

local printed_lines = {
	by_test_id = {}
}
function printed_lines:print(test_id, text)
	if self.by_test_id[test_id] == nil then
		self.by_test_id[test_id] = {}
	end
	table.insert(self.by_test_id[test_id], text)
end

function printed_lines:lines(test_id)
	if self.by_test_id[test_id] == nil then
		return {}
	end

	return self.by_test_id[test_id]
end

function printed_lines:reset()
	self.by_test_id = {}
end

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

on_event("test_started", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	lights:set_light(e.test.id, 5)

	local parent_id
	if e.test.parent != nil then parent_id = e.test.parent.id end
	test_tree:add_child(e.test.id, e.test.name .. " (running)", parent_id)

	print_line(e.test, "\f5Running \f7" .. e.test.name)
	sfx(1)
end)

on_event("test_finished", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	if e.error == nil then
		lights:set_light(e.test.id, 26)
		test_summary:inc_succeded()
	else
		lights:set_light(e.test.id, 8)
		test_summary:inc_failed()
	end

	local color
	local message

	if e.error == nil then
		message = "\fbTest successful"
		color = "\fb"
	else
		if e.error.file != nil then
			print_line(e.test, "\f8Error \f7at " .. e.error.file)

			local err = e.error
			-- print additional message provided by user
			if err.msg != nil then
				print_line(e.test, err.msg)
			end

			if err.assert == "eq" then
				print_line(e.test, "args not equal:")
				print_line(e.test, "\f5 expect=\f6" .. err.expected)
				print_line(e.test, "\f5 actual=\f6" .. err.actual)
			elseif err.assert == "not_eq" then
				print_line(e.test, "args are equal:")
				print_line(e.test, "\f5 actual=\f6" .. err.actual)
			elseif err.assert == "same" then
				print_line(e.test, "args are not the same:")
				print_line(e.test, "\f5 expect=\f6" .. err.expected)
				print_line(e.test, "\f5 actual=\f6" .. err.actual)
			elseif err.assert == "not_same" then
				print_line(e.test, "args are the same:")
				print_line(e.test, "\f5 actual=\f6" .. err.actual)
			elseif err.assert == "close" then
				print_line(e.test, "args not close")
				print_line(e.test, "\f5 expect=\f6" .. err.expected)
				print_line(e.test, "\f5 actual=\f6" .. err.actual)
				print_line(e.test, "\f5 delta =\f6" .. err.delta)
			elseif err.assert == "not_close" then
				print_line(e.test, "args too close")
				print_line(e.test, "\f5 not_ex=\f6" .. err.not_expected)
				print_line(e.test, "\f5 actual=\f6" .. err.actual)
				print_line(e.test, "\f5 delta =\f6" .. err.delta)
			elseif err.assert == "not_nil" then
				print_line(e.test, "arg is nil")
			elseif err.assert == "nil" then
				print_line(e.test, err.actual .. " is not nil")
			elseif err.assert == "true" then
				print_line(e.test, "arg is false")
			elseif err.assert == "false" then
				print_line(e.test, "arg is true")
			end
		end

		message = "\f8Test failed"
		color = "\f8"
	end

	print_line(e.test, message)

	test_tree:update_child_text(e.test.id, color .. e.test.name)
	-- update text for all parents
end)

on_event("print", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	printed_lines:print(e.test.id, e.text)
end)

on_event("done", function(e)
	if e._from != runner_pid then
		-- discard events from old runners
		return
	end

	runner_pid = nil
	-- test_tree:select { id = e.root_test_id }
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
	-- 		create_process("/system/apps/filenav.p64", {intention="save_file_as", window_attribs={workspace = "current", autoclose=true}})
	-- 	end
	-- }

	-- item has filename and fullpath attributes
	local function start_test(item)
		gui = create_gui()

		cls(7)

		local test_file = item.filename
		local work_dir = item.fullpath:sub(1, #item.fullpath - #item.filename)

		window { title = item.fullpath }

		local function run_tests_in_seperate_process()
			if runner_pid != nil then
				return
			end
			printed_lines:reset()
			test_tree:reset()
			runner_pid = create_process("runner.lua",
				{ argv = { test_file }, path = work_dir, window_attribs = { autoclose = true } })
		end

		local text_area = attach_textarea(gui, { x = 0, y = 97, width = width, height = 103 })

		test_summary = attach_test_summary(gui, { x = 8, y = 102, width = 150, height = 10 })

		local function select_test(test_id)
			local lines = printed_lines:lines(test_id)
			text_area:set_lines(lines)

			lights:detach()
			test_summary:detach()
		end

		lights = attach_lights(gui, { x = 8, y = 115, width = 264, height = 78 })
		function lights:select(selected_test)
			select_test(selected_test)
			-- TODO should move test tree too
		end

		test_tree = attach_tree(gui, { x = 0, y = 16, width = width, height = 80 })
		function test_tree:select(e)
			select_test(e.id)
		end

		local toolbar = gui:attach { x = 0, y = 0, width = width, height = 16 }
		function toolbar:draw()
			rectfill(0, 0, self.width, self.height, toolbar_color)
		end

		run_btn = toolbar:attach_button { x = 6, y = 4, width = 10 }
		function run_btn:click()
			start_test(item)
		end

		function run_btn:update()
			if runner_pid != nil then
				self.cursor = nil
			else
				self.cursor = "pointer"
			end
		end

		function run_btn:draw()
			local col = disabled_color
			if runner_pid == nil then
				col = enabled_color
			end
			pal(icon_color, col)
			spr(0)
			pal()
		end

		stop_btn = toolbar:attach_button { x = 22, y = 4, width = 10 }
		function stop_btn:click()
			stop_test()
		end

		function stop_btn:update()
			if runner_pid == nil then
				self.cursor = nil
			else
				self.cursor = "pointer"
			end
		end

		function stop_btn:draw()
			local col = disabled_color
			if runner_pid != nil then
				col = enabled_color
			end
			pal(icon_color, col)
			spr(1)
			pal()
		end

		-- toggle_btn = toolbar:attach_button { x = 35, y = 4, width = 10 }
		-- function toggle_btn:draw()
		-- 	pal(icon_color, enabled_color)
		-- 	spr(2)
		-- 	pal()
		-- end

		run_tests_in_seperate_process()
	end

	local run_from_the_browser = env().parent_pid == 1
	if run_from_the_browser then
		start_test {
			filename = "subject_test.lua",
			fullpath = "examples/subject_test.lua",
		}
	else
		print("please drag'n'drop test file here")
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
	end
end
