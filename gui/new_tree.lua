function attach_new_tree(parent_el, el)
   local bg_color <const> = 7
   local fg_color <const> = 13
   local highlight_bg_color <const> = 1
   local highlight_fg_color <const> = 7

   local node_height <const> = 10

   local space <const> = " "

   -- index of array is the line number in the tree. value is a list of nodes
   local nodes_by_line_array = {}
   local nodes_by_id = {}

   local function insert_new_node(line_number, node)
      table.insert(nodes_by_line_array, line_number, { node })
      -- update line number in consecutive nodes
      -- (not a performance problem if nodes are added in the end)
      for i = line_number + 1, #nodes_by_line_array do
         local nodes = nodes_by_line_array[i]
         for _, n in ipairs(nodes) do
            n.line += 1
         end
      end
   end

   el = parent_el:attach(el)

   local pane = el:attach(
      { width = el.width, height = 0, x = 0, y = 0 }
   )
   el:attach_scrollbars { autohide = true }

   function el:add_node(id, text, parent_id)
      if nodes_by_id[id] != nil then
         return -- node already added
      end

      local line = 1
      local indent = 0

      if parent_id != nil then
         local parent_node = nodes_by_id[parent_id]
         if parent_node == nil then
            return -- parent does not exist
         end

         line = parent_node.line + parent_node.children_len + 1
         indent = parent_node.indent + 1

         parent_node.children_len += 1
      end

      local node = {
         id = id,
         text = text,
         indent = indent,
         children_len = 0,
         line = line,
         visible = true
      }
      insert_new_node(line, node)
      nodes_by_id[id] = node

      pane.height += node_height
   end

   function el:update_node_text(id, text)
      local node = nodes_by_id[id]
      if node == nil then
         return
      end
      node.text = text
   end

   function el:reset()
      nodes_by_line_array = {}
      nodes_by_id = {}
   end

   function el:select_node(id)
   end

   function el:draw()
      rectfill(0, 0, el.width, el.height, bg_color)

      -- draw only visible part of the tree
      local first_line = max(math.floor(-pane.y / node_height), 1)
      local last_line = math.floor(first_line + el.height / node_height)

      for i = first_line, last_line do
         local nodes = nodes_by_line_array[i]
         if nodes == nil then
            return
         end

         for _, node in ipairs(nodes) do
            if node.visible then
               print(space:rep(node.indent) .. node.text)
               break
            end
         end
      end
   end

   return el
end
