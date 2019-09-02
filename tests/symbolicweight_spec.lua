local cassowary = require("cassowary")

describe('cassowary.SymbolicWeight', function ()

  describe('ctor', function ()

    describe('no args', function ()
      local weight = cassowary.SymbolicWeight {}
      it('has the right weight', function () assert.is.same(0, weight.value) end)
    end)

    describe('var args', function ()
      local weight = cassowary.SymbolicWeight { 1, 1 }
      it('has the right weight', function () assert.is.same(1001, weight.value) end)
    end)

  end)

end)
