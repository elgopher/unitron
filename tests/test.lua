-- (c) 2024 Jacek Olszak
-- This code is licensed under CC BY-NC-SA 4.0 License (see LICENSE for details)

-- this file contains functions used in tests veryfing unitron behavior
-- functions here are extremely simple compared to unitron (no custom assertions, 
-- no spawning background processes etc.)

local level = 0

function test(name, func)
    local space = " "
    print(space:rep(level) .. "Running " .. name)
    level += 1
    func()
    level -= 1
end