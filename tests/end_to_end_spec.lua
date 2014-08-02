c = require("cassowary")
assert = require("luassert")

	describe('End-To-End', function () 

		it('simple1', function ()
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 167 });
			local y = c.Variable({ value = 2 });
			local eq = c.Equation(x, c.Expression(y));

			solver:addConstraint(eq);
			assert.equal(x.value, y.value);
			assert.equal(x.value, 0);
			assert.equal(y.value, 0);
		end);

		it('justStay1', function ()
			local x = c.Variable({ value = 5 });
			local y = c.Variable({ value = 10 });
			local solver = c.SimplexSolver();
			solver:addStay(x);
			solver:addStay(y);
			assert.is.truthy(c.approx(x, 5));
			assert.is.truthy(c.approx(y, 10));
			assert.is.same(x.value, 5);
			assert.is.same(y.value, 10);
		end);

		it('local >= num', function ()
			-- x >= 100
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 10 });
			local ieq = c.Inequality(x, ">=", 100);
			solver:addConstraint(ieq);
			assert.is.same(x.value, 100);
		end)

		it('num == var', function ()
			-- 100 == var
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 10 });
			local eq = c.Equation(100, x);
			solver:addConstraint(eq);
			assert.is.same(x.value, 100);
		end);

		it('num <= var', function ()
			-- x >= 100
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 10 });
			local ieq = c.Inequality(100, "<=", x);
			solver:addConstraint(ieq);

			assert.is.same(x.value, 100);
		end);

		it('exp >= num', function ()
			-- stay width
			-- right >= 100
			local solver = c.SimplexSolver();

			-- x = 10
			local x = c.Variable({ value = 10 });
			-- width = 10
			local width = c.Variable({ value = 10 });
			-- right = x + width
			local right = c.Expression(x):plus(width);
			-- right >= 100
			local ieq = c.Inequality(right, ">=", 100);
			solver:addStay(width);
			solver:addConstraint(ieq);

			assert.is.same(x.value, 90);
			assert.is.same(width.value, 10);
		end);

		it('num <= exp', function ()
			-- stay width
			-- 100 <= right
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 10 });
			local width = c.Variable({ value = 10 });
			local right = c.Expression(x):plus(width);
			local ieq = c.Inequality(100, "<=", right);

			solver:addStay(width):addConstraint(ieq);

			assert.is.same(x.value, 90);
			assert.is.same(width.value, 10);
		end);

		it('exp == var', function ()
			-- stay width, rightMin
			-- right >= rightMin
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 10 });
			local width = c.Variable({ value = 10 });
			local rightMin = c.Variable({ value = 100 });
			local right = c.Expression(x):plus(width);
			local eq = c.Equation(right, rightMin);

			solver:addStay(width) :addStay(rightMin) :addConstraint(eq);

			assert.is.same(x.value, 90);
			assert.is.same(width.value, 10);
		end);

		it('exp >= var', function ()
			-- stay width, rightMin
			-- right >= rightMin
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 10 });
			local width = c.Variable({ value = 10 });
			local rightMin = c.Variable({ value = 100 });
			local right = c.Expression(x):plus(width);
			local ieq = c.Inequality(right, ">=", rightMin);

			solver:addStay(width) :addStay(rightMin) :addConstraint(ieq);

			assert.is.same(x.value, 90);
			assert.is.same(width.value, 10);
		end);

		it('local <= exp', function ()
			-- stay width
			-- right >= rightMin
			local solver = c.SimplexSolver();

			local x = c.Variable({ value = 10 });
			local width = c.Variable({ value = 10 });
			local rightMin = c.Variable({ value = 100 });
			local right = c.Expression(x):plus(width);
			local ieq = c.Inequality(rightMin, "<=", right);
			solver:addStay(width):addStay(rightMin):addConstraint(ieq);

			assert.is.same(x.value, 90);
			assert.is.same(width.value, 10);
		end);

		it('exp == exp', function ()
			-- stay width, rightMin
			-- right >= rightMin
			local solver = c.SimplexSolver();

			local x1 = c.Variable({ value = 10 });
			local width1 = c.Variable({ value = 10 });
			local right1 = c.Expression(x1):plus(width1);
			local x2 = c.Variable({ value = 100 });
			local width2 = c.Variable({ value = 10 });
			local right2 = c.Expression(x2):plus(width2);

			local eq = c.Equation(right1, right2);

			solver:addStay(width1) :addStay(width2) :addStay(x2) :addConstraint(eq);

			assert.is.same(x1.value, 100);
			assert.is.same(x2.value, 100);
			assert.is.same(width1.value, 10);
			assert.is.same(width2.value, 10);
		end);

		it('exp >= exp', function ()
			-- stay width, rightMin
			-- right >= rightMin
			local solver = c.SimplexSolver();

			local x1 = c.Variable({ value = 10 });
			local width1 = c.Variable({ value = 10 });
			local right1 = c.Expression(x1):plus(width1);
			local x2 = c.Variable({ value = 100 });
			local width2 = c.Variable({ value = 10 });
			local right2 = c.Expression(x2):plus(width2);

			local ieq = c.Inequality(right1, ">=", right2);

			solver:addStay(width1) :addStay(width2) :addStay(x2) :addConstraint(ieq);

			assert.is.same(x1.value, 100);
		end);

		it('exp <= exp', function ()
			-- stay width, rightMin
			-- right >= rightMin
			local solver = c.SimplexSolver();

			local x1 = c.Variable({ value = 10 });
			local width1 = c.Variable({ value = 10 });
			local right1 = c.Expression(x1):plus(width1);
			local x2 = c.Variable({ value = 100 });
			local width2 = c.Variable({ value = 10 });
			local right2 = c.Expression(x2):plus(width2);
			local ieq = c.Inequality(right2, "<=", right1);

			solver:addStay(width1)
				:addStay(width2)
				:addStay(x2)
				:addConstraint(ieq);

			assert.is.same(x1.value, 100);
		end);

		it('addDelete1', function ()
			local solver = c.SimplexSolver();
			local x = c.Variable({ name= 'x' });
			local cbl = c.Equation(x, 100, c.Strength.weak);
			solver:addConstraint(cbl);
			local c10 = c.Inequality(x, "<=", 10);
			local c20 = c.Inequality(x, "<=", 20);
			solver:addConstraint(c10):addConstraint(c20);
			assert.is.truthy(c.approx(x, 10));

			solver:removeConstraint(c10);
			assert.is.truthy(c.approx(x, 20));

			solver:removeConstraint(c20);
			assert.is.truthy(c.approx(x, 100));

			local c10again = c.Inequality(x, "<=", 10);
			solver:addConstraint(c10)
			:addConstraint(c10again);
			assert.is.truthy(c.approx(x, 10));

			solver:removeConstraint(c10);
			assert.is.truthy(c.approx(x, 10));

			solver:removeConstraint(c10again);
			assert.is.truthy(c.approx(x, 100));
		end);

		it('addDelete2', function ()
			local solver = c.SimplexSolver();
			local x = c.Variable({ name = 'x' });
			local y = c.Variable({ name = 'y' });

			solver:addConstraint(c.Equation(x, 100, c.Strength.weak))
			:addConstraint(c.Equation(y, 120, c.Strength.strong));
			local c10 = c.Inequality(x, "<=", 10);
			local c20 = c.Inequality(x, "<=", 20);
			solver:addConstraint(c10)
			:addConstraint(c20);
			assert.is.truthy(c.approx(x, 10));
			assert.is.truthy(c.approx(y, 120));

			solver:removeConstraint(c10);
			assert.is.truthy(c.approx(x, 20));
			assert.is.truthy(c.approx(y, 120));

			local cxy = c.Equation(c.times(2, x), y);
			solver:addConstraint(cxy);
			assert.is.truthy(c.approx(x, 20));
			assert.is.truthy(c.approx(y, 40));

			solver:removeConstraint(c20);
			assert.is.truthy(c.approx(x, 60));
			assert.is.truthy(c.approx(y, 120));

			solver:removeConstraint(cxy);
			assert.is.truthy(c.approx(x, 100));
			assert.is.truthy(c.approx(y, 120));
		end);

		it('casso1', function ()
			local solver = c.SimplexSolver();
			local x = c.Variable({ name = 'x' });
			local y = c.Variable({ name = 'y' });

			solver:addConstraint(c.Inequality(x, "<=", y))
			:addConstraint(c.Equation(y, c.plus(x, 3)))
			:addConstraint(c.Equation(x, 10, c.Strength.weak))
			:addConstraint(c.Equation(y, 10, c.Strength.weak));

			assert.is.truthy(
				(c.approx(x, 10) and c.approx(y, 13)) or
				(c.approx(x,  7) and c.approx(y, 10))
				);
		end);

		it('inconsistent1', function ()
			local solver = c.SimplexSolver();
			local x = c.Variable({ name = 'x' });
			-- x = 10
			solver:addConstraint(c.Equation(x, 10));
			-- x = 5
			assert.has.errors(function () solver:addConstraint(c.Equation(x, 5)) end);
		end);

		it('inconsistent2', function ()
			local solver = c.SimplexSolver();
			local x = c.Variable({ name = 'x' });
			solver:addConstraint(c.Inequality(x, ">=", 10));
			assert.has.errors(function()
				solver:addConstraint(c.Inequality(x, "<=", 5)) 
				end);
		end);

		it('inconsistent3', function ()
			local solver = c.SimplexSolver();
			local w = c.Variable({ name = 'w' });
			local x = c.Variable({ name = 'x' });
			local y = c.Variable({ name = 'y' });
			local z = c.Variable({ name = 'z' });
			solver:addConstraint(c.Inequality(w, ">=", 10))
			:addConstraint(c.Inequality(x, ">=", w))
			:addConstraint(c.Inequality(y, ">=", x))
			:addConstraint(c.Inequality(z, ">=", y))
			:addConstraint(c.Inequality(z, ">=", 8));

			assert.has.errors(function()
				solver:addConstraint(c.Inequality(z, "<=", 4))
				end);
		end);

		it('inconsistent4', function ()
			local solver = c.SimplexSolver();
			local x = c.Variable({ name = 'x' });
			local y = c.Variable({ name = 'y' });
			-- x = 10
			solver:addConstraint(c.Equation(x, 10));
			-- x = y
			solver:addConstraint(c.Equation(x, y));
			-- y = 5. Should fail.
			assert.has.errors(function()
				solver:addConstraint(c.Equation(y, 5))
				end)
		end);

		it('multiedit', function ()
			-- This test stresses the edit session stack. beginEdit() starts a new
			-- "edit variable group" and "endEdit" closes it, leaving only the
			-- previously opened edit variables still active.
			local x = c.Variable({ name = 'x' });
			local y = c.Variable({ name = 'y' });
			local w = c.Variable({ name = 'w' });
			local h = c.Variable({ name = 'h' });
			local solver = c.SimplexSolver();
			-- Add some stays and start an editing session
			solver:addStay(x)
						:addStay(y)
						:addStay(w)
						:addStay(h)
						:addEditVar(x)
						:addEditVar(y):beginEdit();
			solver:suggestValue(x, 10)
						:suggestValue(y, 20):resolve();
			assert.is.truthy(c.approx(x, 10));
			assert.is.truthy(c.approx(y, 20));
			assert.is.truthy(c.approx(w, 0));
			assert.is.truthy(c.approx(h, 0));

			-- Open a second set of variables for editing
			solver:addEditVar(w)
						:addEditVar(h):beginEdit();
			solver:suggestValue(w, 30)
						:suggestValue(h, 40)
			solver:endEdit();
			-- Close the second set...
			assert.is.truthy(c.approx(x, 10));
			assert.is.truthy(c.approx(y, 20));
			assert.is.truthy(c.approx(w, 30));
			assert.is.truthy(c.approx(h, 40));

			-- Now make sure the first set can still be edited
			solver:suggestValue(x, 50)
						:suggestValue(y, 60):endEdit();
			assert.is.truthy(c.approx(x, 50));
			assert.is.truthy(c.approx(y, 60));
			assert.is.truthy(c.approx(w, 30));
			assert.is.truthy(c.approx(h, 40));
		end);

		it('multiedit2', function ()
			local x = c.Variable({ name= 'x' });
			local y = c.Variable({ name= 'y' });
			local w = c.Variable({ name= 'w' });
			local h = c.Variable({ name= 'h' });
			local solver = c.SimplexSolver();
			solver:addStay(x)
			:addStay(y)
			:addStay(w)
			:addStay(h)
			:addEditVar(x)
			:addEditVar(y):beginEdit();
			solver:suggestValue(x, 10)
			:suggestValue(y, 20):resolve();
			solver:endEdit();
			assert.is.truthy(c.approx(x, 10));
			assert.is.truthy(c.approx(y, 20));
			assert.is.truthy(c.approx(w, 0));
			assert.is.truthy(c.approx(h, 0));

			solver:addEditVar(w)
			:addEditVar(h):beginEdit();
			solver:suggestValue(w, 30)
			:suggestValue(h, 40):endEdit();
			assert.is.truthy(c.approx(x, 10));
			assert.is.truthy(c.approx(y, 20));
			assert.is.truthy(c.approx(w, 30));
			assert.is.truthy(c.approx(h, 40));

			solver:addEditVar(x)
			:addEditVar(y):beginEdit();
			solver:suggestValue(x, 50)
			:suggestValue(y, 60):endEdit();
			assert.is.truthy(c.approx(x, 50));
			assert.is.truthy(c.approx(y, 60));
			assert.is.truthy(c.approx(w, 30));
			assert.is.truthy(c.approx(h, 40));
		end);

		-- it('multiedit3', function ()
		-- 	local rand = function (max, min) {
		-- 		min = (typeof min !== 'undefined') ? min : 0;
		-- 		max = max || Math.pow(2, 26);
		-- 		return parseInt(Math.random() * (max - min), 10) + min;
		-- 	};
		-- 	local MAX = 500;
		-- 	local MIN = 100;

		-- 	local weak = c.Strength.weak;
		-- 	local medium = c.Strength.medium;
		-- 	local strong = c.Strength.strong;

		-- 	local eq  = function (a1, a2, strength, w) {
		-- 		return c.Equation(a1, a2, strength || weak, w || 0);
		-- 	};

		-- 	local v = {
		-- 		width: c.Variable({ name: 'width' }),
		-- 		height: c.Variable({ name: 'height' }),
		-- 		top: c.Variable({ name: 'top' }),
		-- 		bottom: c.Variable({ name: 'bottom' }),
		-- 		left: c.Variable({ name: 'left' }),
		-- 		right: c.Variable({ name: 'right' }),
		-- 	};

		-- 	local solver = c.SimplexSolver();

		-- 	local iw = c.Variable({
		-- 		name: 'window_innerWidth',
		-- 		value = rand(MAX, MIN)
		-- 	});
		-- 	local ih = c.Variable({
		-- 		name: 'window_innerHeight',
		-- 		value = rand(MAX, MIN)
		-- 	});
		-- 	local iwStay = c.StayConstraint(iw);
		-- 	local ihStay = c.StayConstraint(ih);

		-- 	local widthEQ = eq(v.width, iw, strong);
		-- 	local heightEQ = eq(v.height, ih, strong);

		-- 	[
		-- 		widthEQ,
		-- 		heightEQ,
		-- 		eq(v.top, 0, weak),
		-- 		eq(v.left, 0, weak),
		-- 		eq(v.bottom, c:plus(v.top, v.height), medium),
		-- 		-- Right is at least left + width
		-- 		eq(v.right,  c:plus(v.left, v.width), medium),
		-- 		iwStay,
		-- 		ihStay
		-- 	].forEach(function (c) {
		-- 		solver:addConstraint(c);
		-- 	});

		-- 	-- Propigate viewport size changes.
		-- 	local reCalc = function ()

		-- 		-- Measurement should be cheap here.
		-- 		local iwv = rand(MAX, MIN);
		-- 		local ihv = rand(MAX, MIN);

		-- 		solver:addEditVar(iw);
		-- 		solver:addEditVar(ih);

		-- 		solver:beginEdit();
		-- 		solver:suggestValue(iw, iwv)
		-- 		.suggestValue(ih, ihv);
		-- 		solver:resolve();
		-- 		solver:endEdit();

		-- 		assert.is.same(v.top.value, 0);
		-- 		assert.is.same(v.left.value, 0);
		-- 		assert.is.truthy(v.bottom.value <= MAX);
		-- 		assert.is.truthy(v.bottom.value >= MIN);
		-- 		assert.is.truthy(v.right.value <= MAX);
		-- 		assert.is.truthy(v.right.value >= MIN);

		-- 	}.bind(this);

		-- 	reCalc();
		-- 	reCalc();
		-- 	reCalc();
		-- });

		it('errorWeights', function ()
			local solver = c.SimplexSolver();

			local weak = c.Strength.weak;
			local medium = c.Strength.medium;
			local strong = c.Strength.strong;

			local x = c.Variable({ name = 'x', value = 100 });
			local y = c.Variable({ name = 'y', value = 200 });
			local z = c.Variable({ name = 'z', value = 50 });
			assert.is.same(x.value, 100);
			assert.is.same(y.value, 200);
			assert.is.same(z.value,  50);

			solver:addConstraint(c.Equation(z,   x,   weak))
			:addConstraint(c.Equation(x,  20,   weak))
			:addConstraint(c.Equation(y, 200, strong));

			assert.is.same(x.value,  20);
			assert.is.same(y.value, 200);
			assert.is.same(z.value,  20);

			solver:addConstraint(
				c.Inequality(c.plus(z, 150), "<=", y, medium)
				);

			assert.is.same(x.value,  20);
			assert.is.same(y.value, 200);
			assert.is.same(z.value,  20);
		end);
	end);
