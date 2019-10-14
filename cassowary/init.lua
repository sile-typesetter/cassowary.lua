local class = require("pl.class")
local tablex = require("pl.tablex")
local Set = require("pl.Set")

local cassowary

local epsilon = 1e-8
local count = 2

local subclass = function(base, inject)
  return tablex.update(class(base), inject)
end

local initialize = function(base, inject)
  return tablex.update(base(), inject)
end

local gensym = function ()
  count = count + 1
  return count
end

local isExpression = function (f)
  return type(f) == "table" and f:is_a(cassowary.Expression)
end

local isVariable = function (f)
  return type(f) == "table" and f:is_a(cassowary.Variable)
end

local isStrength = function (f)
  return type(f) == "table" and f:is_a(cassowary.Strength)
end

local isNumber = function (f)
  return type(f) == "number"
end

local isWeight = function (f)
  return type(f) == "table" and f:is_a(cassowary.SymbolicWeight)
end

local SetFirst = function (set)
  return Set.values(set)[1]
end

cassowary = {
  debug = false,
  trace = false,
  verbose = false,
  traceAdded = false,

  tracePrint = function (self, p)
    if self.trace and self.verbose then print(p) end
  end,

  traceFnEnterPrint = function (self, p)
    if self.trace then  print("* "..p) end
  end,

  traceFnExitPrint  = function (self, p)
    if self.trace then print("- "..p) end
  end,

  exprFromVarOrValue = function (v)
    if isNumber(v) then
      return cassowary.Expression.fromConstant(v)
    elseif isExpression(v) then
      return v
    elseif isVariable(v) then
      return cassowary.Expression.fromVariable(v)
    else
      return v
    end
  end,

  plus = function (e1, e2)
    return cassowary.exprFromVarOrValue(e1):plus(cassowary.exprFromVarOrValue(e2))
  end,

  minus = function (e1, e2)
    return cassowary.exprFromVarOrValue(e1):minus(cassowary.exprFromVarOrValue(e2))
  end,

  times = function (e1, e2)
    return cassowary.exprFromVarOrValue(e1):times(cassowary.exprFromVarOrValue(e2))
  end,

  divide = function (e1, e2)
    return cassowary.exprFromVarOrValue(e1):divide(cassowary.exprFromVarOrValue(e2))
  end,

  approx = function (a, b)
    if a == b then return true end
    a = type(a) == "table" and a.value or 0 + a
    b = type(b) == "table" and b.value or 0 + b
    if a == 0 then return math.abs(b) < epsilon end
    if b == 0 then return math.abs(a) < epsilon end
    return (math.abs(a - b) < math.abs(a) * epsilon)
  end
}

cassowary.AbstractVariable = class({
  varnameprefix = "",
  prefix = "",
  name = "",
  value = 0,
  isDummy = false,
  isExternal = false,
  isPivotable = false,
  isRestricted = false,

  _init = function (self, properties)
    self.hashcode = gensym()
    self.name = self.varnameprefix .. self.hashcode
    if properties then tablex.update(self, properties) end
  end,

  __tostring = function (self)
    return self.prefix .. "[" .. self.name .. ":" .. self.value .. "]"
  end
})

cassowary.Variable = subclass(cassowary.AbstractVariable, {
  varnameprefix = "v",
  isExternal = true
})

cassowary.DummyVariable = subclass(cassowary.AbstractVariable, {
  varnameprefix = "d",
  isDummy = true,
  isRestricted = true,
  value = "dummy"
})

cassowary.ObjectiveVariable = subclass(cassowary.AbstractVariable, {
  varnameprefix = "o",
  value = "obj"
})

cassowary.SlackVariable = subclass(cassowary.AbstractVariable, {
  varnameprefix = "s",
  value = "slack",
  isPivotable = true,
  isRestricted = true
})

local _multiplier = 1000
cassowary.SymbolicWeight = class({
  _init = function (self, coefficients)
    self.value = 0
    local factor = 1
    while #coefficients > 0 do
      self.value = self.value + ( factor * table.remove(coefficients) )
      factor = factor * _multiplier
    end
  end
})

cassowary.Strength = class({
  _init = function (self, name, w1, w2, w3)
    self.name = name
    if isWeight(w1) then
      self.symbolicWeight = w1
    else
      self.symbolicWeight = cassowary.SymbolicWeight({ w1, w2, w3 })
    end
  end,

  isRequired = function (self)
    return self == cassowary.Strength.required
  end,

  __tostring = function (self)
    return self.name .. (self:isRequired() and "" or ":"..tostring(self.symbolicWeight))
  end
})

cassowary.Strength.required = cassowary.Strength("<Required>", 1000, 1000, 1000 )
cassowary.Strength.strong = cassowary.Strength("strong", 1, 0, 0)
cassowary.Strength.medium = cassowary.Strength("medium", 0, 1, 0)
cassowary.Strength.weak = cassowary.Strength("weak", 0, 0, 1)

cassowary.EditInfo = class({
  __tostring = function ()
    return "EditInfo:"
  end
})

cassowary.Error = class({
  description = "Error: An error has occured in Cassowary",

  _init = function (self, desc)
    if desc then self.description = self.description .. ": " .. desc end
  end,

  __tostring = function (self)
    return self.description
  end
})

cassowary.InternalError   = subclass(cassowary.Error, { description = "InternalError" })
cassowary.NonExpression   = subclass(cassowary.Error, { description = "NonExpression: The resulting expression would be non" })
cassowary.RequiredFailure = subclass(cassowary.Error, { description = "RequiredFailure: A required constraint cannot be satisfied" })

cassowary.Tableau = class({
  _init = function (self)
    self.columns = {}
    self.rows = {}
    self.infeasibleRows         = Set {}
    self.externalRows           = Set {}
    self.externalParametricVars = Set {}
  end,

  noteRemovedVariable = function (self, v, subject)
    if cassowary.trace then print("c.Tableau::noteRemovedVariable: ", v, subject) end
    local column = self.columns[v]
    if (subject and column) then column = column - subject end
    self.columns[v] = column
  end,

  noteAddedVariable = function (self, v, subject)
    if subject then self:insertColVar(v, subject) end
  end,

  insertColVar = function (self, paramVar, rowvar)
    cassowary:traceFnEnterPrint("insertColVar "..tostring(paramVar).." "..tostring(rowvar))
    local rowset = self.columns[paramVar]
    if not rowset then
      rowset = Set {}
      self.columns[paramVar] = rowset
    end
    rowset = rowset + rowvar
    self.columns[paramVar] = rowset
  end,

  addRow = function (self, aVar, expr)
    cassowary:traceFnEnterPrint("addRow: "..tostring(aVar)..", "..tostring(expr))
    self.rows[aVar] = expr
    for clv, _ in pairs(expr.terms) do
      self:insertColVar(clv, aVar)
      if clv.isExternal then self.externalParametricVars = self.externalParametricVars + clv end
    end
    if aVar.isExternal then self.externalRows = self.externalRows + aVar end
    -- cassowary:tracePrint(self.."")
  end,

  removeColumn = function (self, aVar)
    cassowary:traceFnEnterPrint("removeColumn: "..tostring(aVar) )
    local rows = self.columns[aVar]
    if rows then
      self.columns[aVar] = nil
      for clv in Set.values(rows):iter() do
        local expr = self.rows[clv]
        expr.terms[aVar] = nil
      end
    end
    if aVar.isExternal then
      self.externalRows = self.externalRows - aVar
      self.externalParametricVars = self.externalParametricVars - aVar
    end
  end,

  removeRow = function (self, aVar)
    cassowary:traceFnEnterPrint("removeRow: "..tostring(aVar) )
    local expr = self.rows[aVar]
    assert(expr)
    for clv, _ in pairs(expr.terms) do
      local varset = self.columns[clv]
      if varset then
        varset = varset - aVar
      end
      self.columns[clv] = varset
    end
    self.infeasibleRows = self.infeasibleRows - aVar
    if aVar.isExternal then
      self.externalRows = self.externalRows - aVar
    end
    self.rows[aVar] = nil
    cassowary:traceFnExitPrint("returning "..tostring(expr) )
    return expr
  end,

  substituteOut = function (self, oldVar, expr)
    if cassowary.trace then
      cassowary:traceFnEnterPrint("substituteOut: "..tostring(oldVar))
    end

    local varset = self.columns[oldVar]
    for v in Set.values(varset):iter() do
      local row = self.rows[v]
      row:substituteOut(oldVar, expr, v, self)
      if v.isRestricted and row.constant < 0 then
        self.infeasibleRows = self.infeasibleRows + v
      end
    end

    if oldVar.isExternal then
      self.externalRows = self.externalRows + oldVar
      self.externalParametricVars = self.externalParametricVars - oldVar
    end

    self.columns[oldVar] = nil
  end,

  columnsHasKey = function (self, subject)
    return self.columns[subject] ~= nil
  end
})

cassowary.Expression = class({
  _init = function (self, cvar, value, constant)
    self.hashcode = gensym()
    self.constant = type(constant) == "number" and constant or 0
    self.terms = {}
    if isNumber(cvar) then self.constant = cvar
    elseif type(cvar) == "table" then
      self:setVariable(cvar, type(value) == "number" and value or 1)
    end
  end,

  initializeFromTable = function (self, constant, terms)
    self.constant = constant
    self.terms = tablex.copy(terms)
    return self
  end,

  multiplyMe = function (self, x)
    self.constant = self.constant * x
    for clv, coeff in pairs(self.terms) do
      self.terms[clv] = coeff * x
    end
    return self
  end,

  clone = function (self)
    local c = cassowary.Expression.empty()
    c:initializeFromTable(self.constant, self.terms)
    return c
  end,

  times = function (self, x)
    if type(x) == "number" then return (self:clone()):multiplyMe(x)
    elseif self:isConstant() then return x:times(self.constant)
    elseif x:isConstant() then return self:times(x.constant)
    else error(cassowary.NonExpression)
    end
  end,

  plus = function (self, x)
    if x:is_a(cassowary.Expression) then return (self:clone()):addExpression(x, 1)
    elseif x:is_a(cassowary.Variable) then return (self:clone()):addVariable(x, 1)
    end
  end,

  minus = function (self, x)
    if x:is_a(cassowary.Expression) then return (self:clone()):addExpression(x, -1)
    elseif x:is_a(cassowary.Variable) then return (self:clone()):addVariable(x, -1)
    end
  end,

  divide = function (self, x)
    if type(x) == "number" then
      if cassowary.approx(x, 0) then error(cassowary.NonExpression) else return self:times(1/x) end
    elseif x:is_a(cassowary.Expression) then
      if not x:isConstant() then error(cassowary.NonExpression) else return self:times(1/x.constant) end
    end
  end,

  addExpression = function (self, expr, n, subject, solver)
    if expr:is_a(cassowary.Variable) then expr = cassowary.Expression.fromVariable(expr) end
    n = type(n) == "number" and n or 1
    self.constant = self.constant + (n * expr.constant)
    for clv, coeff in pairs(expr.terms) do
      self:addVariable(clv, coeff * n, subject, solver)
    end
    return self
  end,

  addVariable = function (self, v, cd, subject, solver)
    cd = cd or 1
    local coeff = self.terms[v]
    if coeff then
      local newCoefficient = coeff + cd
      if newCoefficient == 0 or cassowary.approx(newCoefficient, 0) then
        if solver then solver:noteRemovedVariable(v, subject) end
        self.terms[v] = nil
      else
        self:setVariable(v, newCoefficient)
      end
    else
      if not cassowary.approx(cd, 0) then
        self:setVariable(v, cd)
        if solver then
          solver:noteAddedVariable(v, subject)
        end
      end
    end
    return self
  end,

  setVariable = function (self, v, c)
    self.terms[v] = c
    return self
  end,

  anyPivotableVariable = function (self)
    if self:isConstant() then
      error(cassowary.InternalError("anyPivotableVariable called on a constant"))
    end
    for clv, _ in pairs(self.terms) do
      if clv.isPivotable then return clv end
    end
    return nil
  end,

  substituteOut = function (self, outvar, expr, subject, solver)
    local multiplier = self.terms[outvar]
    self.terms[outvar] = nil
    self.constant = self.constant + (multiplier * expr.constant)
    for clv, coeff in pairs(expr.terms) do
      local oldcoeff = self.terms[clv]
      if oldcoeff then
        local newCoefficient = oldcoeff + multiplier * coeff
        if cassowary.approx(newCoefficient, 0) then
          solver:noteRemovedVariable(clv, subject)
          self.terms[clv] = nil
        else
          self.terms[clv] = newCoefficient
        end
      else
        self.terms[clv] = multiplier * coeff
        if solver then
          solver:noteAddedVariable(clv, subject)
        end
      end
    end
  end,

  changeSubject = function (self, old, new)
    self:setVariable(old, self:newSubject(new))
  end,

  newSubject = function (self, subject)
    local reciprocal = 1 / self.terms[subject]
    self.terms[subject] = nil
    self:multiplyMe(-reciprocal)
    return reciprocal
  end,

  coefficientFor = function (self, clv)
    return self.terms[clv] or 0
  end,

  isConstant = function (self)
    return next(self.terms) == nil -- terms contraindicate an equation being constant
  end,

  equals = function (self, other)
    if self == other then
      return true
    elseif isExpression(other) and not other:isConstant() then
      return tablex.deepcompare(self.terms, other.terms)
    else
      return other.constant == self.constant
    end
  end,

  __tostring = function (self)
    local rv = ""
    local needsplus = false
    if (not cassowary.approx(self.constant, 0) or self:isConstant()) then
      rv = rv .. self.constant
      if self:isConstant() then return rv end
      needsplus = true
    end
    local sort_hashcodes = function (a, b) return a.hashcode < b.hashcode end
    for clv, coeff in tablex.sort(self.terms, sort_hashcodes) do
      if needsplus then rv = rv .. " + " end
      rv = rv .. coeff .. "*" .. clv.value
      needsplus = true
    end
    return rv
  end,

  empty = function ()
    return cassowary.Expression(nil, 1, 0)
  end,

  fromConstant = function (c)
    return cassowary.Expression(c)
  end,

  fromValue = function (v)
    return cassowary.Expression(nil, v, 0)
  end,

  fromVariable = function (v)
    return cassowary.Expression(v, 1, 0)
  end
})

local _constraintStringify = function (self) return tostring(self.strength) .. " {" .. tostring(self.weight) .. "} (" .. tostring(self.expression) .. ")" end

cassowary.AbstractConstraint = class({
  isEditConstraint = false,
  isInequality = false,
  isStayConstraint = false,
  __tostring = _constraintStringify,

  _init = function (self, cle, strength, weight)
    self.hashcode = gensym()
    self.strength = strength or cassowary.Strength.required
    self.weight = (not weight or weight == 0) and 1 or weight
    if cle then self.expression = cle end
  end,

  required = function (self)
    return self.strength == cassowary.Strength.required
  end
})

cassowary.EditConstraint = subclass(cassowary.AbstractConstraint, {
  isEditConstraint = true,

  _init = function (self, cv, strength, weight)
    self:super(nil, strength, weight)
    self.variable = cv
    self.expression = cassowary.Expression(cv, -1, cv.value)
  end,

  __tostring = function (self) return "edit: ".._constraintStringify(self) end
})

cassowary.StayConstraint = subclass(cassowary.AbstractConstraint, {
  isStayConstraint = true,

  _init = function (self, cv, strength, weight)
    self:super(nil, strength, weight)
    self.variable = cv
    self.expression = cassowary.Expression(cv, -1, cv.value)
  end,

  __tostring = function (self) return "stay: ".._constraintStringify(self) end
})

cassowary.Inequality = subclass(cassowary.AbstractConstraint, {
  isInequality = true,

  cloneOrNewCle = function (cle)
    if type(cle)=="table" and cle.clone then return cle:clone() else return cassowary.Expression(cle) end
  end,

  _init = function (self, a1, a2, a3, a4, a5)
    -- This disgusting mess copied from slightyoff's disgusting mess
    -- (cle || number), op, cv
    if (isNumber(a1) or isExpression(a1)) and isVariable(a3) and not isExpression(a3) then
      local cle, op, cv, strength, weight = a1, a2, a3, a4, a5
      self:super(self.cloneOrNewCle(cle), strength, weight)
      if op == "<=" then
        self.expression:multiplyMe(-1)
        self.expression:addVariable(cv)
      elseif op == ">=" then
        self.expression:addVariable(cv, -1)
      else
        error(cassowary.InternalError("Invalid operator in c.Inequality constructor"))
      end
    -- cv, op, (cle || number)
    elseif isVariable(a1) and (isNumber(a3) or isExpression(a3)) then
      local cle, op, cv, strength, weight = a3, a2, a1, a4, a5
      self:super(self.cloneOrNewCle(cle), strength, weight)
      if op == ">=" then -- a switch!
        self.expression:multiplyMe(-1)
        self.expression:addVariable(cv)
      elseif op == "<=" then
        self.expression:addVariable(cv, -1)
      else
        error(cassowary.InternalError("Invalid operator in c.Inequality constructor"))
      end
    -- cle, op, num
    elseif isExpression(a1) and isNumber(a3) then
      -- I feel like I'm writing Java
      local cle1, op, cle2, strength, weight = a1, a2, a3, a4, a5
      self:super(self.cloneOrNewCle(cle1), strength, weight)
      if op == "<=" then
        self.expression:multiplyMe(-1)
        self.expression:addExpression(self.cloneOrNewCle(cle2))
      elseif op == ">=" then
        -- Just keep turning the crank and the code keeps coming out
        self.expression:addExpression(self.cloneOrNewCle(cle2), -1)
      else
        error(cassowary.InternalError("Invalid operator in c.Inequality constructor"))
      end
    elseif isNumber(a1) and isExpression(a3) then
      -- Polymorphism makes a lot of sense in strongly-typed languages
      local cle1, op, cle2, strength, weight = a3, a2, a1, a4, a5
      self:super(self.cloneOrNewCle(cle1), strength, weight)
      if op == ">=" then
        self.expression:multiplyMe(-1)
        self.expression:addExpression(self.cloneOrNewCle(cle2))
      elseif op == "<=" then
        self.expression:addExpression(self.cloneOrNewCle(cle2), -1)
      else
        error(cassowary.InternalError("Invalid operator in c.Inequality constructor"))
      end
    elseif isExpression(a1) and isExpression(a3) then
      -- but in weakly-typed languages it really doesn't gain you anything.
      local cle1, op, cle2, strength, weight = a1, a2, a3, a4, a5
      self:super(self.cloneOrNewCle(cle2), strength, weight)
      if op == ">=" then
        self.expression:multiplyMe(-1)
        self.expression:addExpression(self.cloneOrNewCle(cle1))
      elseif op == "<=" then
        self.expression:addExpression(self.cloneOrNewCle(cle1), -1)
      else
        error(cassowary.InternalError("Invalid operator in c.Inequality constructor"))
      end
    elseif isExpression(a1) then
      self:super(a1, a2, a3)
    elseif a2 == ">=" then
      self:super(cassowary.Expression(a3), a4, a5)
      self.expression:multiplyMe(-1)
      self.expression:addVariable(a1)
    elseif a2 == "<=" then
      self:super(cassowary.Expression(a3), a4, a5)
      self.expression:addVariable(a1, -1)
    else
      error(cassowary.InternalError("Invalid operator in c.Inequality constructor"))
    end
    assert(self.expression)
  end,

  __tostring = function (self)
    return _constraintStringify(self) .. " >= 0) id: ".. self.hashcode
  end
})

cassowary.Equation = subclass(cassowary.AbstractConstraint, {
  _init = function (self, a1, a2, a3, a4)
    if (isExpression(a1) and not a2 or isStrength(a2)) then
      self:super(a1, a2, a3)
    elseif isVariable(a1) and isExpression(a2) then
      local cv, cle, strength, weight = a1, a2, a3, a4
      self:super(cle:clone(), strength, weight)
      self.expression:addVariable(cv, -1)
    elseif isVariable(a1) and isNumber(a2) then
      local cv, val, strength, weight= a1, a2, a3, a4
      self:super(cassowary.Expression(val), strength, weight)
      self.expression:addVariable(cv, -1)
    elseif isExpression(a1) and isVariable(a2) then
      local cle, cv, strength, weight= a1, a2, a3, a4
      self:super(cle:clone(), strength, weight)
      self.expression:addVariable(cv, -1)
    elseif (isNumber(a1) or isExpression(a1) or isVariable(a1)) and
      (isNumber(a2) or isExpression(a2) or isVariable(a2)) then
      a1 = isExpression(a1) and a1:clone() or cassowary.Expression(a1)
      a2 = isExpression(a2) and a2:clone() or cassowary.Expression(a2)
      self:super(a1, a3, a4)
      self.expression:addExpression(a2, -1)
    else
      error("Bad initializer to Equation")
    end
    assert(self.strength:is_a(cassowary.Strength))
  end,

  __tostring = function (self)
    return _constraintStringify(self) .. " = 0"
  end
})

cassowary.SimplexSolver = subclass(cassowary.Tableau, {
  _init = function (self)
    self:super()
    self.stayMinusErrorVars = {}
    self.stayPlusErrorVars = {}
    self.errorVars = {}
    self.markerVars = {}
    self.objective = cassowary.ObjectiveVariable({name = "Z"})
    self.editVarMap = {}
    self.editVarList = {} -- XXX
    self.slackCounter = 0
    self.artificialCounter = 0
    self.dummyCounter = 0
    self.autoSolve = true
    self.needsSolving = false
    self.optimizeCount = 0
    self.rows[self.objective] = cassowary.Expression.empty()
    self.editVariableStack = { 0 } -- A stack of *element counts*
    if cassowary.trace then
      cassowary:tracePrint("objective expr == "..tostring(self.rows[self.objective]))
    end
    return self
  end,

  add = function (self, ...)
    local args = {...}
    for k=1, #args do self:addConstraint(args[k]) end
    return self
  end,

  addEditConstraint = function (self, cn, eplus_eminus, prevEConstant)
    local i = 0
    for _ in pairs(self.editVarMap) do i = i + 1 end
    local cvEplus, cvEminus = eplus_eminus[1], eplus_eminus[2]
    local ei = initialize(cassowary.EditInfo, { constraint = cn,
      editPlus = cvEplus,
      editMinus = cvEminus,
      prevEditConstant = prevEConstant,
      index = i })
    self.editVarMap[cn.variable] = ei
    self.editVarList[i+1] = {v = cn.variable, info = ei}
  end,

  addConstraint = function (self, cn)
    cassowary:traceFnEnterPrint("addConstraint: "..tostring(cn))
    local expr, eplus_eminus, prevEConstant = self:newExpression(cn)
    if not self:tryAddingDirectly(expr) then self:addWithArtificialVariable(expr) end
    self.needsSolving = true
    if cn.isEditConstraint then self:addEditConstraint(cn, eplus_eminus, prevEConstant) end
    if self.autoSolve then
      self:optimize(self.objective)
      self:setExternalVariables()
    end
    return self
  end,

  addConstraintNoException = function (self, cn)
    cassowary:traceFnEnterPrint("addConstaintNoException: "..tostring(cn))
    return pcall(self.addConstraint, self, cn)
  end,

  addEditVar = function (self, v, strength, weight)
    cassowary:traceFnEnterPrint("addEditVar: " .. tostring(v) .. " @ " .. tostring(strength) .. " {" .. tostring(weight) .. "}");
    return self:addConstraint(cassowary.EditConstraint(v, strength or cassowary.Strength.strong, weight));
  end,

  beginEdit = function (self)
    local i = 0
    for _ in pairs(self.editVarMap) do i = i + 1 end
    assert(i > 0)
    self.infeasibleRows = Set {}
    self:resetStayConstants();
    self.editVariableStack[#(self.editVariableStack)+1] = i
    return self;
  end,

  endEdit = function ( self )
    local i = 0
    for _ in pairs(self.editVarMap) do i = i + 1 end
    assert(i > 0)
    self:resolve()
    table.remove(self.editVariableStack)
    local last = self.editVariableStack[#(self.editVariableStack)]
    self:removeEditVarsTo(last)
    return self
  end,

  removeAllEditVars = function (self)
    self:removeEditVarsTo(0)
  end,

  removeEditVarsTo = function (self, n)
    -- n is a count, which in lua is not an index
    for k = n + 1, #(self.editVarList) do
      if self.editVarList[k] then
        local v = self.editVarMap[self.editVarList[k].v]
        self:removeConstraint(v.constraint)
      end
      self.editVarList[k] = nil
    end
    local i = 0
    for _ in pairs(self.editVarMap) do i = i + 1 end
    assert(i == n)
  end,

  addPointStays = function (self, points)
    cassowary:traceFnEnterPrint("addPointStays: "..tostring(points))
    for i = 1, #points do
      local p = points[i]
      self:addStay(p.x, cassowary.Strength.weak, 2^i)
      self:addStay(p.y, cassowary.Strength.weak, 2^i)
    end
    return self
  end,

  addStay = function (self, v, strength, weight)
    local cn = cassowary.StayConstraint(v, strength or cassowary.Strength.weak, weight or 1)
    return self:addConstraint(cn)
  end,

  removeConstraint = function (self, cn)
    cassowary:traceFnEnterPrint("removeConstraint: "..tostring(cn))
    self.needsSolving = true
    self:resetStayConstants()
    local zrow = self.rows[self.objective]
    local evars = self.errorVars[cn]
    cassowary:tracePrint("evars: "..tostring(evars))
    if evars then
      for cv in Set.values(evars):iter() do
        local expr = self.rows[cv]
        if not expr then
          zrow:addVariable(cv, -cn.weight * cn.strength.symbolicWeight.value, self.objective, self)
        else
          zrow:addExpression(expr, -cn.weight * cn.strength.symbolicWeight.value, self.objective, self)
        end
        cassowary:tracePrint("now evars: "..tostring(evars))
      end
    end
    local marker = self.markerVars[cn]
    self.markerVars[cn] = nil
    if not marker then error(cassowary.InternalError("Constraint not found in removeConstraint")) end
    cassowary:tracePrint("Looking to remove var "..tostring(marker))
    if not self.rows[marker] then
      local col = self.columns[marker] -- XXX
      --cassowary:tracePrint("Must pivot - cols are "..col)
      local exitVar
      local minRatio = 0
      for v in Set.values(col):iter() do
        if v.isRestricted then
          local expr = self.rows[v]
          local coeff = expr:coefficientFor(marker)
          cassowary:tracePrint("Marker "..tostring(marker).."'s coefficient in "..tostring(expr).." is "..tostring(coeff))
          if coeff < 0 then
            local r = -expr.constant / coeff
            if (not exitVar) or r < minRatio or (
              cassowary.approx(r, minRatio) and v.hashcode < exitVar.hashcode
              ) then
              minRatio = r
              exitVar = v
            end
          end
        end
      end
      if not exitVar then
        cassowary:tracePrint("Exitvar still null")
        for v in Set.values(col):iter() do
          if v.isRestricted then
            local expr = self.rows[v]
            local coeff = expr:coefficientFor(marker)
            local r = expr.constant / coeff
            if (not exitVar) or r < minRatio then
              minRatio = r
              exitVar = v
            end
          end
        end
      end
      if not exitVar then
        if Set.len(col) == 0 then self:removeColumn(marker)
        else
          local i = 1
          while i <= #col and not exitVar do
            if not (col[i] == self.objective) then exitVar = col[i] end
          end
        end
      end
      if exitVar then self:pivot(marker, exitVar) end
    end
    if self.rows[marker] then self:removeRow(marker) end
    if evars then
      for _, v in ipairs(evars) do
        if v ~= marker then self:removeColumn(v) end
      end
    end
    if cn.isStayConstraint then
      if evars then
        for i = 1, #(self.stayPlusErrorVars) do
          evars[self.stayPlusErrorVars[i]] = nil
          evars[self.stayMinusErrorVars[i]] = nil
        end
      end
    elseif cn.isEditConstraint then
      assert(evars)
      local cei = self.editVarMap[cn.variable]
      self:removeColumn(cei.editMinus)
      self.editVarMap[cn.variable] = nil
    end
    if evars then self.errorVars[evars] = nil end
    if self.autoSolve then
      self:optimize(self.objective)
      self:setExternalVariables()
    end
    return self
  end,

  reset = function ()
    error(cassowary.InternalError("reset not implemented" ))
  end,

  resolveArray = function (self, newEditConstants)
    cassowary:traceFnEnterPrint("resolveArray: "..newEditConstants)
    local l = #newEditConstants
    for v, cei in pairs(self.editVarMap) do
      local i = cei.index
      if i < l then self:suggestValue(v, newEditConstants[i]) end
    end
    self:resolve()
  end,

  resolvePair = function (self, x, y)
    self:suggestValue(self.editVarList[1].v, x)
    self:suggestValue(self.editVarList[2].v, y)
  end,

  resolve = function (self)
    self:dualOptimize()
    self:setExternalVariables()
    self.infeasibleRows = Set {}
    self:resetStayConstants()
  end,

  suggestValue = function (self, v, x)
    cassowary:traceFnEnterPrint("suggestValue: "..tostring(v).. " "..tostring(x))
    local cei = self.editVarMap[v] or error(cassowary.Error("suggestValue for variable " .. v .. ", but var is not an edit variable"))
    local delta = x - cei.prevEditConstant
    cei.prevEditConstant = x
    self:deltaEditConstant(delta, cei.editPlus, cei.editMinus)
    return self
  end,

  solve = function (self)
    if not self.needsSolving then return self end
    self:optimize(self.objective)
    self:setExternalVariables()
    return self
  end,

  setEditedValue = function ()
    assert("Nobody calls this")
  end,

  addVar = function ()
    assert("Or this")
  end,

  getInternalInfo = function ()
    error("Unimplemented")
  end,

  addWithArtificialVariable = function (self, expr)
    cassowary:traceFnEnterPrint("addWithArtificialVariable "..tostring(expr))
    self.artificialCounter = self.artificialCounter + 1
    local av = cassowary.SlackVariable({ value = self.artificialCounter, prefix = "a"})
    local az = cassowary.ObjectiveVariable({ name = "az" })
    local azRow = expr:clone()
    self:addRow(az, azRow)
    self:addRow(av, expr)
    self:optimize(az)
    local azTableauRow = self.rows[az]
    cassowary:tracePrint("azTableauRow.constant == " .. tostring(azTableauRow.constant))
    if not cassowary.approx(azTableauRow.constant, 0) then
      self:removeRow(az)
      self:removeColumn(av)
      error(cassowary.RequiredFailure)
    end
    local e = self.rows[av]
    if e then
      if e:isConstant() then
        self:removeRow(av)
        self:removeRow(az)
        return
      end
      self:pivot(e:anyPivotableVariable(), av)
    end
    assert(not self.rows[av])
    self:removeColumn(av)
    self:removeRow(az)
  end,

  tryAddingDirectly = function (self, expr)
    cassowary:traceFnEnterPrint("tryAddingDirectly "..tostring(expr))
    local subject = self:chooseSubject(expr)
    if not subject then
      cassowary:traceFnExitPrint("Returning false")
      return false
    end
    expr:newSubject(subject)
    if self:columnsHasKey(subject) then
      self:substituteOut(subject, expr)
    end
    self:addRow(subject, expr)
    cassowary:traceFnExitPrint("Returning true")
    return true
  end,

  chooseSubject = function (self, expr)
    cassowary:traceFnEnterPrint("chooseSubject "..tostring(expr))
    local subject, foundUnrestricted, foundNewRestricted
    local terms = expr.terms
    for v, c in pairs(terms) do
      if foundUnrestricted then
        if not v.isRestricted and not self:columnsHasKey(v) then
          return v
        end
      elseif v.isRestricted then
        if not foundNewRestricted and not v.isDummy and c < 0 then
          local col = self.columns[v]
          if not col or (#col == 1 and self:columnsHasKey(self.objective)) then
            subject = v
            foundNewRestricted = true
          end
        end
      else
        subject = v
        foundUnrestricted = true
      end
    end
    if subject then return subject end
    local coeff = 0
    local oneNonDummy = false
    for v, c in pairs(terms) do
      if not v.isDummy then
        oneNonDummy = true
        break
      end
      if not self:columnsHasKey(v) then
        subject = v
        coeff = c
      end
    end
    if oneNonDummy then return false end
    if not cassowary.approx(expr.constant, 0) then
      error(cassowary.RequiredFailure)
    end
    if coeff > 0 then expr:multiplyMe(-1) end
    return subject
  end,

  deltaEditConstant = function (self, delta, plusErrorVar, minusErrorVar)
    cassowary:traceFnEnterPrint("deltaEditConstant".. " "..tostring(delta).." "..tostring(plusErrorVar).." "..tostring(minusErrorVar))
    local exprPlus = self.rows[plusErrorVar]
    if exprPlus then
      exprPlus.constant = exprPlus.constant + delta
      if exprPlus.constant < 0 then self.infeasibleRows = self.infeasibleRows + plusErrorVar end
      return
    end
    local exprMinus = self.rows[minusErrorVar]
    if exprMinus then
      exprMinus.constant = exprMinus.constant - delta
      if exprMinus.constant < 0 then self.infeasibleRows = self.infeasibleRows + minusErrorVar end
      return
    end
    local columnVars = self.columns[minusErrorVar]
    if not columnVars then print("columnVars is null!") end
    for basicVar in Set.values(columnVars):iter() do
      local expr = self.rows[basicVar]
      local c = expr:coefficientFor(minusErrorVar)
      expr.constant = expr.constant + (c * delta)
      if basicVar.isRestricted and expr.constant < 0 then
        self.infeasibleRows = self.infeasibleRows + basicVar
      end
    end
  end,

  dualOptimize = function (self)
    cassowary:traceFnEnterPrint("dualOptimize")
    local zRow = self.rows[self.objective]
    while Set.len(self.infeasibleRows) > 0 do
      local exitVar = SetFirst(self.infeasibleRows)
      self.infeasibleRows = self.infeasibleRows - exitVar
      local entryVar = nil
      local expr = self.rows[exitVar]
      if expr and expr.constant < 0 then
        local ratio = 1/0
        local r
        local terms = expr.terms
        for v, cd in pairs(terms) do
          if cd > 0 and v.isPivotable then
            local zc = zRow:coeffientFor(v)
            r = zc / cd
            if r < ratio or (cassowary.approx(r, ratio) and v.hashcode < entryVar.hashcode) then
              entryVar = v
              ratio = r
            end
          end
        end
        if ratio == 1/0 then
          error(cassowary.InternalError("ratio == nil in dualOptimize"))
        end
        self:pivot(entryVar, exitVar)
      end
    end
  end,

  newExpression = function (self, cn)
    cassowary:traceFnEnterPrint("newExpression "..tostring(cn))
    local cnExpr = cn.expression
    local expr = cassowary.Expression.fromConstant(cnExpr.constant)
    local slackvar, dummyvar, eminus, eplus
    local cnTerms = cnExpr.terms
    local eplus_eminus = {}
    local prevEConstant
    for v, c in pairs(cnTerms) do
      local e = self.rows[v]
      if not e then expr:addVariable(v, c) else expr:addExpression(e, c) end
    end
    if cn.isInequality then
      cassowary:tracePrint("Inequality, adding slack")
      self.slackCounter = self.slackCounter + 1
      slackvar = cassowary.SlackVariable({ value = self.slackCounter, prefix = "s" })
      expr:setVariable(slackvar, -1)
      self.markerVars[cn] = slackvar
      if not cn:required() then
        self.slackCounter = self.slackCounter + 1
        eminus = cassowary.SlackVariable({ value = self.slackCounter, prefix = "em" })
        expr:setVariable(eminus, 1)
        local zRow = self.rows[self.objective]
        zRow:setVariable(eminus, cn.strength.symbolicWeight.value * cn.weight)
        self:insertErrorVar(cn, eminus)
        self:noteAddedVariable(eminus, self.objective)
      end
    elseif cn:required() then
      cassowary:tracePrint("Equality, required")
      self.dummyCounter = self.dummyCounter + 1
      dummyvar = cassowary.DummyVariable({ value = self.dummyCounter, prefix = "d" })
      eplus_eminus[1] = dummyvar
      eplus_eminus[2] = dummyvar
      prevEConstant = cnExpr.constant
      expr:setVariable(dummyvar, 1)
      self.markerVars[cn] = dummyvar
      cassowary:tracePrint("Adding dummy var d"..self.dummyCounter)
    else
      cassowary:tracePrint("Equality, not required")
      self.slackCounter = self.slackCounter + 1
      eplus = cassowary.SlackVariable({ value = self.slackCounter, prefix = "ep" })
      eminus = cassowary.SlackVariable({ value = self.slackCounter, prefix = "em" })
      expr:setVariable(eplus, -1)
      expr:setVariable(eminus, 1)
      self.markerVars[cn] = eplus
      local zRow = self.rows[self.objective]
      cassowary:tracePrint(zRow)
      local swCoeff = cn.strength.symbolicWeight.value * cn.weight
      if swCoeff == 0 then
        cassowary:tracePrint("cn === "..cn.. " swCoeff = 0")
      end
      zRow:setVariable(eplus, swCoeff)
      self:noteAddedVariable(eplus, self.objective)
      zRow:setVariable(eminus, swCoeff)
      self:noteAddedVariable(eminus, self.objective)
      self:insertErrorVar(cn, eminus)
      self:insertErrorVar(cn, eplus)
      if cn.isStayConstraint then
        self.stayPlusErrorVars[#self.stayPlusErrorVars+1] = eplus
        self.stayMinusErrorVars[#self.stayMinusErrorVars+1] = eminus
      elseif cn.isEditConstraint then
        eplus_eminus[1] = eplus
        eplus_eminus[2] = eminus
        prevEConstant = cnExpr.constant
      end
    end
    if expr.constant <0 then expr:multiplyMe(-1) end
    return expr, eplus_eminus, prevEConstant
  end,

  optimize = function (self, zVar)
    cassowary:traceFnEnterPrint("optimize: "..tostring(zVar))
    self.optimizeCount = self.optimizeCount + 1
    local zRow = self.rows[zVar]
    assert(zRow)
    local entryVar, exitVar, objectiveCoeff, terms
    while true do
      objectiveCoeff = 0
      terms = zRow.terms
      for v, c in pairs(terms) do
        if v.isPivotable and c < objectiveCoeff then
          objectiveCoeff = c
          entryVar = v
          break
        end
      end
      cassowary:tracePrint("entryVar: "..tostring(entryVar).." objectiveCoeff: "..tostring(objectiveCoeff))
      if objectiveCoeff >= -epsilon then return end
      local minRatio = 2^64
      local columnVars = self.columns[entryVar]
      local r
      for v in Set.values(columnVars):iter() do
        cassowary:tracePrint("Checking "..tostring(v))
        if v.isPivotable then
          local expr = self.rows[v]
          local coeff = expr:coefficientFor(entryVar)
          cassowary:tracePrint("pivotable, coeff is "..tostring(coeff))
          if coeff < 0 then
            r = -expr.constant / coeff
            if r < minRatio or (cassowary.approx(r, minRatio) and v.hashcode < exitVar.hashcode) then
              minRatio = r
              exitVar = v
            end
          end
        end
      end
      if minRatio == 2^64 then
        error(cassowary.InternalError("Objective function is unbounded in optimize"))
      end
      self:pivot(entryVar, exitVar)
    end
  end,

  pivot = function (self, entryVar, exitVar)
    cassowary:tracePrint("pivot: "..tostring(entryVar)..", "..tostring(exitVar))
    local expr = self:removeRow(exitVar)
    expr:changeSubject(exitVar, entryVar)
    self:substituteOut(entryVar, expr)
    self:addRow(entryVar, expr)
  end,

  resetStayConstants = function (self)
    cassowary:tracePrint("resetStayConstants")
    local spev = self.stayPlusErrorVars
    for i = 1, #spev do
      local expr = self.rows[spev[i]]
      if not expr then expr = self.rows[self.stayMinusErrorVars[i]] end
      if expr then expr.constant = 0 end
    end
  end,

  setExternalVariables = function (self)
    cassowary:tracePrint("setExternalVariables")
    local changed = {}
    for v in Set.values(self.externalParametricVars):iter() do
      if self.rows[v] then
        cassowary:tracePrint("Error: variable" .. tostring(v) .. " in _externalParametricVars is basic")
      else
        v.value = 0
        changed[v.name] = 0
      end
    end
    for v in Set.values(self.externalRows):iter() do
      local expr = self.rows[v]
      if not (v.value == expr.constant) then
        v.value = expr.constant
        changed[v.name] = expr.constant
      end
    end
    self.changed = changed
    self.needsSolving = false
    -- self:informCallbacks()
    -- self:onsolved()
  end,

  insertErrorVar = function (self, cn, aVar)
    cassowary:tracePrint("insertErrorVar: "..tostring(cn)..", "..tostring(aVar))
    local constraintSet = self.errorVars[aVar]
    if not constraintSet then
      constraintSet = Set {}
      self.errorVars[cn] = constraintSet
    end
    constraintSet = constraintSet + aVar
    self.errorVars[cn] = constraintSet
  end,

  __tostring = function (self)
    local s = "TABLEAU ROWS\n"
    for r, v in pairs(self.rows) do
      s = s .. tostring(r) .. ":\n"
        for t, t2 in pairs(v.terms) do
          s = s .. "  " .. tostring(t) .. " : "..tostring(t2).."\n"
        end
      s = s .. "\n"
    end
    s = s .. "TABLEAU Columns\n"
    for r, v in pairs(self.columns) do
      s = s .. tostring(r) .. ":" .. tostring(v).."\n"
    end
    return s
  end
})

return cassowary
