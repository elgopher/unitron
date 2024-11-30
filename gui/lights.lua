-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- lights is a gui component showing lights of different color :)

---@param el {x:number,y:number,width:number,height:number,select:function}
function attach_lights(parent, el)
	local lights <const> = {}
	local lights_max = 0
	local size <const> = 3 -- light size in pixels
	local margin <const> = 1

	el = parent:attach(el)
	el.visible = true -- Picotron's hidden field is broken

	---@param no integer Starting from 1
	function el:set_light(no, color)
		lights[no] = color
		lights_max = max(lights_max, no)
	end

	local function light_at_cursor_pointer(msg)
		if msg.mx == nil and msg.my == nil then
			return
		end
		local cell = flr(msg.mx / (size + margin))
		local row = flr(msg.my / (size + margin))
		local number_of_cells_in_a_row = flr(el.width / (size + margin))
		local light = row * number_of_cells_in_a_row + cell + 1 -- lights start at 1

		if light > 0 and light <= lights_max then
			return light
		end
		return nil
	end

	function el:update(msg)
		if not el.visible then
			return
		end

		if light_at_cursor_pointer(msg) != nil then
			el.cursor = "pointer"
		else
			el.cursor = ""
		end
	end

	function el:click(msg)
		if not el.visible then
			return
		end

		local light = light_at_cursor_pointer(msg)
		if light != nil then
			el.select(light)
		end
	end

	function el:draw()
		if not el.visible then
			return
		end

		rectfill(0, 0, el.width, el.height, 0)
		local x, y = 0, 0

		for i = 1, lights_max do
			local light = lights[i]
			if light == nil then
				light = 0
			end

			rectfill(x, y, x + size - 1, y + size - 1, light)

			if x + size + margin >= el.width then
				x = 0
				y += size + margin
				if y >= el.height then
					return
				end
			else
				x += size + margin
			end
		end
	end

	return el
end
