c = require("cassowary")
assert = require("luassert")

	describe('c.Tableau', function () 
		describe('ctor', function () 
			it('doesn\'t blow up', function () 
				c.Tableau()
			end)

			it('has sane properties', function () 
				local tab = c.Tableau {}
				assert.is.same(0, #(tab.columns));
				assert.is.same(0, #(tab.rows));
				assert.is.same(0, #(tab.infeasibleRows));
				assert.is.same(0, #(tab.externalRows));
				assert.is.same(0, #(tab.externalParametricVars));
			end)
		end)
	end)
