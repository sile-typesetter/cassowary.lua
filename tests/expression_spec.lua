c = require("cassowary")
assert = require("luassert")

	describe('c.Expression', function ()
		it('is constructable with 3 variables as arguments', function ()
			local x = c.Variable { name = 'x', value = 167 }
			local e = c.Expression(x, 2, 3);
			assert.is.same(tostring(e), '3 + 2*167');
		end)
	end)

		it('is constructable with one parameter', function ()
			assert.is.same(tostring(c.Expression(4)), '4');
		end);

		it('plus', function ()
			local x1 = c.Variable { name = 'x', value = 167 }
			assert.same(tostring(c.plus(4, 2)), '6');
			assert.same(tostring(c.plus(x1, 2)), '2 + 1*167');
			assert.same(tostring(c.plus(3, x1)), '3 + 1*167');
		end);

		it('times', function () 
			local x2 = c.Variable { name= 'x', value= 167 };
			assert.same(tostring(c.times(x2, 3)), '3*167');
			assert.same(tostring(c.times(7, x2)), '7*167');
		end);

		it('complex', function ()
			local x3 = c.Variable { name= 'x', value= 167 };
			local y1 = c.Variable { name= 'y', value= 2 };
			local ex = c.plus(4, c.plus(c.times(x3, 3), c.times(2, y1)));
			assert.same(tostring(ex), '4 + 3*167 + 2*2');
		end);

		it('zero_args', function ()
			local exp1 = c.Expression();
			assert.same(0, exp1.constant);
		end);

		it('one_number', function ()
			local exp2 = c.Expression(10);
			assert.same(10, exp2.constant);
		end);

		it('one_variable', function ()
			local v = c.Variable { value = 10 };
			local exp3 = c.Expression(v);
			assert.same(0, exp3.constant);
			assert.same(1, exp3.terms[v]);
		end);

		it('variable_number', function ()
			local v = c.Variable({ value = 10 })
			local exp4 = c.Expression(v, 20);
			assert.same(0, exp4.constant);
			assert.same(20, exp4.terms[v]);
		end);

		it('variable_number_number', function ()
			local v = c.Variable({ value = 10 })
			local exp = c.Expression(v, 20, 2);
			assert.same(2, exp.constant);
			assert.same(20, exp.terms[v]);
		end);

		it('clone', function ()
			local v = c.Variable({ value = 10 })
			local exp = c.Expression(v, 20, 2);
			local clone = exp:clone();

			assert.same(clone.constant, exp.constant);
			assert.same(clone.terms.size, exp.terms.size);
			assert.same(20, clone.terms[v]);
		end);

		it('isConstant', function ()
			local e1 = c.Expression();
			local e2 = c.Expression(10);
			local e3 = c.Expression(c.Variable({ value = 10 }), 20, 2);

			assert.same(true, e1:isConstant());
			assert.same(true, e2:isConstant());
			assert.same(false, e3:isConstant());
		end);

		it('multiplyMe', function ()
			local v = c.Variable({ value = 10 })
			local e = c.Expression(v, 20, 2):multiplyMe(-1);

			assert.same(e.constant, -2);
			assert.same(v.value, 10);
			assert.same(e.terms[v], -20);
		end);

		it('times', function ()
			local v = c.Variable({ value = 10 })
			local a = c.Expression(v, 20, 2);

			-- times a number
			local e = a:times(10);
			assert.same(e.constant, 20);
			assert.same(e.terms[v], 200);

			-- times a constant exression
			e = a:times(c.Expression(10));
			assert.same(e.constant, 20);
			assert.same(e.terms[v], 200);

			-- constant expression times another expression
			e = c.Expression(10):times(a);
			assert.same(e.constant, 20);
			assert.same(e.terms[v], 200);

			-- multiplying two non-constant expressions
			-- t.e(c.NonExpression, a, 'times', [a]);
			assert.has_error(function () a.times(a, a) end);
		end);

		it('addVariable', function ()
			local a = c.Expression(c.Variable({ value = 10 }), 20, 2);
			local v = c.Variable({ value = 20 })

			-- implicit coefficient of 1
			a:addVariable(v);
			assert.same(a.terms[v], 1);

			-- add again, with different coefficient
			a:addVariable(v, 2);
			assert.same(a.terms[v], 3);

			-- add again, with resulting 0 coefficient. should remove the term.
			a:addVariable(v, -3);
			assert.same(nil, a.terms[v]);

			-- try adding the removed term back, with 0 coefficient
			a:addVariable(v, 0);
			assert.same(nil, a.terms[v]);
		end);

		it('addExpression_variable', function ()
			local a = c.Expression(c.Variable({ value = 10 }), 20, 2);
			local v = c.Variable({ value = 20 })

			-- should work just like addVariable
			a:addExpression(v, 2);
			assert.same(a.terms[v], 2);
		end);

		it('addExpression', function ()
			local va = c.Variable({ value = 10 })
			local vb = c.Variable({ value = 20 })
			local vc = c.Variable({ value = 5 })
			local a = c.Expression(va, 20, 2);

			-- different variable and implicit coefficient of 1, should make term
			a:addExpression(c.Expression(vb, 10, 5));
			assert.same(a.constant, 7);
			assert.same(a.terms[vb], 10);

			-- same variable, should reuse existing term
			a:addExpression(c.Expression(vb, 2, 5));
			assert.same(a.constant, 12);
			assert.same(a.terms[vb], 12);

			-- another variable and a coefficient,
			-- should multiply the constant and all terms in the expression
			a:addExpression(c.Expression(vc, 1, 2), 2);
			assert.same(a.constant, 16);
			assert.same(a.terms[vc], 2);
		end);

		it('plus', function ()
			local va = c.Variable({ value = 10 })
			local vb = c.Variable({ value = 20 })
			local a = c.Expression(va, 20, 2);
			local b = c.Expression(vb, 10, 5);

			local p = a:plus(b);
			assert.is_not.same(a, p);
			assert.is_not.same(a, b);

			assert.same(p.constant, 7);
			assert.same(p.terms[va], 20);
			assert.same(p.terms[vb], 10);
		end);

		it('minus', function ()
			local va = c.Variable({ value = 10 })
			local vb = c.Variable({ value = 20 })
			local a = c.Expression(va, 20, 2);
			local b = c.Expression(vb, 10, 5);

			local p = a:minus(b);
			assert.is_not.same(a, p);
			assert.is_not.same(a, b);

			assert.same(p.constant, -3);
			assert.same(p.terms[va], 20);
			assert.same(p.terms[vb], -10);
		end);

		it('divide', function ()
			local va = c.Variable({ value = 10 })
			local vb = c.Variable({ value = 20 })
			local a = c.Expression(va, 20, 2);

			assert.has_error(function() a.divide(a, 0) end);
			-- t.e(c.NonExpression, a, 'divide', [0]);

			local p = a:divide(2);
			assert.same(p.constant, 1);
			assert.same(p.terms[va], 10);

			assert.has_error(function() a.divide(a, c.Expression(vb, 10, 5)) end)
			-- t.e(c.NonExpression, a, 'divide', [c.Expression(vb, 10, 5)]);
			local ne = c.Expression(vb, 10, 5);
			assert.has_error(function() ne.divide(ne, a) end);

			p = a:divide(c.Expression(2));
			assert.same(p.constant, 1);
			assert.same(p.terms[va], 10);
		end);

		it('coefficientFor', function ()
			local va = c.Variable({ value = 10 })
			local vb = c.Variable({ value = 20 })
			local a = c.Expression(va, 20, 2);

			assert.same(a:coefficientFor(va), 20);
			assert.same(a:coefficientFor(vb), 0);
		end);

		it('setVariable', function ()
			local va = c.Variable({ value = 10 })
			local vb = c.Variable({ value = 20 })
			local a = c.Expression(va, 20, 2);

			-- set existing variable
			a:setVariable(va, 2);
			assert.same(a:coefficientFor(va), 2);

			-- set variable
			a:setVariable(vb, 2);
			assert.same(a:coefficientFor(vb), 2);
		end);

		it('anyPivotableVariable', function ()

			-- t.e(c.InternalError, c.Expression(10), 'anyPivotableVariable');
			local e = c.Expression(10);
			assert.has_error(function () e.anyPivotableVariable(e) end);
			-- t.e(c.InternalError, c.Expression(10), 'anyPivotableVariable');

			local va = c.Variable({ value = 10 })
			local vb = c.SlackVariable();
			local a = c.Expression(va, 20, 2);

			assert.same(nil, a:anyPivotableVariable());

			a:setVariable(vb, 2);
			assert.same(vb, a:anyPivotableVariable());
		end);

		it('substituteOut', function ()
			local v1 = c.Variable({ value = 20 })
			local v2 = c.Variable({ value = 2 })
			local a = c.Expression(v1, 2, 2); -- 2*v1 + 2

			-- variable
			a:substituteOut(v1, c.Expression(v2, 4, 4));
			assert.same(a.constant, 10);
			assert.same(nil, a.terms[v1]);
			assert.same(a.terms[v2], 8);

			-- existing variable
			a:setVariable(v1, 1);
			a:substituteOut(v2, c.Expression(v1, 2, 2));

			assert.same(a.constant, 26);
			assert.same(null, a.terms[v2]);
			assert.same(a.terms[v1], 17);
		end);

		it('newSubject', function ()
			local v = c.Variable({ value = 10 })
			local e = c.Expression(v, 2, 5);

			assert.same(e:newSubject(v), 1 / 2);
			assert.same(e.constant, -2.5);
			assert.same(null, e.terms[v]);
			assert.same(true, e:isConstant());
		end);

		it('changeSubject', function ()
			local va = c.Variable({ value = 10 })
			local vb = c.Variable({ value = 5 })
			local e = c.Expression(va, 2, 5);

			e:changeSubject(vb, va);
			assert.same(e.constant, -2.5);
			assert.same(null, e.terms[va]);
			assert.same(e.terms[vb], 0.5);
		end);

		it('toString', function ()
			local v = c.Variable({ name = 'v', value = 5 })

			assert.same(tostring(c.Expression.fromConstant(10)), '10');
			assert.same(tostring(c.Expression(v, 0, 10)), '10 + 0*5');

			local e = c.Expression(v, 2, 10);
			assert.same(tostring(e), '10 + 2*5');

			e:setVariable(c.Variable({ name = 'b', value = 2 }), 4);
			assert.same(tostring(e), '10 + 2*5 + 4*2');
		end);

		it('equals', function ()
			local v = c.Variable({ name = 'v', value = 5 })

			assert.is_true(c.Expression(10):equals(c.Expression(10)));
			assert.is_false(c.Expression(10):equals(c.Expression(1)));
			assert.is_true(c.Expression(v, 2, -1):equals(c.Expression(v, 2, -1)));
			assert.is_false(c.Expression(v, -2, 5):equals(c.Expression(v, 3, 6)));
		end);

		it('plus', function ()
			local x = c.Variable({ name = 'x', value = 167 })
			local y = c.Variable({ name = 'y', value = 10 })

			assert.same(tostring(c.plus(2, 3)), '5');
			assert.same(tostring(c.plus(x, 2)), '2 + 1*167');
			assert.same(tostring(c.plus(3, x)), '3 + 1*167');
			assert.same(tostring(c.plus(x, y)), '1*167 + 1*10');
		end);

		it('minus', function ()
			local x = c.Variable({ name = 'x', value = 167 })
			local y = c.Variable({ name = 'y', value = 10 })

			assert.same(tostring(c.minus(2, 3)), '-1');
			assert.same(tostring(c.minus(x, 2)), '-2 + 1*167');
			assert.same(tostring(c.minus(3, x)), '3 + -1*167');
			assert.same(tostring(c.minus(x, y)), '1*167 + -1*10');
		end);

		it('times', function ()
			local x = c.Variable({ name = 'x', value = 167 })
			local y = c.Variable({ name = 'y', value = 10 })

			assert.same(tostring(c.times(2, 3)), '6');
			assert.same(tostring(c.times(x, 2)), '2*167');
			assert.same(tostring(c.times(3, x)), '3*167');
			assert.has_error(function () c.times(c, x, y) end);
		end);

		it('divide', function ()
			local x = c.Variable({ name = 'x', value = 167 })
			local y = c.Variable({ name = 'y', value = 10 })

			assert.same(tostring(c.divide(4, 2)), '2');
			assert.same(tostring(c.divide(x, 2)), '0.5*167');
			assert.has_error(function () c.divide(c, 4, x) end);
			assert.has_error(function () c.divide(c, x, y) end);
		end);
-- 	end);
-- })