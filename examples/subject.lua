-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- this file is "production" code which will be tested by subject_test.lua

function concat(left, right)
	return left .. right
end

function divide(left, right)
	return left / right
end

function add_numbers(left, right)
	return left + right
end

function new_player()
	local player = { position = 0 }
	function player:collides(other_player)
		return player.position == other_player.position
	end

	return player
end
