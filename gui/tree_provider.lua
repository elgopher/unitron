-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

--- returns a new instance of data structure holding tree of nodes. This object
--- is used by tree component. The code was extracted from the tree component
--- because the component was to complex (and will be even more complex
--- when tree will have node collapsing and hiding functionality).
function new_tree_provider()
   local p = {}

   local nodes_by_line <const> = {}
   local nodes_by_id <const> = {}

   function p:nodes_len()
      return #nodes_by_line
   end

   function p:get_node(line_no)
      return nodes_by_line[line_no]
   end

   function p:get_line_no(id)
      for line_no, node in ipairs(nodes_by_line) do
         if node.id == id then
            return line_no
         end
      end

      return nil
   end

   function p:append_node(parent_id, id, text)
      local node = { text = text, depth = 0, id = id, has_children = false }
      if parent_id != nil then
         local parent = nodes_by_id[parent_id]
         parent.has_children = true
         node.depth = parent.depth + 1
      end
      nodes_by_id[node.id] = node
      table.insert(nodes_by_line, node)
   end

   function p:update_node_text(id, new_text)
      nodes_by_id[id].text = new_text
   end

   return p
end
