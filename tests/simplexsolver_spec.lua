c = require("cassowary")
assert = require("luassert")

  describe('c.SimplexSolver', function ()
    it('should be constructable without args', function ()
      assert.is.truthy(c.SimplexSolver())
    end)
  end)

  describe("addEditVar", function()
    it("works with required strength", function()
      local solver = c.SimplexSolver();
      local a = c.Variable({name = "a"});

      solver:addConstraint(c.StayConstraint(a, c.Strength.strong, 0));
      solver:resolve();

      assert.equal(0, a.value);

      solver:addEditVar(a, c.Strength.required) :beginEdit() :suggestValue(a, 2) :resolve();
      assert.is.equal(2, a.value);
    end);
    it("works with required strength after many suggestions", function()
      local solver = c.SimplexSolver();
      local a = c.Variable({name = "a"});
      local b = c.Variable({name = "b"});

      solver:addConstraint(c.StayConstraint(a, c.Strength.strong, 0)) :addConstraint(c.Equation(a,b,c.Strength.required)) :resolve();
      assert.equal(0, b.value);
      assert.equal(0, a.value);

      solver:addEditVar(a, c.Strength.required) :beginEdit() :suggestValue(a, 2) :resolve();

      assert.equal(2, a.value);
      assert.equal(2, b.value);
      
      solver:suggestValue(a, 10):resolve();
        
      assert.equal(10, a.value);
      assert.equal(10, b.value);
    end);
    it('works with weight', function ()
      local x = c.Variable({ name= 'x' });
      local y = c.Variable({ name= 'y' });
      local solver = c.SimplexSolver();
      solver:addStay(x):addStay(y):addConstraint(c.Equation(x, y, c.Strength.required)):addEditVar(x,c.Strength.medium,1)
      solver:addEditVar(y,c.Strength.medium,10):beginEdit()
      solver:suggestValue(x, 10):suggestValue(y, 20)
      solver:resolve();
      assert.is.truthy(c.approx(x.value, 20));
      assert.is.truthy(c.approx(y.value, 20));
    end);        
  end);