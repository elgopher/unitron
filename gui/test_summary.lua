-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

function attach_test_summary(gui, el)
    local succeded, failed = 0, 0

    local container = gui:attach(el)

    function container:draw()
        rectfill(0, 0, el.width, el.height, 0)
        color(26)
        print("Succeded: " .. succeded .. " \f8 Failed: " .. failed)
    end

    function container:inc_succeded()
        succeded += 1
    end

    function container:inc_failed()
        failed += 1
    end

    return container
end
