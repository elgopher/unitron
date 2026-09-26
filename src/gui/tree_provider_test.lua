-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- run this file in unitron gui

include "tree_provider.lua"
include "../lib/tables.lua" -- TODO ugly way of importing dependencies

test("new provider has 0 lines", function()
   local p = new_tree_provider()
   assert_eq(0, p:nodes_len())
end)

test("add root", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   assert_eq(1, p:nodes_len())
   assert_eq(
      {
         text = "root",
         depth = 0,
         id = 1,
         has_children = false,
         collapsed = false
      },
      p:get_node(1)
   )
   assert_eq(1, p:get_line_no(1))
end)

test("add child node", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   -- when
   p:append_node(1, 2, "child")
   -- then
   assert_eq(2, p:nodes_len())
   assert_eq(
      {
         text = "child",
         depth = 1,
         id = 2,
         parent_id = 1,
         has_children = false,
         collapsed = false
      },
      p:get_node(2)
   )
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

test("toggle_line", function()
   test("should collapse node", function()
      local p = new_tree_provider()
      p:append_node(nil, 1, "root")
      p:append_node(1, 2, "child")
      p:append_node(2, 3, "subchild")
      -- when
      p:toggle_line(1)
      -- then
      assert(p:get_node(1).collapsed)
      assert_eq(1, p:nodes_len())

      test("should expand node", function()
         -- when
         p:toggle_line(1)
         -- then
         assert(not p:get_node(1).collapsed)
         assert_eq(3, p:nodes_len())
         assert_eq("child", p:get_node(2).text)
         assert_eq("subchild", p:get_node(3).text)
      end)
   end)
end)

test("append_node when parent node is collapsed", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   p:toggle_line(1) -- collapse root
   -- when
   p:append_node(1, 2, "child")
   -- then
   assert(p:nodes_len() == 1, "child should not be visible")
end)

test("append_node when parent of parent is collapsed", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   p:append_node(1, 2, "child")
   p:toggle_line(1) -- collapse root
   -- when
   p:append_node(2, 3, "subchild")
   -- then
   assert(p:nodes_len() == 1, "subchild should not be visible")
end)

test("expand when node added when parent was collapsed", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   p:toggle_line(1) -- collapse root
   p:append_node(1, 2, "child")
   -- when
   p:toggle_line(1) -- expand root
   assert_eq(2, p:nodes_len(), "two elements expected")
end)

test("expand node after another child was added", function()
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")
   p:append_node(1, 2, "child") -- line 2
   p:append_node(2, 3, "subchild")
   p:toggle_line(2)             -- collapse child
   p:append_node(1, 4, "another child")
   assert_eq(3, p:nodes_len())
   p:toggle_line(2) -- expand child
   assert_eq(4, p:nodes_len())
end)

test("thousands of children", function()
   -- should finish in a second
   local p = new_tree_provider()
   p:append_node(nil, 1, "root")

   test("append_node", function()
      for id = 2, 10000 do
         p:append_node(1, id, "child")
      end
   end)

   test("toggle_line", function()
      p:toggle_line(1)
      p:toggle_line(1)
   end)
end)
