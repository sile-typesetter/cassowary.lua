# Cassowary

This is a lua port of the [cassowary](http://constraints.cs.washington.edu/cassowary/)
constraint solving toolkit. It allows you to use lua to solve algebraic equations and
inequalities and find the values of unknown variables which satisfy those inequalities.

This port is a fairly dumb, bug-for-bug translation of the 
[Javascript version of cassowary](https://github.com/slightlyoff/cassowary.js). From that
project's description:

"Cassowary and other hierarchial constraint toolkits add a unique mechanism for deciding between sets of rules that might conflict in determining which of a set of possible solutions are "better". By allowing constraint authors to specify weights for the constraints, the toolkit can decide in terms of stronger constraints over weaker ones, allowing for more optimal solutions. These sorts of situations arise all the time in UI programming; e.g.: "I'd like this to be it's natural width, but only if that's smaller than 600px, and never let it get smaller than 200px". Constraint solvers offer a way out of the primordial mess of nasty conditionals and brittle invalidations."

## Getting started

Cassowary.lua is distributed through luarocks. Once installed:

```lua
cassowary = require("cassowary")

-- Create a new solver object
local solver = cassowary.SimplexSolver();

-- Create lua variables to represent x and y
local x = cassowary.Variable({ name = 'x' });
local y = cassowary.Variable({ name = 'y' });

-- Let's encode some expressions:

--    x < y
solver:addConstraint(cassowary.Inequality(x, "<=", y))

--    y = x + 3
solver:addConstraint(cassowary.Equation(y, cassowary.plus(x, 3)))

--    either x = 10 or y = 10
solver:addConstraint(cassowary.Equation(x, 10, cassowary.Strength.weak))
solver:addConstraint(cassowary.Equation(y, 10, cassowary.Strength.weak))

-- The solver automatically tries to resolve the current situation
-- whenever constraints are added, so all we need to do is look
-- at the values:

print("x = "..x.value)
print("y = "..y.value)
```

Depending on the phase of the moon, you will either see:

```
x=7
y=10
```

or

```
x=10
y=13
```

For further examples, see the test suite.

## Licence

This is a derived work of the Javascript port; I've chosen to
licensed it similarly under the Apache 2.0 license.

## Author

Simon Cozens, <simon@simon-cozens.org>
