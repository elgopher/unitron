-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- lights is a gui component showing lights of different color :)

function attach_lights(gui, el)
    local lights = {}
    local lights_max = 0
    local size = 2 -- light size in pixels

    local container = gui:attach(el)

    function container:set_light(no, color)
        lights[no] = color
        lights_max = max(lights_max, no)
    end

    function container:draw()
        rectfill(0, 0, el.width, el.height, 0)
        local x, y = 0, 0

        for i = 1, lights_max do
            local light = lights[i]
            if light == nil then
                light = 0
            end

            rectfill(x, y, x + size, y + size, light)

            if x >= el.width then
                x = 0
                y += size * 2
                if y >= el.height then
                    return
                end
            else
                x += size * 2
            end
        end
    end

    return container
end
