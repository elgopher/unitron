-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

include "tables.lua"

test("insert_table", function()
   local from = { 1, 2, 3 }
   local to = { 'A', 'B', 'C' }
   local pos = 2
   insert_table(from, pos, to)
   assert_eq({ 'A', 1, 2, 3, 'B', 'C' }, to)
end)

test("move_table", function()
   local from = { 1, 2, 3 }
   local to = { 'A', 'B', 'C' }
   local result = move_table(from, 2, 3, to, 2)
   assert_eq({ 'A', 2, 3 }, to)
   assert_eq({ 1 }, result)
end)
