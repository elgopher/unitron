-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

function attach_test_summary(gui, el)
	local succeeded, failed = 0, 0

	el = gui:attach(el)

	function el:draw()
		rectfill(0, 0, el.width, el.height, 0)
		color(26)
		print("Succeeded: " .. succeeded .. " \f8 Failed: " .. failed)
	end

	function el:inc_succeeded()
		succeeded += 1
	end

	function el:inc_failed()
		failed += 1
	end

	return el
end
