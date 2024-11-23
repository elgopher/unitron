-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

include "tree_provider.lua"

test("new provider has 0 lines", function()
   local p = new_tree_provider()
   assert_eq(0, p:nodes_len())
end)

test("add root", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   assert_eq(1, p:nodes_len())
   assert_eq({ text = "root", depth = 0, id = 1, has_children = false }, p:get_node(1))
   assert_eq(1, p:get_line_no(1))
end)

test("add child node", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   -- when
   p:append_node(1, 2, "child")
   -- then
   assert_eq(2, p:nodes_len())
   assert_eq({ text = "child", depth = 1, id = 2, has_children = false }, p:get_node(2))
   assert_eq(2, p:get_line_no(2))
   -- and
   assert(p:get_node(1).has_children)
end)

test("update node text", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   -- when
   p:update_node_text(1, "updated")
   -- then
   assert_eq("updated", p:get_node(1).text)
end)
