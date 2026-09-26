-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

---@param from table
---@param pos integer
---@param to table
function insert_table(from, pos, to)
   table.move(to,
      pos, pos + (#to - pos),
      #from + pos)

   table.move(from, 1, #from, pos, to)
end

---Moves all elements from one table to another. Returns new table with removed
---elements
---@param from_table table
---@param from_first integer
---@param from_last integer
---@param to_table table
---@param to_first integer
function move_table(from_table, from_first, from_last, to_table, to_first)
   local results = {}

   table.move(from_table, from_first, from_last, to_first, to_table)

   table.move(from_table, 1, from_first - 1, 1, results)
   table.move(from_table, from_last + 1, #from_table,
      from_first, results)

   return results
end
