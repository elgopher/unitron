-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- lights is a gui component showing lights of different color :)

---@param el {x:number,y:number,width:number,height:number,select:function}
function attach_lights(parent, el)
	local lights <const> = {}
	local lights_max = 0
	local size <const> = 2 -- light size in pixels

	el = parent:attach(el)

	function el:set_light(no, color)
		lights[no] = color
		lights_max = max(lights_max, no)
	end

	local function light_at_cursor_pointer(msg)
		if msg.mx == nil and msg.my == nil then
			return
		end
		local cell = ceil((msg.mx + 1) / (size * 2))
		local row = ceil(msg.my / (size * 2)) - 1
		local number_of_cells_in_a_row = el.width / (size * 2)
		local light = row * number_of_cells_in_a_row + cell
		if light > 0 and light <= lights_max then
			return light
		end
		return nil
	end

	function el:update(msg)
		if light_at_cursor_pointer(msg) != nil then
			el.cursor = "pointer"
		else
			el.cursor = ""
		end
	end

	function el:click(msg)
		local light = light_at_cursor_pointer(msg)
		if light != nil then
			el.select(light)
		end
	end

	function el:draw()
		rectfill(0, 0, el.width, el.height, 0)
		local x, y = 0, 0

		for i = 1, lights_max do
			local light = lights[i]
			if light == nil then
				light = 0
			end

			rectfill(x, y, x + size, y + size, light)

			if x >= el.width then
				x = 0
				y += size * 2
				if y >= el.height then
					return
				end
			else
				x += size * 2
			end
		end
	end

	return el
end
