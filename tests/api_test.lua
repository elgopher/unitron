-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

include "test.lua"
include "../api.lua"

test("assert_eq", function()
	test("should fail when not equal", function()
		local tests = {
			numbers = {
				left = 10, right = 11,
			},
			strings = {
				left = "a", right = "b",
			},
			flat_tables = {
				left = { key = "value" },
				right = { key = "different_value" },
			},
			tables_with_different_number_of_keys = {
				left = { key = "value" },
				right = { key = "value", another_key = "another_value" },
			},
			nested_tables = {
				left = { a = { b = "c" } },
				right = { a = { b = "d" } },
			},
			different_types = {
				left = "1", right = 1,
			},
			userdata_different_width = {
				left  = userdata("u8", 2, 1),
				right = userdata("u8", 1, 1),
			},
			userdata_different_height = {
				left  = userdata("u8", 1, 2),
				right = userdata("u8", 1, 1),
			},
			userdata_different_values = {
				left = userdata('u8', 2, 2, "02030405"),
				right = userdata('u8', 2, 2, "0A0B0C0D"),
			},
			userdata_different_type = {
				left = userdata('u8', 2, 2),
				right = userdata('i32', 2, 2),
			},
		}

		for test_name, case in pairs(tests) do
			test(test_name, function()
				local success = pcall(assert_eq, case.left, case.right)
				assert(not success)
			end)
		end
	end)

	test("should not fail when equal", function()
		local table_with_cycle = {}
		table_with_cycle.next = table_with_cycle

		local another_table_with_cycle = {}
		another_table_with_cycle.next = another_table_with_cycle

		local tests = {
			numbers = {
				left = 10, right = 10,
			},
			strings = {
				left = "a", right = "a",
			},
			flat_tables = {
				left = { key = "value" },
				right = { key = "value" },
			},
			nested_tables = {
				left = { a = { b = "c" } },
				right = { a = { b = "c" } },
			},
			-- in Lua there is no distinction whether key is nil
			-- or not present in a table:
			tables_with_nil_value = {
				left = { key = nil },
				right = { another_key = nil },
			},
			tables_with_cycle = {
				left = table_with_cycle,
				right = another_table_with_cycle,
			},
			userdata = {
				left = userdata('u8', 2, 2, "02030405"),
				right = userdata('u8', 2, 2, "02030405"),
			},
		}

		for test_name, case in pairs(tests) do
			test(test_name, function()
				assert_eq(case.left, case.right)
			end)
		end
	end)
end)
