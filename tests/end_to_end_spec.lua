local cassowary = require("cassowary")

describe('End-To-End', function ()

  it('simple1', function ()
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 167 })
    local y = cassowary.Variable({ value =   2 })
    local eq = cassowary.Equation(x, cassowary.Expression(y))
    solver:addConstraint(eq)
    assert.equal(x.value, y.value)
    assert.equal(0, x.value)
    assert.equal(0, y.value)
  end)

  it('justStay1', function ()
    local x = cassowary.Variable({ value =  5 })
    local y = cassowary.Variable({ value = 10 })
    local solver = cassowary.SimplexSolver()
    solver:addStay(x)
    solver:addStay(y)
    assert.is.truthy(cassowary.approx(x,  5))
    assert.is.truthy(cassowary.approx(y, 10))
    assert.is.same(5, x.value)
    assert.is.same(10, y.value)
  end)

  it('local >= num', function ()
    -- x >= 100
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 10 })
    local ieq = cassowary.Inequality(x, ">=", 100)
    solver:addConstraint(ieq)
    assert.is.same(100, x.value)
  end)

  it('num == var', function ()
    -- 100 == var
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 10 })
    local eq = cassowary.Equation(100, x)
    solver:addConstraint(eq)
    assert.is.same(x.value, 100)
  end)

  it('num <= var', function ()
    -- x >= 100
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 10 })
    local ieq = cassowary.Inequality(100, "<=", x)
    solver:addConstraint(ieq)
    assert.is.same(100, x.value)
  end)

  it('exp >= num', function ()
    -- stay width
    -- right >= 100
    local solver = cassowary.SimplexSolver()
    -- x = 10
    local x = cassowary.Variable({ value = 10 })
    -- width = 10
    local width = cassowary.Variable({ value = 10 })
    -- right = x + width
    local right = cassowary.Expression(x):plus(width)
    -- right >= 100
    local ieq = cassowary.Inequality(right, ">=", 100)
    solver:addStay(width)
    solver:addConstraint(ieq)
    assert.is.same(90, x.value)
    assert.is.same(10, width.value)
  end)

  it('num <= exp', function ()
    -- stay width
    -- 100 <= right
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 10 })
    local width = cassowary.Variable({ value = 10 })
    local right = cassowary.Expression(x):plus(width)
    local ieq = cassowary.Inequality(100, "<=", right)
    solver:addStay(width):addConstraint(ieq)
    assert.is.same(90, x.value)
    assert.is.same(10, width.value)
  end)

  it('exp == var', function ()
    -- stay width, rightMin
    -- right >= rightMin
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 10 })
    local width = cassowary.Variable({ value = 10 })
    local rightMin = cassowary.Variable({ value = 100 })
    local right = cassowary.Expression(x):plus(width)
    local eq = cassowary.Equation(right, rightMin)
    solver:addStay(width) :addStay(rightMin) :addConstraint(eq)
    assert.is.same(90, x.value)
    assert.is.same(10, width.value)
  end)

  it('exp >= var', function ()
    -- stay width, rightMin
    -- right >= rightMin
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 10 })
    local width = cassowary.Variable({ value = 10 })
    local rightMin = cassowary.Variable({ value = 100 })
    local right = cassowary.Expression(x):plus(width)
    local ieq = cassowary.Inequality(right, ">=", rightMin)
    solver:addStay(width) :addStay(rightMin) :addConstraint(ieq)
    assert.is.same(90, x.value)
    assert.is.same(10, width.value)
  end)

  it('local <= exp', function ()
    -- stay width
    -- right >= rightMin
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ value = 10 })
    local width = cassowary.Variable({ value = 10 })
    local rightMin = cassowary.Variable({ value = 100 })
    local right = cassowary.Expression(x):plus(width)
    local ieq = cassowary.Inequality(rightMin, "<=", right)
    solver:addStay(width):addStay(rightMin):addConstraint(ieq)
    assert.is.same(90, x.value)
    assert.is.same(10, width.value)
  end)

  it('exp == exp', function ()
    -- stay width, rightMin
    -- right >= rightMin
    local solver = cassowary.SimplexSolver()
    local x1 = cassowary.Variable({ value = 10 })
    local width1 = cassowary.Variable({ value = 10 })
    local right1 = cassowary.Expression(x1):plus(width1)
    local x2 = cassowary.Variable({ value = 100 })
    local width2 = cassowary.Variable({ value = 10 })
    local right2 = cassowary.Expression(x2):plus(width2)
    local eq = cassowary.Equation(right1, right2)
    solver:addStay(width1) :addStay(width2) :addStay(x2) :addConstraint(eq)
    assert.is.same(100, x1.value)
    assert.is.same(100, x2.value)
    assert.is.same(10, width1.value)
    assert.is.same(10, width2.value)
  end)

  it('exp >= exp', function ()
    -- stay width, rightMin
    -- right >= rightMin
    local solver = cassowary.SimplexSolver()
    local x1 = cassowary.Variable({ value = 10 })
    local width1 = cassowary.Variable({ value = 10 })
    local right1 = cassowary.Expression(x1):plus(width1)
    local x2 = cassowary.Variable({ value = 100 })
    local width2 = cassowary.Variable({ value = 10 })
    local right2 = cassowary.Expression(x2):plus(width2)
    local ieq = cassowary.Inequality(right1, ">=", right2)
    solver:addStay(width1) :addStay(width2) :addStay(x2) :addConstraint(ieq)
    assert.is.same(100, x1.value)
  end)

  it('exp <= exp', function ()
    -- stay width, rightMin
    -- right >= rightMin
    local solver = cassowary.SimplexSolver()
    local x1 = cassowary.Variable({ value = 10 })
    local width1 = cassowary.Variable({ value = 10 })
    local right1 = cassowary.Expression(x1):plus(width1)
    local x2 = cassowary.Variable({ value = 100 })
    local width2 = cassowary.Variable({ value = 10 })
    local right2 = cassowary.Expression(x2):plus(width2)
    local ieq = cassowary.Inequality(right2, "<=", right1)
    solver:addStay(width1)
    :addStay(width2)
    :addStay(x2)
    :addConstraint(ieq)
    assert.is.same(100, x1.value)
  end)

  it('addDelete1', function ()
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ name= 'x' })
    local cbl = cassowary.Equation(x, 100, cassowary.Strength.weak)
    solver:addConstraint(cbl)
    local c10 = cassowary.Inequality(x, "<=", 10)
    local c20 = cassowary.Inequality(x, "<=", 20)
    solver:addConstraint(c10):addConstraint(c20)
    assert.is.truthy(cassowary.approx(x,  10))
    solver:removeConstraint(c10)
    assert.is.truthy(cassowary.approx(x,  20))
    solver:removeConstraint(c20)
    assert.is.truthy(cassowary.approx(x, 100))
    local c10again = cassowary.Inequality(x, "<=", 10)
    solver:addConstraint(c10)
    :addConstraint(c10again)
    assert.is.truthy(cassowary.approx(x,  10))
    solver:removeConstraint(c10)
    assert.is.truthy(cassowary.approx(x,  10))
    solver:removeConstraint(c10again)
    assert.is.truthy(cassowary.approx(x, 100))
  end)

  it('addDelete2', function ()
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ name = 'x' })
    local y = cassowary.Variable({ name = 'y' })
    solver:addConstraint(cassowary.Equation(x, 100, cassowary.Strength.weak))
    :addConstraint(cassowary.Equation(y, 120, cassowary.Strength.strong))
    local c10 = cassowary.Inequality(x, "<=", 10)
    local c20 = cassowary.Inequality(x, "<=", 20)
    solver:addConstraint(c10)
    :addConstraint(c20)
    assert.is.truthy(cassowary.approx(x,  10))
    assert.is.truthy(cassowary.approx(y, 120))
    solver:removeConstraint(c10)
    assert.is.truthy(cassowary.approx(x,  20))
    assert.is.truthy(cassowary.approx(y, 120))
    local cxy = cassowary.Equation(cassowary.times(2, x), y)
    solver:addConstraint(cxy)
    assert.is.truthy(cassowary.approx(x,  20))
    assert.is.truthy(cassowary.approx(y,  40))
    solver:removeConstraint(c20)
    assert.is.truthy(cassowary.approx(x,  60))
    assert.is.truthy(cassowary.approx(y, 120))
    solver:removeConstraint(cxy)
    assert.is.truthy(cassowary.approx(x, 100))
    assert.is.truthy(cassowary.approx(y, 120))
  end)

  it('casso1', function ()
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ name = 'x' })
    local y = cassowary.Variable({ name = 'y' })
    solver:addConstraint(cassowary.Inequality(x, "<=", y))
      :addConstraint(cassowary.Equation(y, cassowary.plus(x, 3)))
      :addConstraint(cassowary.Equation(x, 10, cassowary.Strength.weak))
      :addConstraint(cassowary.Equation(y, 10, cassowary.Strength.weak))
    assert.is.truthy(
      (cassowary.approx(x, 10) and cassowary.approx(y, 13)) or
      (cassowary.approx(x,  7) and cassowary.approx(y, 10)))
  end)

  it('inconsistent1', function ()
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ name = 'x' })
    -- x = 10
    solver:addConstraint(cassowary.Equation(x, 10))
    -- x = 5
    assert.has.errors(function () solver:addConstraint(cassowary.Equation(x, 5)) end)
  end)

  it('inconsistent2', function ()
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ name = 'x' })
    solver:addConstraint(cassowary.Inequality(x, ">=", 10))
    assert.has.errors(function()
      solver:addConstraint(cassowary.Inequality(x, "<=", 5))
    end)
  end)

  it('inconsistent3', function ()
    local solver = cassowary.SimplexSolver()
    local w = cassowary.Variable({ name = 'w' })
    local x = cassowary.Variable({ name = 'x' })
    local y = cassowary.Variable({ name = 'y' })
    local z = cassowary.Variable({ name = 'z' })
    solver:addConstraint(cassowary.Inequality(w, ">=", 10))
    :addConstraint(cassowary.Inequality(x, ">=", w))
    :addConstraint(cassowary.Inequality(y, ">=", x))
    :addConstraint(cassowary.Inequality(z, ">=", y))
    :addConstraint(cassowary.Inequality(z, ">=", 8))
    assert.has.errors(function()
      solver:addConstraint(cassowary.Inequality(z, "<=", 4))
    end)
  end)

  it('inconsistent4', function ()
    local solver = cassowary.SimplexSolver()
    local x = cassowary.Variable({ name = 'x' })
    local y = cassowary.Variable({ name = 'y' })
    -- x = 10
    solver:addConstraint(cassowary.Equation(x, 10))
    -- x = y
    solver:addConstraint(cassowary.Equation(x, y))
    -- y = 5. Should fail.
    assert.has.errors(function()
      solver:addConstraint(cassowary.Equation(y, 5))
    end)
  end)

  it('multiedit', function ()
    -- This test stresses the edit session stack. beginEdit() starts a new
    -- "edit variable group" and "endEdit" closes it, leaving only the
    -- previously opened edit variables still active.
    local x = cassowary.Variable({ name = 'x' })
    local y = cassowary.Variable({ name = 'y' })
    local w = cassowary.Variable({ name = 'w' })
    local h = cassowary.Variable({ name = 'h' })
    local solver = cassowary.SimplexSolver()
    -- Add some stays and start an editing session
    solver:addStay(x)
    :addStay(y)
    :addStay(w)
    :addStay(h)
    :addEditVar(x)
    :addEditVar(y):beginEdit()
    solver:suggestValue(x, 10)
    :suggestValue(y, 20):resolve()
    assert.is.truthy(cassowary.approx(x, 10))
    assert.is.truthy(cassowary.approx(y, 20))
    assert.is.truthy(cassowary.approx(w,  0))
    assert.is.truthy(cassowary.approx(h,  0))
    -- Open a second set of variables for editing
    solver:addEditVar(w)
    :addEditVar(h):beginEdit()
    solver:suggestValue(w, 30)
    :suggestValue(h, 40)
    solver:endEdit()
    -- Close the second set...
    assert.is.truthy(cassowary.approx(x, 10))
    assert.is.truthy(cassowary.approx(y, 20))
    assert.is.truthy(cassowary.approx(w, 30))
    assert.is.truthy(cassowary.approx(h, 40))
    -- Now make sure the first set can still be edited
    solver:suggestValue(x, 50)
    :suggestValue(y, 60):endEdit()
    assert.is.truthy(cassowary.approx(x, 50))
    assert.is.truthy(cassowary.approx(y, 60))
    assert.is.truthy(cassowary.approx(w, 30))
    assert.is.truthy(cassowary.approx(h, 40))
  end)

  it('multiedit2', function ()
    local x = cassowary.Variable({ name= 'x' })
    local y = cassowary.Variable({ name= 'y' })
    local w = cassowary.Variable({ name= 'w' })
    local h = cassowary.Variable({ name= 'h' })
    local solver = cassowary.SimplexSolver()
    solver:addStay(x)
    :addStay(y)
    :addStay(w)
    :addStay(h)
    :addEditVar(x)
    :addEditVar(y):beginEdit()
    solver:suggestValue(x, 10)
    :suggestValue(y, 20):resolve()
    solver:endEdit()
    assert.is.truthy(cassowary.approx(x, 10))
    assert.is.truthy(cassowary.approx(y, 20))
    assert.is.truthy(cassowary.approx(w,  0))
    assert.is.truthy(cassowary.approx(h,  0))
    solver:addEditVar(w)
    :addEditVar(h):beginEdit()
    solver:suggestValue(w, 30)
    :suggestValue(h, 40):endEdit()
    assert.is.truthy(cassowary.approx(x, 10))
    assert.is.truthy(cassowary.approx(y, 20))
    assert.is.truthy(cassowary.approx(w, 30))
    assert.is.truthy(cassowary.approx(h, 40))
    solver:addEditVar(x)
    :addEditVar(y):beginEdit()
    solver:suggestValue(x, 50)
    :suggestValue(y, 60):endEdit()
    assert.is.truthy(cassowary.approx(x, 50))
    assert.is.truthy(cassowary.approx(y, 60))
    assert.is.truthy(cassowary.approx(w, 30))
    assert.is.truthy(cassowary.approx(h, 40))
  end)

  -- it('multiedit3', function ()
  -- 	local rand = function (max, min) {
  -- 		min = (typeof min !== 'undefined') ? min : 0
  -- 		max = max || Math.pow(2, 26)
  -- 		return parseInt(Math.random() * (max - min), 10) + min
  -- 	}
  -- 	local MAX = 500
  -- 	local MIN = 100

  -- 	local weak = cassowary.Strength.weak
  -- 	local medium = cassowary.Strength.medium
  -- 	local strong = cassowary.Strength.strong

  -- 	local eq  = function (a1, a2, strength, w) {
  -- 		return cassowary.Equation(a1, a2, strength || weak, w || 0)
  -- 	}

  -- 	local v = {
  -- 		width: cassowary.Variable({ name: 'width' }),
  -- 		height: cassowary.Variable({ name: 'height' }),
  -- 		top: cassowary.Variable({ name: 'top' }),
  -- 		bottom: cassowary.Variable({ name: 'bottom' }),
  -- 		left: cassowary.Variable({ name: 'left' }),
  -- 		right: cassowary.Variable({ name: 'right' }),
  -- 	}

  -- 	local solver = cassowary.SimplexSolver()

  -- 	local iw = cassowary.Variable({
  -- 		name: 'window_innerWidth',
  -- 		value = rand(MAX, MIN)
  -- 	})
  -- 	local ih = cassowary.Variable({
  -- 		name: 'window_innerHeight',
  -- 		value = rand(MAX, MIN)
  -- 	})
  -- 	local iwStay = cassowary.StayConstraint(iw)
  -- 	local ihStay = cassowary.StayConstraint(ih)

  -- 	local widthEQ = eq(v.width, iw, strong)
  -- 	local heightEQ = eq(v.height, ih, strong)

  -- 	[
  -- 		widthEQ,
  -- 		heightEQ,
  -- 		eq(v.top, 0, weak),
  -- 		eq(v.left, 0, weak),
  -- 		eq(v.bottom, cassowary:plus(v.top, v.height), medium),
  -- 		-- Right is at least left + width
  -- 		eq(v.right,  cassowary:plus(v.left, v.width), medium),
  -- 		iwStay,
  -- 		ihStay
  -- 	].forEach(function (cassowary) {
  -- 		solver:addConstraint(cassowary)
  -- 	})

  -- 	-- Propigate viewport size changes.
  -- 	local reCalc = function ()

  -- 		-- Measurement should be cheap here.
  -- 		local iwv = rand(MAX, MIN)
  -- 		local ihv = rand(MAX, MIN)

  -- 		solver:addEditVar(iw)
  -- 		solver:addEditVar(ih)

  -- 		solver:beginEdit()
  -- 		solver:suggestValue(iw, iwv)
  -- 		.suggestValue(ih, ihv)
  -- 		solver:resolve()
  -- 		solver:endEdit()

  -- 		assert.is.same(0, v.top.value)
  -- 		assert.is.same(0, v.left.value)
  -- 		assert.is.truthy(v.bottom.value <= MAX)
  -- 		assert.is.truthy(v.bottom.value >= MIN)
  -- 		assert.is.truthy(v.right.value <= MAX)
  -- 		assert.is.truthy(v.right.value >= MIN)

  -- 	}.bind(this)

  -- 	reCalc()
  -- 	reCalc()
  -- 	reCalc()
  -- })

  it('errorWeights', function ()
    local solver = cassowary.SimplexSolver()
    local weak = cassowary.Strength.weak
    local medium = cassowary.Strength.medium
    local strong = cassowary.Strength.strong
    local x = cassowary.Variable({ name = 'x', value = 100 })
    local y = cassowary.Variable({ name = 'y', value = 200 })
    local z = cassowary.Variable({ name = 'z', value =  50 })
    assert.is.same(100, x.value)
    assert.is.same(200, y.value)
    assert.is.same( 50, z.value)
    solver:addConstraint(cassowary.Equation(z, x, weak))
    :addConstraint(cassowary.Equation(x,  20, weak))
    :addConstraint(cassowary.Equation(y, 200, strong))
    assert.is.same( 20, x.value)
    assert.is.same(200, y.value)
    assert.is.same( 20, z.value)
    solver:addConstraint(
      cassowary.Inequality(cassowary.plus(z, 150), "<=", y, medium)
      )
    assert.is.same( 20, x.value)
    assert.is.same(200, y.value)
    assert.is.same( 20, z.value)
  end)
end)
