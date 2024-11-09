-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

function attach_textarea(gui, el)
	local line_height = 10

	el.draw = function() end -- draw is needed for clipping
	local container = gui:attach(el)
	local text_area = container:attach(
		{ x = 0, y = 0, width = el.width, height = 0 }
	)
	container:attach_scrollbars { autohide = true }

	local lines = {}

	local function text_at_mouse_position(msg)
		return lines[ceil(msg.my / line_height)]
	end

	local function is_link(text)
		return el.is_link != nil and el:is_link(text)
	end

	function text_area:update(msg)
		if msg.my == nil then return end -- outside the window
		local cursor = ""
		local text = text_at_mouse_position(msg)
		if is_link(text) then
			cursor = "pointer"
		end
		text_area.cursor = cursor
	end

	function text_area:click(msg)
		local text = text_at_mouse_position(msg)
		if is_link(text) and el.link_click != nil then
			el:link_click(text)
		end
	end

	function text_area:draw()
		local y = 0
		for _, line in ipairs(lines) do
			print(line, 0, y, 7)
			y += line_height
		end
	end

	function text_area:mousewheel(e)
		self.y += e.wheel_y * 32
	end

	function container:set_lines(lines_to_draw)
		text_area.y = 0
		lines = lines_to_draw
		text_area.height = line_height * #lines
	end

	return container
end
