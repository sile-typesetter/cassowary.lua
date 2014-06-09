c = require("cassowary")
assert = require("luassert")

	describe('c.SymbolicWeight', function ()
		describe('ctor', function ()
			describe('no args', function ()
				local w1 = c.SymbolicWeight {};
				it('has the right weight', function () assert.is.same(0, w1.value); end)
			end)
			describe('var args', function ()
				local w2 = c.SymbolicWeight {1; 1}
				it('has the right weight', function () assert.is.same(1001, w2.value); end)
			end)
		end)
	end)
