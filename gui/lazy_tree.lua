-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

function attach_lazy_tree(parent_el, el)
   local bg_color <const> = 7
   local fg_color <const> = 13
   local highlight_bg_color <const> = 1
   local highlight_fg_color <const> = 7

   local node_height <const> = 10

   local last_added = {}
   local visible_nodes_array = {}

   -- this function is very slow - run only as last resort
   local function count_children(node)
      if node.children == nil then
         return 0
      end
      if node.collapsed then
         return 0
      end

      local c = #node.children
      for _, child in ipairs(node.children) do
         c += count_children(child)
      end

      return c
   end

   local function find(node, id)
      if node == nil then
         return nil
      end
      if node.id == id then
         return node
      end
      if node.children == nil then
         return nil
      end
      for _, child in ipairs(node.children) do
         local f = find(child, id)
         if f != nil then
            return f
         end
      end

      return nil
   end

   local function find_node(id)
      if id == nil then
         return nil
      end
      if last_added.node.parent != nil and last_added.node.parent.id == id then
         return last_added.node.parent
      end
      if last_added.node.id == id then
         return last_added.node
      end
      -- TODO find node in all parents first

      -- brute force - find node iterating over all elements
      printh("brute force find")
      return find(visible_nodes_array[1], id)
   end

   local function find_next_node_position_for_parent(id)
      if id == nil then
         return nil
      end
      if last_added.node.parent != nil and last_added.node.parent.id == id then
         return last_added.position + 1
      end

      -- brute force - find node position in descending order
      for i = #visible_nodes_array, 1, -1 do
         local node = visible_nodes_array[i]
         if node.id == id then
            printh("running slow count_children")
            return i + count_children(node)
         end
      end

      return nil
   end

   el = parent_el:attach(el)

   local pane = el:attach(
      { width = el.width, height = 0, x = 0, y = 0 }
   )
   el:attach_scrollbars { autohide = true }

   function el:add_node(id, text, parent_id)
      local parent = find_node(parent_id)

      local node = {
         id = id,
         parent = parent,
         text = text,
         collapsed = false,
         -- TODO to much memory is consumed by this. Better calculate indent
         -- on the fly in draw method:
         indent = 0,
      }


      local position = 1
      if parent != nil then
         if parent.children == nil then
            parent.children = {}
         end

         node.indent = parent.indent + 1

         table.insert(parent.children, node)

         position = find_next_node_position_for_parent(parent_id)

         if position != nil then -- the parent is not hidden
            table.insert(visible_nodes_array, position, node)
         end
      else
         visible_nodes_array = { node }
      end

      pane.height += node_height
      last_added.node = node
      last_added.position = position
   end

   function el:update_node_text(id, text)
      local node = find_node(id)
      if node == nil then
         return
      end
      node.text = text
   end

   function el:reset()
      visible_nodes_array = {}
      last_added = {}
   end

   function el:select_node(id)
   end

   local function line_at_y(y)
      return math.floor(y / node_height) - 1
   end

   function el:draw()
      rectfill(0, 0, el.width, el.height, bg_color)
      local first_line = line_at_y(-pane.y)
      local last_line = math.floor(first_line + el.height / node_height)

      for i = first_line, last_line do
         local node = visible_nodes_array[i]
         if node == nil then
            return
         end

         cursor(node.indent * 12, (i - first_line) * node_height, 13)

         local prefix
         if node.children == nil then
            prefix = "    "
         elseif #node.children > 0 then
            prefix = "[-] "
         end
         print(prefix .. node.text)
      end
   end

   function pane:click(msg)
      local node = visible_nodes_array[line_at_y(msg.my)]
      if node == nil then
         return
      end
      el.select(node.id)
   end

   return el
end
