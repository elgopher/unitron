-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

---@param el {x:number, y:number, width:number, height:number, is_link:function, link_click:function, get_line:function, lines_len:function}
function attach_text_output(parent, el)
	local line_height <const> = 10

	local lines_len = 0

	el = parent:attach(el)
	local text_output <const> = el:attach(
		{ x = 0, y = 0, width = el.width, height = 0 }
	)
	el:attach_scrollbars { autohide = true }

	local function line_at_mouse_position(msg)
		return ceil(msg.my / line_height)
	end

	local function is_link(line_no)
		return line_no >= 1 and line_no <= lines_len
			 and el.is_link != nil and el.is_link(line_no)
	end

	function text_output:update(msg)
		lines_len = el.lines_len()
		if msg.my == nil then return end -- outside the window
		local cursor = ""
		local line = line_at_mouse_position(msg)
		if is_link(line) then
			cursor = "pointer"
		end
		text_output.cursor = cursor
	end

	function text_output:click(msg)
		local line = line_at_mouse_position(msg)
		if is_link(line) and el.link_click != nil then
			el.link_click(line)
		end
	end

	-- for performance reasons draw only visible lines
	function text_output:draw()
		local line_no = flr(-text_output.y / line_height)

		text_output.height = line_height * lines_len

		local last_line = line_no + ceil(el.height / line_height)
		last_line = min(last_line, lines_len - 1)

		for i = line_no, last_line do
			local line = el.get_line(i + 1)
			print(line, 0, i * line_height, 7)
		end
	end

	function text_output:mousewheel(e)
		self.y += e.wheel_y * 32
	end

	function el:scroll_to_the_top()
		text_output.y = 0
	end

	return el
end
