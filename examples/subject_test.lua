-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

include "subject.lua" -- include the "production" code which will be tested here

-- test function starts a test with given name. Code of the test is provided
-- in the anonymous function:
test("compare strings", function()
	local s = concat("hello ", "world")
	assert_eq("hello world", s) -- change total assert_not_eq to get test error
	-- assertions can have optional message which is presented in the unitron's
	-- user interface:
	assert_eq("hello world", s, "should return \"hello world\"")
end)

test("compare tables", function()
	local expected = {
		a = "a value",
		b = "b value",
	}
	local actual = {
		a = "a value",
		b = "b value",
	}
	assert_eq(expected, actual) -- tables are compared deeply
end)

test("compare numbers", function()
	local sum = divide(10.444, 9.99)
	local delta = 0.0001
	assert_close(1.0454, sum, delta)
end)

test("compare userdata", function()
	local u1 = userdata("u8", 2, 2, "00010203")
	local u2 = userdata("u8", 2, 2, "00010203")
	assert_eq(u1, u2)
end)

test("assert nil", function()
	local v = nil
	assert_nil(v)
end)

-- sometimes you want to be sure that two tables are pointing to the same
-- address in memory
test("compare pointers", function()
	local t = { key = "value" }
	local pointer_to_t = t
	-- internally assert_same just runs expected==actual:
	assert_same(t, pointer_to_t)
end)

-- standard assert function can be used too to veryify if argument is true
test("standard assert aka assert true", function()
	assert(true)
end)

-- you can nest tests multiple times. This is useful in grouping similar tests.
test("nesting tests", function()
	test("nested test", function()
		assert(true)
	end)
	test("another nested test", function()
		test("yet another", function()
			assert(true)
		end)
	end)
end)

-- table driven tests are the kind of nested tests which use tests defined
-- in tables. This greatly reduces amount of code.
test("table driven tests", function()
	local tests = {
		-- first test case with name "2+2=4".
		-- You can drop square brackets and quotes when key does not have
		-- special characters.
		["2+2=4"] = { left = 2, right = 2, expected_sum = 4 },
		["0+1=1"] = { left = 0, right = 1, expected_sum = 1 } -- second test case
	}

	for test_name, test_case in pairs(tests) do
		-- start nested test with test case name so when there is an error
		-- you will know which specific test case failed:
		test(test_name, function()
			local sum = add_numbers(test_case.left, test_case.right)
			assert_eq(test_case.expected_sum, sum)
		end)
	end
end)

-- test can be slow, but don't worry - it does not block the unitron ui
test("slow test", function()
	for i = 1, 1000000 do
		spr(0, 30, 30) -- drawing sprites also does not break the unitron ui
	end
end)

-- sometimes you want to reuse variables in multiple tests. Reusing
-- state between tests is not a good idea, because tests should be
-- independent. However, there is a way to reuse variables and still
-- have independent tests. You can use a setup function which will
-- re-initialize these variables on the beginning of each test.
test("test with setup function", function()
	local player1, player2 -- these variables will be reused

	-- setup will be run on the beginning of each test:
	local function setup()
		player1 = new_player()
		player1.position = 1
		player2 = new_player()
		player2.position = 2
	end

	test("players should collide", function()
		setup() -- initialize players
		-- following line modifies player2, so the next test will be
		-- affected, if the player2 is not re-initialized
		player2.position = player1.position
		assert(player1:collides(player2))
	end)

	test("players should not collide", function()
		-- initialize players again. setup will override local player variables:
		setup()
		assert(not player1:collides(player2))
	end)
end)
