local cassowary = require("cassowary")

describe('cassowary.Expression', function ()

  it('is constructable with 3 variables as arguments', function ()
    local x = cassowary.Variable { name = 'x', value = 167 }
    local e = cassowary.Expression(x, 2, 3)
    assert.is.same('3 + 2*167', tostring(e))
  end)

  it('is constructable with one parameter', function ()
    assert.is.same('4', tostring(cassowary.Expression(4)))
  end)

  it('plus', function ()
    local x1 = cassowary.Variable { name = 'x', value = 167 }
    assert.same('6', tostring(cassowary.plus(4, 2)))
    assert.same('2 + 1*167', tostring(cassowary.plus(x1, 2)))
    assert.same('3 + 1*167', tostring(cassowary.plus(3, x1)))
  end)

  it('times', function ()
    local x2 = cassowary.Variable { name= 'x', value= 167 }
    assert.same('3*167', tostring(cassowary.times(x2, 3)))
    assert.same('7*167', tostring(cassowary.times(7, x2)))
  end)

  it('complex', function ()
    local x3 = cassowary.Variable { name= 'x', value= 167 }
    local y1 = cassowary.Variable { name= 'y', value= 2 }
    local ex = cassowary.plus(4, cassowary.plus(cassowary.times(x3, 3), cassowary.times(2, y1)))
    assert.same('4 + 3*167 + 2*2', tostring(ex))
  end)

  it('zero_args', function ()
    local exp1 = cassowary.Expression()
    assert.same(0, exp1.constant)
  end)

  it('one_number', function ()
    local exp2 = cassowary.Expression(10)
    assert.same(10, exp2.constant)
  end)

  it('one_variable', function ()
    local v = cassowary.Variable { value = 10 }
    local exp3 = cassowary.Expression(v)
    assert.same(0, exp3.constant)
    assert.same(1, exp3.terms[v])
  end)

  it('variable_number', function ()
    local v = cassowary.Variable({ value = 10 })
    local exp4 = cassowary.Expression(v, 20)
    assert.same(0, exp4.constant)
    assert.same(20, exp4.terms[v])
  end)

  it('variable_number_number', function ()
    local v = cassowary.Variable({ value = 10 })
    local exp = cassowary.Expression(v, 20, 2)
    assert.same(2, exp.constant)
    assert.same(20, exp.terms[v])
  end)

  it('clone', function ()
    local v = cassowary.Variable({ value = 10 })
    local exp = cassowary.Expression(v, 20, 2)
    local clone = exp:clone()

    assert.same(clone.constant, exp.constant)
    assert.same(clone.terms.size, exp.terms.size)
    assert.same(20, clone.terms[v])
  end)

  it('isConstant', function ()
    local e1 = cassowary.Expression()
    local e2 = cassowary.Expression(10)
    local e3 = cassowary.Expression(cassowary.Variable({ value = 10 }), 20, 2)

    assert.same(true, e1:isConstant())
    assert.same(true, e2:isConstant())
    assert.same(false, e3:isConstant())
  end)

  it('multiplyMe', function ()
    local v = cassowary.Variable({ value = 10 })
    local e = cassowary.Expression(v, 20, 2):multiplyMe(-1)

    assert.same(-2, e.constant)
    assert.same(10, v.value)
    assert.same(-20, e.terms[v])
  end)

  it('times', function ()
    local v = cassowary.Variable({ value = 10 })
    local a = cassowary.Expression(v, 20, 2)

    -- times a number
    local e = a:times(10)
    assert.same(20, e.constant)
    assert.same(200, e.terms[v])

    -- times a constant exression
    e = a:times(cassowary.Expression(10))
    assert.same(20, e.constant)
    assert.same(200, e.terms[v])

    -- constant expression times another expression
    e = cassowary.Expression(10):times(a)
    assert.same(20, e.constant)
    assert.same(200, e.terms[v])

    -- multiplying two non-constant expressions
    -- t.e(cassowary.NonExpression, a, 'times', [a])
    assert.has_error(function () a.times(a, a) end)
  end)

  it('addVariable', function ()
    local a = cassowary.Expression(cassowary.Variable({ value = 10 }), 20, 2)
    local v = cassowary.Variable({ value = 20 })

    -- implicit coefficient of 1
    a:addVariable(v)
    assert.same(1, a.terms[v])

    -- add again, with different coefficient
    a:addVariable(v, 2)
    assert.same(3, a.terms[v])

    -- add again, with resulting 0 coefficient. should remove the term.
    a:addVariable(v, -3)
    assert.same(nil, a.terms[v])

    -- try adding the removed term back, with 0 coefficient
    a:addVariable(v, 0)
    assert.same(nil, a.terms[v])
  end)

  it('addExpression_variable', function ()
    local a = cassowary.Expression(cassowary.Variable({ value = 10 }), 20, 2)
    local v = cassowary.Variable({ value = 20 })

    -- should work just like addVariable
    a:addExpression(v, 2)
    assert.same(2, a.terms[v])
  end)

  it('addExpression', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local vc = cassowary.Variable({ value = 5 })
    local a = cassowary.Expression(va, 20, 2)

    -- different variable and implicit coefficient of 1, should make term
    a:addExpression(cassowary.Expression(vb, 10, 5))
    assert.same(7, a.constant)
    assert.same(10, a.terms[vb])

    -- same variable, should reuse existing term
    a:addExpression(cassowary.Expression(vb, 2, 5))
    assert.same(12, a.constant)
    assert.same(12, a.terms[vb])

    -- another variable and a coefficient,
    -- should multiply the constant and all terms in the expression
    a:addExpression(cassowary.Expression(vc, 1, 2), 2)
    assert.same(16, a.constant)
    assert.same(2, a.terms[vc])
  end)

  it('plus', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)
    local b = cassowary.Expression(vb, 10, 5)

    local p = a:plus(b)
    assert.is_not.same(a, p)
    assert.is_not.same(a, b)

    assert.same(7, p.constant)
    assert.same(20, p.terms[va])
    assert.same(10, p.terms[vb])
  end)

  it('minus', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)
    local b = cassowary.Expression(vb, 10, 5)

    local p = a:minus(b)
    assert.is_not.same(a, p)
    assert.is_not.same(a, b)

    assert.same(-3, p.constant)
    assert.same(20, p.terms[va])
    assert.same(-10, p.terms[vb])
  end)

  it('divide', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)

    assert.has_error(function() a.divide(a, 0) end)
    -- t.e(cassowary.NonExpression, a, 'divide', [0])

    local p = a:divide(2)
    assert.same(1, p.constant)
    assert.same(10, p.terms[va])

    assert.has_error(function() a.divide(a, cassowary.Expression(vb, 10, 5)) end)
    -- t.e(cassowary.NonExpression, a, 'divide', [cassowary.Expression(vb, 10, 5)])
    local ne = cassowary.Expression(vb, 10, 5)
    assert.has_error(function() ne.divide(ne, a) end)

    p = a:divide(cassowary.Expression(2))
    assert.same(1, p.constant)
    assert.same(10, p.terms[va])
  end)

  it('coefficientFor', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)

    assert.same(20, a:coefficientFor(va))
    assert.same(0, a:coefficientFor(vb))
  end)

  it('setVariable', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)

    -- set existing variable
    a:setVariable(va, 2)
    assert.same(2, a:coefficientFor(va))

    -- set variable
    a:setVariable(vb, 2)
    assert.same(2, a:coefficientFor(vb))
  end)

  it('anyPivotableVariable', function ()

    -- t.e(cassowary.InternalError, cassowary.Expression(10), 'anyPivotableVariable')
    local e = cassowary.Expression(10)
    assert.has_error(function () e.anyPivotableVariable(e) end)
    -- t.e(cassowary.InternalError, cassowary.Expression(10), 'anyPivotableVariable')

    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.SlackVariable()
    local a = cassowary.Expression(va, 20, 2)

    assert.same(nil, a:anyPivotableVariable())

    a:setVariable(vb, 2)
    assert.same(vb, a:anyPivotableVariable())
  end)

  it('substituteOut', function ()
    local v1 = cassowary.Variable({ value = 20 })
    local v2 = cassowary.Variable({ value = 2 })
    local a = cassowary.Expression(v1, 2, 2); -- 2*v1 + 2

    -- variable
    a:substituteOut(v1, cassowary.Expression(v2, 4, 4))
    assert.same(10, a.constant)
    assert.same(nil, a.terms[v1])
    assert.same(8, a.terms[v2])

    -- existing variable
    a:setVariable(v1, 1)
    a:substituteOut(v2, cassowary.Expression(v1, 2, 2))

    assert.same(26, a.constant)
    assert.same(nil, a.terms[v2])
    assert.same(17, a.terms[v1])
  end)

  it('newSubject', function ()
    local v = cassowary.Variable({ value = 10 })
    local e = cassowary.Expression(v, 2, 5)

    assert.same(1 / 2, e:newSubject(v))
    assert.same(-2.5, e.constant)
    assert.same(nil, e.terms[v])
    assert.same(true, e:isConstant())
  end)

  it('changeSubject', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 5 })
    local e = cassowary.Expression(va, 2, 5)

    e:changeSubject(vb, va)
    assert.same(-2.5, e.constant)
    assert.same(nil, e.terms[va])
    assert.same(0.5, e.terms[vb])
  end)

  it('toString', function ()
    local v = cassowary.Variable({ name = 'v', value = 5 })

    assert.same('10', tostring(cassowary.Expression.fromConstant(10)))
    assert.same('10 + 0*5', tostring(cassowary.Expression(v, 0, 10)))

    local e = cassowary.Expression(v, 2, 10)
    assert.same('10 + 2*5', tostring(e))

    e:setVariable(cassowary.Variable({ name = 'b', value = 2 }), 4)
    assert.same('10 + 2*5 + 4*2', tostring(e))
  end)

  it('equals', function ()
    local v = cassowary.Variable({ name = 'v', value = 5 })

    assert.is_true(cassowary.Expression(10):equals(cassowary.Expression(10)))
    assert.is_false(cassowary.Expression(10):equals(cassowary.Expression(1)))
    assert.is_true(cassowary.Expression(v, 2, -1):equals(cassowary.Expression(v, 2, -1)))
    assert.is_false(cassowary.Expression(v, -2, 5):equals(cassowary.Expression(v, 3, 6)))
  end)

  it('plus', function ()
    local x = cassowary.Variable({ name = 'x', value = 167 })
    local y = cassowary.Variable({ name = 'y', value = 10 })

    assert.same('5', tostring(cassowary.plus(2, 3)))
    assert.same('2 + 1*167', tostring(cassowary.plus(x, 2)))
    assert.same('3 + 1*167', tostring(cassowary.plus(3, x)))
    assert.same('1*167 + 1*10', tostring(cassowary.plus(x, y)))
  end)

  it('minus', function ()
    local x = cassowary.Variable({ name = 'x', value = 167 })
    local y = cassowary.Variable({ name = 'y', value = 10 })

    assert.same('-1', tostring(cassowary.minus(2, 3)))
    assert.same('-2 + 1*167', tostring(cassowary.minus(x, 2)))
    assert.same('3 + -1*167', tostring(cassowary.minus(3, x)))
    assert.same('1*167 + -1*10', tostring(cassowary.minus(x, y)))
  end)

  it('times', function ()
    local x = cassowary.Variable({ name = 'x', value = 167 })
    local y = cassowary.Variable({ name = 'y', value = 10 })

    assert.same('6', tostring(cassowary.times(2, 3)))
    assert.same('2*167', tostring(cassowary.times(x, 2)))
    assert.same('3*167', tostring(cassowary.times(3, x)))
    assert.has_error(function () cassowary.times(cassowary, x, y) end)
  end)

  it('divide', function ()
    local x = cassowary.Variable({ name = 'x', value = 167 })
    local y = cassowary.Variable({ name = 'y', value = 10 })

    assert.same(2, tonumber(tostring(cassowary.divide(4, 2))))
    assert.same('0.5*167', tostring(cassowary.divide(x, 2)))
	assert.has_error(function () cassowary.divide(cassowary, 4, x) end)
	assert.has_error(function () cassowary.divide(cassowary, x, y) end)
  end)

end)
