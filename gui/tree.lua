-- This code is licensed under MIT license (see LICENSE for details)

---@param el {x:number,y:number,width:number,height:number,select:function}
function attach_tree(parent_el, el)
	include "gui/tree_provider.lua"

	local provider <const> = new_tree_provider()

	local selected_line = nil

	local tree = attach_text_output(parent_el, {
		x = el.x,
		y = el.y,
		width = el.width,
		height = el.height,
		bg_color = 7,
		get_line = function(line_no)
			local node = provider:get_node(line_no)
			local whitespace = " "

			local fg_color = 13
			local bg_color = 7
			if selected_line != nil and selected_line == line_no then
				fg_color = 7
				bg_color = 1
			end

			local prefix = whitespace:rep(node.depth * 2)
			if node.has_children then
				prefix = prefix .. "[-] "
			else
				prefix = prefix .. "    "
			end

			local text = prefix .. node.text

			return {
				text = text,
				bg_color = bg_color,
				fg_color = fg_color,
			}
		end,
		is_link = function(line_no)
			return true
		end,
		link_click = function(line_no)
			selected_line = line_no
			el.select(provider:get_node(line_no).id)
		end,
		lines_len = function()
			return provider:nodes_len()
		end
	})

	function tree:add_child(id, text, parent_id)
		provider:append_node(parent_id, id, text)
	end

	function tree:update_child_text(id, text)
		provider:update_node_text(id, text)
	end

	function tree:select_child(id)
		local line = provider:get_line_no(id)
		selected_line = line
		tree:scroll_to_line(line)
	end

	return tree
end
