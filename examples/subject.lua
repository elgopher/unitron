-- (c) 2024 Jacek Olszak
-- This code is licensed under CC BY-NC-SA 4.0 License (see LICENSE for details)

-- this file is "production" code which will be tested by subject_test.lua

---@param left string
---@param right string
---@return string
function concat(left, right)
    return left .. right
end

---@param left number
---@param right number
---@return number
function divide(left, right)
    return left / right
end

---@param left number
---@param right number
---@return number
function add(left, right)
    return left + right
end
