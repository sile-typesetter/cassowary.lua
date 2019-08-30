local cassowary = require("cassowary")

describe('cassowary.Expression', function ()

  it('is constructable with 3 variables as arguments', function ()
    local x = cassowary.Variable { name = 'x', value = 167 }
    local e = cassowary.Expression(x, 2, 3)
    assert.is.same(tostring(e), '3 + 2*167')
  end)

  it('is constructable with one parameter', function ()
    assert.is.same(tostring(cassowary.Expression(4)), '4')
  end)

  it('plus', function ()
    local x1 = cassowary.Variable { name = 'x', value = 167 }
    assert.same(tostring(cassowary.plus(4, 2)), '6')
    assert.same(tostring(cassowary.plus(x1, 2)), '2 + 1*167')
    assert.same(tostring(cassowary.plus(3, x1)), '3 + 1*167')
  end)

  it('times', function () 
    local x2 = cassowary.Variable { name= 'x', value= 167 }
    assert.same(tostring(cassowary.times(x2, 3)), '3*167')
    assert.same(tostring(cassowary.times(7, x2)), '7*167')
  end)

  it('complex', function ()
    local x3 = cassowary.Variable { name= 'x', value= 167 }
    local y1 = cassowary.Variable { name= 'y', value= 2 }
    local ex = cassowary.plus(4, cassowary.plus(cassowary.times(x3, 3), cassowary.times(2, y1)))
    assert.same(tostring(ex), '4 + 3*167 + 2*2')
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

    assert.same(e.constant, -2)
    assert.same(v.value, 10)
    assert.same(e.terms[v], -20)
  end)

  it('times', function ()
    local v = cassowary.Variable({ value = 10 })
    local a = cassowary.Expression(v, 20, 2)

    -- times a number
    local e = a:times(10)
    assert.same(e.constant, 20)
    assert.same(e.terms[v], 200)

    -- times a constant exression
    e = a:times(cassowary.Expression(10))
    assert.same(e.constant, 20)
    assert.same(e.terms[v], 200)

    -- constant expression times another expression
    e = cassowary.Expression(10):times(a)
    assert.same(e.constant, 20)
    assert.same(e.terms[v], 200)

    -- multiplying two non-constant expressions
    -- t.e(cassowary.NonExpression, a, 'times', [a])
    assert.has_error(function () a.times(a, a) end)
  end)

  it('addVariable', function ()
    local a = cassowary.Expression(cassowary.Variable({ value = 10 }), 20, 2)
    local v = cassowary.Variable({ value = 20 })

    -- implicit coefficient of 1
    a:addVariable(v)
    assert.same(a.terms[v], 1)

    -- add again, with different coefficient
    a:addVariable(v, 2)
    assert.same(a.terms[v], 3)

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
    assert.same(a.terms[v], 2)
  end)

  it('addExpression', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local vc = cassowary.Variable({ value = 5 })
    local a = cassowary.Expression(va, 20, 2)

    -- different variable and implicit coefficient of 1, should make term
    a:addExpression(cassowary.Expression(vb, 10, 5))
    assert.same(a.constant, 7)
    assert.same(a.terms[vb], 10)

    -- same variable, should reuse existing term
    a:addExpression(cassowary.Expression(vb, 2, 5))
    assert.same(a.constant, 12)
    assert.same(a.terms[vb], 12)

    -- another variable and a coefficient,
    -- should multiply the constant and all terms in the expression
    a:addExpression(cassowary.Expression(vc, 1, 2), 2)
    assert.same(a.constant, 16)
    assert.same(a.terms[vc], 2)
  end)

  it('plus', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)
    local b = cassowary.Expression(vb, 10, 5)

    local p = a:plus(b)
    assert.is_not.same(a, p)
    assert.is_not.same(a, b)

    assert.same(p.constant, 7)
    assert.same(p.terms[va], 20)
    assert.same(p.terms[vb], 10)
  end)

  it('minus', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)
    local b = cassowary.Expression(vb, 10, 5)

    local p = a:minus(b)
    assert.is_not.same(a, p)
    assert.is_not.same(a, b)

    assert.same(p.constant, -3)
    assert.same(p.terms[va], 20)
    assert.same(p.terms[vb], -10)
  end)

  it('divide', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)

    assert.has_error(function() a.divide(a, 0) end)
    -- t.e(cassowary.NonExpression, a, 'divide', [0])

    local p = a:divide(2)
    assert.same(p.constant, 1)
    assert.same(p.terms[va], 10)

    assert.has_error(function() a.divide(a, cassowary.Expression(vb, 10, 5)) end)
    -- t.e(cassowary.NonExpression, a, 'divide', [cassowary.Expression(vb, 10, 5)])
    local ne = cassowary.Expression(vb, 10, 5)
    assert.has_error(function() ne.divide(ne, a) end)

    p = a:divide(cassowary.Expression(2))
    assert.same(p.constant, 1)
    assert.same(p.terms[va], 10)
  end)

  it('coefficientFor', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)

    assert.same(a:coefficientFor(va), 20)
    assert.same(a:coefficientFor(vb), 0)
  end)

  it('setVariable', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 20 })
    local a = cassowary.Expression(va, 20, 2)

    -- set existing variable
    a:setVariable(va, 2)
    assert.same(a:coefficientFor(va), 2)

    -- set variable
    a:setVariable(vb, 2)
    assert.same(a:coefficientFor(vb), 2)
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
    assert.same(a.constant, 10)
    assert.same(nil, a.terms[v1])
    assert.same(a.terms[v2], 8)

    -- existing variable
    a:setVariable(v1, 1)
    a:substituteOut(v2, cassowary.Expression(v1, 2, 2))

    assert.same(a.constant, 26)
    assert.same(null, a.terms[v2])
    assert.same(a.terms[v1], 17)
  end)

  it('newSubject', function ()
    local v = cassowary.Variable({ value = 10 })
    local e = cassowary.Expression(v, 2, 5)

    assert.same(e:newSubject(v), 1 / 2)
    assert.same(e.constant, -2.5)
    assert.same(null, e.terms[v])
    assert.same(true, e:isConstant())
  end)

  it('changeSubject', function ()
    local va = cassowary.Variable({ value = 10 })
    local vb = cassowary.Variable({ value = 5 })
    local e = cassowary.Expression(va, 2, 5)

    e:changeSubject(vb, va)
    assert.same(e.constant, -2.5)
    assert.same(null, e.terms[va])
    assert.same(e.terms[vb], 0.5)
  end)

  it('toString', function ()
    local v = cassowary.Variable({ name = 'v', value = 5 })

    assert.same(tostring(cassowary.Expression.fromConstant(10)), '10')
    assert.same(tostring(cassowary.Expression(v, 0, 10)), '10 + 0*5')

    local e = cassowary.Expression(v, 2, 10)
    assert.same(tostring(e), '10 + 2*5')

    e:setVariable(cassowary.Variable({ name = 'b', value = 2 }), 4)
    assert.same(tostring(e), '10 + 2*5 + 4*2')
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

    assert.same(tostring(cassowary.plus(2, 3)), '5')
    assert.same(tostring(cassowary.plus(x, 2)), '2 + 1*167')
    assert.same(tostring(cassowary.plus(3, x)), '3 + 1*167')
    assert.same(tostring(cassowary.plus(x, y)), '1*167 + 1*10')
  end)

  it('minus', function ()
    local x = cassowary.Variable({ name = 'x', value = 167 })
    local y = cassowary.Variable({ name = 'y', value = 10 })

    assert.same(tostring(cassowary.minus(2, 3)), '-1')
    assert.same(tostring(cassowary.minus(x, 2)), '-2 + 1*167')
    assert.same(tostring(cassowary.minus(3, x)), '3 + -1*167')
    assert.same(tostring(cassowary.minus(x, y)), '1*167 + -1*10')
  end)

  it('times', function ()
    local x = cassowary.Variable({ name = 'x', value = 167 })
    local y = cassowary.Variable({ name = 'y', value = 10 })

    assert.same(tostring(cassowary.times(2, 3)), '6')
    assert.same(tostring(cassowary.times(x, 2)), '2*167')
    assert.same(tostring(cassowary.times(3, x)), '3*167')
    assert.has_error(function () cassowary.times(cassowary, x, y) end)
  end)

  it('divide', function ()
    local x = cassowary.Variable({ name = 'x', value = 167 })
    local y = cassowary.Variable({ name = 'y', value = 10 })

    assert.same(tonumber(tostring(cassowary.divide(4, 2))), 2)
    assert.same(tostring(cassowary.divide(x, 2)), '0.5*167')
    --assert.has_error(function () cassowary.divide(cassowary, 4, x) end)
    --assert.has_error(function () cassowary.divide(cassowary, x, y) end)
  end)

end)
