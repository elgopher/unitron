-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

---@param el {x:number, y:number, width:number, height:number, bg_color:integer, is_link:function, link_click:function, get_line:function, lines_len:function}
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

		text_output.height = line_height * lines_len

		-- If text_output has decreased, adjust the y position.
		if text_output.height - el.height < -text_output.y then
			text_output.y = min(-text_output.height + el.height, 0) -- test this
		end

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
			el.link_click(line, msg)
		end
	end

	-- for performance reasons draw only visible lines
	function text_output:draw()
		local line_no = flr(-text_output.y / line_height)

		local last_line = line_no + ceil(el.height / line_height)
		last_line = min(last_line, lines_len - 1)

		for i = line_no, last_line do
			local line = el.get_line(i + 1)
			rectfill(0, i * line_height,
				text_output.width, (i + 1) * line_height + 1,
				line.bg_color)
			print(line.text, 1, i * line_height + 1, line.fg_color)
		end
	end

	function el:scroll_to_line(line_no)
		text_output.y = -(line_height * (line_no - 1))
		if text_output.y == 0 then
			return
		end
		text_output.y += el.height / 2 - line_height
		if -text_output.y + el.height > text_output.height then
			text_output.y = -text_output.height + el.height
		end
		if text_output.y > 0 then
			text_output.y = 0
		end
	end

	function el:draw()
		-- draw background (needed when tree height is too low)
		rectfill(0, 0, el.width, el.height, el.bg_color)
	end

	return el
end
