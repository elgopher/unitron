-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- table_len returns number of elements in a table t.
-- Keys with nil value are not counted
local function table_len(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

local function equal(expected, actual, visited_values)
	if expected == nil or actual == nil then
		return expected == actual
	end

	if visited_values == nil then
		visited_values = {}
		visited_values[expected] = true
	elseif visited_values[expected] == true then
		-- do not compare already visited values
		-- (avoid stack overflow for cycle references)
		return true
	end

	local function tables_equal(expected, actual)
		if table_len(expected) != table_len(actual) then
			return false
		end

		for k, v in pairs(expected) do
			if not equal(v, actual[k], visited_values) then
				return false
			end
		end

		return true
	end

	local function userdata_type(u)
		_, _, t = u:attribs()
		return t
	end

	if type(expected) != type(actual) then
		return false
	end

	if type(expected) == "userdata" then
		if userdata_type(expected) != userdata_type(actual) then
			return false
		end

		if expected:width() != actual:width() then
			return false
		end

		if expected:height() != actual:height() then
			return false
		end

		for i = 0, #expected do
			if expected[i] != actual[i] then
				return false
			end
		end

		return true
	end

	if type(expected) == "table" then
		return tables_equal(expected, actual)
	end

	return expected == actual
end

local function msg_or(msg, default)
	if msg == nil then
		return default
	end
	return tostring(msg)
end

---Asserts that expected and actual are equal. Values must have the same type.
---
---For strings, numbers and booleans '==' operator is used.
---
---For tables, all keys and values are compared deeply.
---If you want to check if two variables reference to the same table in memory
---please use assert(a==b) instead.
---Tables could have cycles.
---
---For userdata, all data is compared and userdata must be of the same type,
---width and height.
---
---@param expected any
---@param actual any
---@param msg? any message which will be presented in the unitron ui, instead of standard message
function assert_eq(expected, actual, msg)
	test_helper()

	if not equal(expected, actual) then
		test_fail {
			msg = msg_or(msg, "args not equal"),
			expect = expected,
			actual = actual
		}
	end
end

---@param not_expected any
---@param actual any
---@param msg? any message which will be presented in the unitron ui, instead of standard message
function assert_not_eq(not_expected, actual, msg)
	test_helper()

	if equal(not_expected, actual) then
		test_fail {
			msg = msg_or(msg, "args are equal"),
			not_expect = not_expected,
			actual = actual,
		}
	end
end

---@param expected number
---@param actual number
---@param delta number
---@param msg? any message which will be presented in the unitron ui, instead of standard message
function assert_close(expected, actual, delta, msg)
	test_helper()

	local invalid_args = expected == nil or actual == nil or delta == nil
	if invalid_args or abs(expected - actual) > delta then
		test_fail {
			msg = msg_or(msg, "args not close"),
			expect = expected,
			actual = actual,
			delta = delta,
		}
	end
end

---@param not_expected number
---@param actual number
---@param delta number
---@param msg? any message which will be presented in the unitron ui, instead of standard message
function assert_not_close(not_expected, actual, delta, msg)
	test_helper()

	local invalid_args = not_expected == nil or actual == nil or delta == nil
	if invalid_args or abs(not_expected - actual) <= delta then
		test_fail {
			msg = msg_or(msg, "args too close"),
			not_expect = not_expected,
			actual = actual,
			delta = delta,
		}
	end
end

---@param actual any
---@param msg? any message which will be presented in the unitron ui, instead of standard message
function assert_not_nil(actual, msg)
	test_helper()

	if actual == nil then
		test_fail {
			msg = msg_or(msg, "arg is nil")
		}
	end
end

---@param actual any
---@param msg? any message which will be presented in the unitron ui, instead of standard message
function assert_nil(actual, msg)
	test_helper()

	if actual != nil then
		test_fail {
			msg = msg_or(msg, "arg is not nil"),
			actual = actual
		}
	end
end
