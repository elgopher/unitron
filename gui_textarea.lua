-- (c) 2024 Jacek Olszak
-- This code is licensed under CC BY-NC-SA 4.0 License (see LICENSE for details)

function attach_textarea(gui, el)
    local line_height = 10

    el.draw = function() end -- draw is needed for clipping
    local container = gui:attach(el)
    local text_area = container:attach({ x = 0, y = 0, width = el.width, height = 0 })
    container:attach_scrollbars { autohide = true }

    local lines = {}

    function text_area:draw()
        local y = 0
        for _, line in ipairs(lines) do
            print(line, 0, y, 7)
            y += line_height
        end
    end

    function text_area:mousewheel(e)
        self.y += e.wheel_y * 32
    end

    function container:set_lines(lines_to_draw)
        text_area.y = 0
        lines = lines_to_draw
        text_area.height = line_height * #lines
    end

    return container
end
