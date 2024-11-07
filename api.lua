-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- table_len returns number of elements in a table t. Keys with nil value are not counted
local function table_len(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

local function equal(expected, actual, visited_values)
	if visited_values == nil then
		visited_values = {}
		visited_values[expected] = true
	elseif visited_values[expected] == true then
		-- do not compare already visited values (avoid stack overflow for cycle references)
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
		-- dirty hack because I dont know the method to get userdata type
		-- TODO OPTIMIZE IT
		local p = pod(u)                   -- pod(u) returns userdata("u8",2,2,"02030405")
		p = string.gsub(p, "userdata%(\"", "") -- drop userdata("
		p = string.gsub(p, "\".*", "")     -- drop ").*
		return p
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

local function get_caller()
	local traceback = debug.traceback("", 3)
	local loc = split(traceback, "\n")[3]
	loc = string.gsub(loc, "(%d+):.*", "%1") -- drop message
	loc = string.gsub(loc, "\t", "")       -- drop tabulator
	return loc
end

local function serialize_arg(v)
	if v == nil then
		return
	end
	local serialized = pod(v)
	if serialized == nil then
		if type(v) == "table" then
			return "[cyclic table]"
		else
			return "[not serializable]"
		end
	end

	return serialized
end

local function serialize_message(msg)
	if msg == nil then
		return nil
	end

	return tostring(msg)
end

---Asserts that expected and actual are equal. Values must have the same type.
---
---For strings, numbers and booleans '==' operator is used.
---
---For tables, all keys and values are compared deeply.
---If you want to compare if two tables points to the same address in memory please use assert_same instead.
---Tables could have cycles.
---
---For userdata, all data is compared and userdata must be of the same type, width and height.
---
---@param expected any
---@param actual any
---@param msg? any message which will be presented in the unitron ui.
function assert_eq(expected, actual, msg)
	if not equal(expected, actual) then
		local err = {
			assert = "eq",
			expected = serialize_arg(expected),
			actual = serialize_arg(actual),
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end

function assert_not_eq(not_expected, actual, msg)
	if equal(not_expected, actual) then
		local err = {
			assert = "not_eq",
			actual = serialize_arg(actual),
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end

function assert_same(expected, actual, msg)
	if expected != actual then
		local err = {
			assert = "same",
			expected = tostring(expected), -- tostring() is more useful than serialize because pointers have more value than values here
			actual = tostring(actual),
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end

function assert_not_same(not_expected, actual, msg)
	if not_expected == actual then
		local err = {
			assert = "not_same",
			actual = tostring(actual),
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end

function assert_close(expected, actual, delta, msg)
	if abs(expected - actual) > delta then
		local err = {
			assert = "close",
			expected = tostring(expected), -- TODO Picotron has a bug that small numbers are not properly serialized
			actual = tostring(actual), -- TODO Picotron has a bug that small numbers are not properly serialized
			delta = tostring(delta), -- TODO Picotron has a bug that small numbers are not properly serialized
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end

function assert_not_close(not_expected, actual, delta, msg)
	if abs(not_expected - actual) <= delta then
		local err = {
			assert = "not_close",
			not_expected = tostring(not_expected), -- TODO Picotron has a bug that small numbers are not properly serialized
			actual = tostring(actual),       -- TODO Picotron has a bug that small numbers are not properly serialized
			delta = tostring(delta),         -- TODO Picotron has a bug that small numbers are not properly serialized
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end

function assert_not_nil(actual, msg)
	if actual == nil then
		local err = {
			assert = "not_nil",
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end

function assert_nil(actual, msg)
	if actual != nil then
		local err = {
			assert = "nil",
			actual = tostring(actual),
			msg = serialize_message(msg),
			file = get_caller(),
		}
		error(err)
	end
end
