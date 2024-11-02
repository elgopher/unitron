-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

include "subject.lua" -- include the "production" code which will be tested here

test("compare strings", function()
    local s = concat("hello ", "world")
    -- change with assert_not_eq to get test error:
    assert_eq("hello world", s)                                
    -- assertions can have optional message which is presented in the runner: 
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

test("compare userdata", function ()
    local u1 = userdata("u8", 2, 2, "00010203")
    local u2 = userdata("u8", 2, 2, "00010203")
    assert_eq(u1, u2)
end)

test("assert nil", function()
    local v = nil
    assert_nil(v)
end)

-- sometimes you want to be sure that two tables are pointing to the same address
-- in memory
test("compare pointers", function()
    local t = { key = "value" }
    local pointer_to_t = t
    assert_same(t, pointer_to_t) -- internally assert_same just runs expected==actual
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

-- table driven tests are the kind of nested tests which use tests defined in tables. 
-- This greatly reduces amount of code.
test("table driven tests", function()
    local tests = {
     	 -- first test case with name "2+2=4".
     	 -- You can drop square brackets and quotes when key does not have special
     	 -- characters.
        ["2+2=4"] = { left = 2, right = 2, expected_sum = 4 },
        ["0+1=1"] = { left = 0, right = 1, expected_sum = 1 }  -- second test case
    }

    for test_name, test_case in pairs(tests) do
        -- start nested test with test case name so when there is an error 
        -- you will know which specific test case failed:
        test(test_name, function()
            local sum = add(test_case.left, test_case.right)
            assert_eq(test_case.expected_sum, sum)
        end)
    end
end)

-- test can be slow, but don't worry - it does not block the runner UI
test("slow test", function ()
    for i = 1, 1000000 do
        spr(0, 30, 30) -- drawing sprites does not breaks the runner UI  
    end
end)
