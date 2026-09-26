-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

--- returns a new instance of data structure holding tree of nodes. This object
--- is used by tree component. The code was extracted from the tree component
--- because the component was to complex (and will be even more complex
--- when tree will have node collapsing and hiding functionality).
function new_tree_provider()
   local p                                     = {}

   local nodes_by_line                         = {}
   local nodes_by_id <const>                   = {}
   local collapsed_children_by_node_id <const> = {}

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

   local function collapse(line_no, node)
      local first_line_no = line_no + 1
      local last_line_no = line_no
      for i = first_line_no, #nodes_by_line do
         local potential_child = nodes_by_line[i]
         if potential_child.depth <= node.depth then
            break
         end
         last_line_no = i
      end

      collapsed_children_by_node_id[node.id] = {}
      nodes_by_line = move_table(
         nodes_by_line, first_line_no, last_line_no,
         collapsed_children_by_node_id[node.id], 1)
   end

   local function expand(line_no, node)
      local src = collapsed_children_by_node_id[node.id]
      insert_table(src, line_no + 1, nodes_by_line)

      collapsed_children_by_node_id[node.id] = nil
   end

   function p:toggle_line(line_no)
      local node <const> = nodes_by_line[line_no]
      if node.collapsed then
         expand(line_no, node)
      else
         collapse(line_no, node)
      end
      node.collapsed = not node.collapsed
   end

   -- append node to the end of the tree
   function p:append_node(parent_id, id, text)
      local node = {
         text = text,
         depth = 0,
         parent_id = parent_id,
         id = id,
         has_children = false,
         collapsed = false
      }
      local parent = nil
      if parent_id != nil then
         parent = nodes_by_id[parent_id]
         parent.has_children = true
         node.depth = parent.depth + 1
      end
      nodes_by_id[node.id] = node

      local function find_collpased_node(n)
         if n == nil then
            return nil
         end
         if n.collapsed then
            return n
         end
         return find_collpased_node(nodes_by_id[n.parent_id])
      end

      local collapsed_parent = find_collpased_node(parent)

      if collapsed_parent == nil then
         table.insert(nodes_by_line, node)
      else
         local children = collapsed_children_by_node_id[collapsed_parent.id]
         table.insert(children, node)
      end
   end

   function p:update_node_text(id, new_text)
      nodes_by_id[id].text = new_text
   end

   return p
end
