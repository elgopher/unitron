-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- new_printed_lines returns object which holds lines printed for given test
function new_printed_lines()
   local by_test_id = {}

   local printed_lines <const> = {}

   function printed_lines:print(test_id, text)
      if by_test_id[test_id] == nil then
         by_test_id[test_id] = {}
      end
      table.insert(by_test_id[test_id], text)
   end

   function printed_lines:line(test_id, line_no)
      if by_test_id[test_id] == nil then
         return ""
      end

      return by_test_id[test_id][line_no] or ""
   end

   function printed_lines:lines_len(test_id, line_no)
      if by_test_id[test_id] == nil then
         return 0
      end

      return #by_test_id[test_id] or 0
   end

   function printed_lines:reset()
      by_test_id = {}
   end

   return printed_lines
end
