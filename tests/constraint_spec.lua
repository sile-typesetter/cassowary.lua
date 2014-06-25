c = require("cassowary")
assert = require("luassert")
	-- describe('c.Constraint', function ()
		it('should create expression equations', function ()
			local ex = c.Expression(10);
			local c1 = c.Equation(ex);
			assert.same(c1.expression, ex);
		end)

		it('can create expressions c.Variable instances', function ()
			local x = c.Variable({ value = 167 });
			local y = c.Variable({ value = 2 });
			local cly = c.Expression(y);
			cly:addExpression(x);
		end)

		it('can create equations from variables and expressions', function ()
			local x = c.Variable({ name = 'x', value = 167 });
			local cly = c.Expression(2);
			local eq = c.Equation(x, cly);
			assert.is.truthy(eq.expression:equals(cly:minus(x)));
		end)

		-- it('should handle strengths correctly', function ()
		-- 	local solver = c.SimplexSolver();
		-- 	local x = c.Variable({ name = 'x', value = 10 });
		-- 	local y = c.Variable({ name = 'y', value = 20 });
		-- 	local z = c.Variable({ name = 'z', value = 1 });
		-- 	local w = c.Variable({ name = 'w', value = 1 });

		--     -- Default weights.
		--     local e0 = c.Equation(x, y);
		--     solver.addStay(y);
		--     solver.addConstraint(e0);
		--     assert.isTrue(c.approx(x, 20));
		--     assert.isTrue(c.approx(y, 20));

		--     -- Weak.
		--     local e1 = c.Equation(x, z, c.Strength.weak);
		--     -- console.log('x:', x.value);
		--     -- c.trace = true;
		--     solver.addStay(x);
		--     solver.addConstraint(e1);
		--     assert.isTrue(c.approx(x, 20));
		--     assert.isTrue(c.approx(z, 20));

		--     -- Strong.
		--     local e2 = c.Equation(z, w, c.Strength.strong);
		--     solver.addStay(w);
		--     solver.addConstraint(e2);
		--     assert.deepEqual(w.value, 1);
		--     assert.deepEqual(z.value, 1);
		-- end)

		it('can use numbers in place of variables', function ()
			local v = c.Variable({ name = 'v', value = 22 });
			local eq = c.Equation(v, 5);
			assert.is.truthy(eq.expression:equals(c.minus(5, v)));
		end)

		it('can use equations in place of variables', function ()
			local e = c.Expression(10);
			local v = c.Variable({ name = 'v', value = 22 });
			local eq = c.Equation(e, v);

			assert.is.truthy(eq.expression:equals(c.minus(10, v)));
		end)

		it('works with nested expressions', function ()

			local e1 = c.Expression(10);
			local e2 = c.Expression(c.Variable({ name = 'z', value = 10 }), 2, 4);
			local eq = c.Equation(e1, e2);
			assert.is.truthy(eq.expression:equals(e1:minus(e2)));
		end)

		it('instantiates inequality expressions correctly', function ()
			local e = c.Expression(10);
			local ieq = c.Inequality(e);
			assert.is.same(ieq.expression, e);
		end)

		it('handles inequality constructors with operator arguments', function ()
			local v1 = c.Variable({ name = 'v1', value = 10 });
			local v2 = c.Variable({ name = 'v2', value = 5 });
			local ieq = c.Inequality(v1, ">=", v2);

			assert.is.truthy(ieq.expression:equals(c.minus(v1, v2)));

			ieq = c.Inequality(v1, "<=", v2);
			assert.is.truthy(ieq.expression:equals(c.minus(v2, v1)));
		end)

		it('handles expressions with variables, operators, and numbers', function ()
			local v = c.Variable({ name = 'v', value = 10 });
			local ieq = c.Inequality(v, ">=", 5);

			assert.is.truthy(ieq.expression:equals(c.minus(v, 5)));

			ieq = c.Inequality(v, "<=", 5);
			assert.is.truthy(ieq.expression:equals(c.minus(5, v)));
		end)

		-- it('handles inequalities with reused variables', function ()
		-- 	local e1 = c.Expression(10);
		-- 	local e2 = c.Expression(c.Variable({ name = 'c', value = 10 }), 2, 4);
		-- 	local ieq = c.Inequality(e1, c.GEQ, e2);

		-- 	assert.isTrue(ieq.expression.equals(e1.minus(e2)));

		-- 	ieq = c.Inequality(e1, c.LEQ, e2);
		-- 	assert.isTrue(ieq.expression.equals(e2.minus(e1)));
		-- end)

		-- it('handles constructors with variable/operator/expression args', function ()
		-- 	local v = c.Variable({ name = 'v', value = 10 });
		-- 	local e = c.Expression(c.Variable({ name = 'x', value = 5 }), 2, 4);
		-- 	local ieq = c.Inequality(v, c.GEQ, e);

		-- 	assert.isTrue(ieq.expression.equals(c.minus(v, e)));

		-- 	ieq = c.Inequality(v, c.LEQ, e);
		-- 	assert.isTrue(ieq.expression.equals(e.minus(v)));
		-- end)

		-- it('handles constructors with expression/operator/variable args', function ()
		-- 	local v = c.Variable({ name = 'v', value = 10 });
		-- 	local e = c.Expression(c.Variable({ name = 'x', value = 5 }), 2, 4);
		-- 	local ieq = c.Inequality(e, c.GEQ, v);

		-- 	assert.isTrue(ieq.expression.equals(e.minus(v)));

		-- 	ieq = c.Inequality(e, c.LEQ, v);
		-- 	assert.isTrue(ieq.expression.equals(c.minus(v, e)));
		-- end)

	-- end)

