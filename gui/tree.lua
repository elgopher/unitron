--[[pod_format="raw",created="2024-11-09 17:24:35",modified="2024-11-09 17:24:35",revision=0]]
-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

function attach_tree(parent_el, el)
	local bg_color <const> = 7
	local fg_color <const> = 13
	local highlight_bg_color <const> = 1
	local highlight_fg_color <const> = 7

	local node_height <const> = 10

	local nodes_by_id <const> = {}

	local selected_child

	el = parent_el:attach(el)

	local root_node = el:attach(
		{ width = el.width, height = node_height, x = 0, y = 0 }
	)
	root_node.indent = ""
	el:attach_scrollbars { autohide = true }

	function el:add_child(id, text, parent_id)
		local parent
		if parent_id == nil then
			parent = root_node
		else
			parent = nodes_by_id[parent_id]
		end


		local child = parent:attach(
			{
				width = parent.width,
				height = node_height,
				x = 0,
				y = parent.height
			}
		)
		child.text = text
		child.indent = parent.indent .. "  "
		if parent_id == nil then
			child.indent = "" -- root element should not have an indent
		end
		function child:draw(msg)
			if child == selected_child then
				pal(bg_color, highlight_bg_color);
				pal(fg_color, highlight_fg_color)
			end
			local prefix = "[-] "
			if #child.child == 0 then
				prefix = "    "
			end
			rectfill(0, 0, self.width, node_height, bg_color)
			print(child.indent .. prefix .. self.text, 0, 1, fg_color)
			pal()
		end

		function child:click()
			selected_child = child
			el:select { id = id }
			return true
		end

		local function add_height(parent, h)
			parent.height += h
			if parent._parent != nil then
				add_height(parent._parent, h)
			end
		end

		add_height(parent, node_height)

		-- use _parent beause parent is already used by Picotron:
		child._parent = parent
		nodes_by_id[id] = child
		child.cursor = "pointer"
	end

	function el:draw()
		rectfill(0, 0, el.width, el.height, bg_color)
	end

	function el:update_child_text(id, text)
		nodes_by_id[id].text = text
	end

	function el:reset()
		for _, child in ipairs(root_node.child) do
			child:detach()
		end
		root_node.y = 0
		root_node.height = node_height
		root_node.height = 0
	end

	local function child_y_relative_to_root_node(child)
		local y = child.y
		while child.parent != root_node do
			y += child.parent.y
			child = child.parent
		end
		return y
	end

	local function scroll_to_child(child)
		local scroll_root_node =
			 -child_y_relative_to_root_node(child) + (el.height / 2)
		if scroll_root_node > 0 then
			scroll_root_node = 0
		end
		local max_scroll = -root_node.height + el.height
		if scroll_root_node <= max_scroll then
			scroll_root_node = max_scroll
		end

		root_node.y = scroll_root_node
	end

	function el:select_child(id)
		selected_child = nodes_by_id[id]
		scroll_to_child(selected_child)
	end

	return el
end
