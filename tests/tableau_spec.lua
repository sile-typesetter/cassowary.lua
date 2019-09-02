local cassowary = require("cassowary")

describe('cassowary.Tableau', function ()

  describe('ctor', function ()

    it('doesn\'t blow up', function ()
      cassowary.Tableau()
    end)

    it('has sane properties', function ()
      local tableau = cassowary.Tableau ()
      assert.is.same(0, #(tableau.columns));
      assert.is.same(0, #(tableau.rows));
      assert.is.same(0, #(tableau.infeasibleRows));
      assert.is.same(0, #(tableau.externalRows));
      assert.is.same(0, #(tableau.externalParametricVars));
    end)

  end)

end)
