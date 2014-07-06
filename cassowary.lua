local epsilon = 1e-8
local count = 1
std = require("std")

local function gPairs (t)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, function(x,y) return x.hashcode < y.hashcode end)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

cassowary = {
  debug = false,
  trace = false,
  verbose = false,
  traceAdded = false,
  tracePrint = function(self, p) if self.trace and self.verbose then print(p) end end,
  traceFnEnterPrint = function(self, p) if self.trace then  print("* "..p) end end,
  traceFnExitPrint  = function(self, p) if self.trace then print("- "..p) end end,
  exprFromVarOrValue = function (v)
    if type(v)=="number" then
      return cassowary.Expression.fromConstant(v)
    elseif v:prototype() == "Expression" then
      return v
    elseif type(v)=="table" then
      return cassowary.Expression.fromVariable(v)
    else
      return v
    end
  end,
  plus = function (e1,e2)
    return cassowary.exprFromVarOrValue(e1):plus(cassowary.exprFromVarOrValue(e2))
  end,
  minus = function (e1,e2)
    return cassowary.exprFromVarOrValue(e1):minus(cassowary.exprFromVarOrValue(e2))
  end,
  times = function (e1,e2)
    return cassowary.exprFromVarOrValue(e1):times(cassowary.exprFromVarOrValue(e2))
  end,
  divide = function (e1,e2)
    return cassowary.exprFromVarOrValue(e1):divide(cassowary.exprFromVarOrValue(e2))
  end,
  approx = function (a,b)
    if a == b then return true end
    a = 0 + a
    b = 0 + b
    if a == 0 then return math.abs(b) < epsilon end
    if b == 0 then return math.abs(a) < epsilon end
    return (math.abs(a - b) < math.abs(a) * epsilon)
  end,
  gensym = function()
    count = count + 1
    return count
  end
}

cassowary.AbstractVariable = std.object {
  varnameprefix = "",
  prefix = "",
  name = "",
  value = 0,
  isDummy = false,
  isExternal = false,
  isPivotable = false,
  isRestricted = false,
  _type = "AbstractVariable",
  _init = function (self,t)
    self.hashcode = cassowary.gensym()
    self.name = self.varnameprefix .. self.hashcode
    if t then
      return std.table.merge(self, t)
    else
      return self
    end
  end,
  __tostring = function (self) return self.prefix .. "[" .. self.name .. ":" .. self.value .. "]" end
}

cassowary.Variable = cassowary.AbstractVariable {
  varnameprefix = "v",
  _type = "Variable",
  isExternal = true
}

cassowary.DummyVariable = cassowary.AbstractVariable {
  varnameprefix = "d",
  _type = "DummyVariable",
  isDummy = true,
  isRestricted = true,
  value = "dummy"
}

cassowary.ObjectiveVariable = cassowary.AbstractVariable {
  varnameprefix = "o",
  _type = "ObjectiveVariable",
  value = "obj"
}

cassowary.SlackVariable = cassowary.AbstractVariable {
  varnameprefix = "s",
  _type = "SlackVariable",
  value = "slack",
  isPivotable = true,
  isRestricted = true
}

local _multiplier = 1000
cassowary.SymbolicWeight = std.object {
  _type = "SymbolicWeight",
  _init = function ( self, coefficients )
    self.value = 0
    local factor = 1
    while #coefficients > 0 do
      self.value = self.value + ( factor * table.remove(coefficients) )
      factor = factor * _multiplier
    end
    return self
  end
}

cassowary.Strength = std.object {
  _type = "Strength",
  _init = function ( self, name, w1, w2, w3 )
    self.name = name
    if (type(w1) == "table" and a.prototype and a:prototype() == "SymbolicWeight") then
      self.symbolicWeight = w1
    else
      self.symbolicWeight = cassowary.SymbolicWeight { w1; w2; w3 }
    end
    return self
  end,
  isRequired = function ( self ) return self == cassowary.Strength.required end,
  __tostring = function ( self ) return self.name .. (self:isRequired() and "" or ":"..self.symbolicWeight) end
}

cassowary.Strength.required = cassowary.Strength("<Required>", 1000, 1000, 1000 )
cassowary.Strength.strong = cassowary.Strength("strong", 1, 0, 0)
cassowary.Strength.medium = cassowary.Strength("medium", 0, 1, 0)
cassowary.Strength.weak = cassowary.Strength("weak", 0, 0, 1)

cassowary.EditInfo = std.object {_type = "EditInfo"}

cassowary.Error = std.object { _type = "Error", description = "An error has occured in Cassowary" }
cassowary.ConstraintError = cassowary.Error { _type = "ConstraintError", description = "Tried to remove a constraint never added to the tableau" }
cassowary.InternalError   = cassowary.Error { _type = "InternalError" }
cassowary.NonExpression   = cassowary.Error { _type = "NonExpression", description = "The resulting expression would be non" }
cassowary.NotEnoughStays  = cassowary.Error { _type = "NotEnoughStays", description = "There are not enough stays to give specific values to every variable" }
cassowary.RequiredFailure = cassowary.Error { _type = "RequiredFailure", description = "A required constraint cannot be satisfied" }
cassowary.TooDifficult    = cassowary.Error { _type = "TooDifficult", description = "The constraints are too difficult to solve" }

local Set = require("std.set")

cassowary.Tableau = std.object {
  _type = "Tableau",
  _init =  function(self)
    self.columns = {}
    self.rows = {}
    self._infeasibleRows         = Set {}
    self._externalRows           = Set {}
    self._externalParametricVars = Set {}
    return self
  end,
  noteRemovedVariable = function(self, v, subject)
    if cassowary.trace then print("c.Tableau::noteRemovedVariable: ", v, subject) end
    local column = self.columns[v]
    if (subject and column) then column[subject] = nil end
  end,
  noteAddedVariable = function(self, v, subject)
    if subject then self:insertColVar(v,subject) end
  end,
  insertColVar = function (self, paramVar, rowvar)
    local rowset = self.columns[paramVar]
    if not rowset then
      rowset = Set {}
      self.columns[paramVar] = rowset
    end
    Set.insert(rowset, rowvar)
  end,
  addRow = function (self, aVar, expr)
    cassowary:traceFnEnterPrint("addRow: "..aVar..", "..expr)
    self.rows[aVar] = expr
    for clv,coeff in pairs(expr.terms) do 
      self:insertColVar(clv, aVar)
      if clv.isExternal then Set.insert(self._externalParametricVars, clv) end
    end
    if aVar.isExternal then Set.insert(self._externalRows, aVar) end
    cassowary:tracePrint(self.."")
  end,
  removeColumn = function (self, aVar)
    cassowary:traceFnEnterPrint("removeColumn: "..aVar )
    rows = self.columns[aVar]
    if rows then
      self.columns[aVar] = nil
      for clv in Set.iter(rows) do
        local expr = self.rows[clv]
        expr.terms[aVar] = nil
      end
    else
      print("Could not find "..aVar.." in columns")
    end
    if aVar.isExternal then
      Set.delete(self._externalRows, aVar)
      Set.delete(self._externalParametricVars, aVar)
    end
  end,
  removeRow = function (self, aVar)
    cassowary:traceFnEnterPrint("removeRow: "..aVar )
    local expr = self.rows[aVar]
    assert(expr)
    for clv,coeff in pairs(expr.terms) do 
      local varset = self.columns[clv]
      if varset then
        print("Removing from varset "..aVar )
        Set.delete(varset, aVar)
      end
    end    
    Set.delete(self._infeasibleRows, aVar)
    if aVar.isExternal then
      Set.delete(self._externalRows, aVar)
    end
    self.rows[aVar] = nil
    cassowary:traceFnExitPrint("returning "..expr )
    return expr
  end,
  substituteOut = function (self, oldVar, expr)
    if cassowary.trace then
      cassowary:traceFnEnterPrint("substituteOut: "..oldVar)
      print(self)
    end

    local varset = self.columns[oldVar]
    for v in Set.iter(varset) do
      local row = self.rows[v]
      row:substituteOut(oldVar, expr, v, self)
      if v.isRestricted and row.constant < 0 then
        Set.insert(self._infeasibleRows, v)
      end
    end

    if oldVar.isExternal then 
      Set.insert(self._externalRows, oldVar)
      Set.delete(self._externalParametricVars, oldVar)
    end

    self.columns[oldVar] = nil
  end,
  columnsHasKey = function(self, subject)
    return self.columns[subject] ~= nil
  end
}

cassowary.Expression = std.object { 
  _type = "Expression",
  _init = function(self, cvar, value, constant)
    self.hashcode = cassowary.gensym()
    self.constant = type(constant) == "number" and constant or 0
    self.terms = {}
    if type(cvar) == "number" then self.constant = cvar
    elseif type(cvar) == "table" then
      self:setVariable(cvar, type(value) == "number" and value or 1)
    end
    return self
  end,
  initializeFromTable = function(self, constant, terms)
    self.constant = constant
    self.terms = std.table.clone(terms)
    return self
  end,
  multiplyMe = function(self, x)
    self.constant = self.constant * x
    for clv,coeff in pairs(self.terms) do 
      self.terms[clv] = coeff * x
    end
    return self
  end,
  clone = function(self)
    local c = cassowary.Expression.empty()
    c:initializeFromTable(self.constant, self.terms)
    return c
  end,
  times = function(self, x)
    if type(x) == "number" then return (self:clone()):multiplyMe(x)
    elseif self:isConstant() then return x:times(self.constant)
    elseif x:isConstant() then return self:times(x.constant)
    else error(cassowary.NonExpression)
    end
  end,
  plus = function(self, x)
    if x:prototype() == "Expression" then return (self:clone()):addExpression(x, 1)
    elseif x:prototype() == "AbstractVariable" then return (self:clone()):addVariable(x,1)
    end
  end,
  minus = function(self, x)
    if x:prototype() == "Expression" then return (self:clone()):addExpression(x, -1)
    elseif x:prototype() == "AbstractVariable" then return (self:clone()):addVariable(x,-1)
    end
  end,
  divide = function(self, x)
    if type(x) == "number" then 
      if cassowary.approx(x,0) then error(cassowary.NonExpression) else return self:times(1/x) end
    elseif x:prototype() == "Expression" then
      if not x:isConstant() then error(cassowary.NonExpression) else return self:times(1/x.constant) end
    end
  end,
  addExpression = function (self, expr, n, subject, solver)
    if expr:prototype() == "AbstractVariable" then expr = cassowary.Expression.fromVariable(expr) end
    n = type(n) == "number" and n or 1
    self.constant = self.constant + (n * expr.constant)
    for clv,coeff in pairs(expr.terms) do
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
      error(cassowary.InternalError { description = "anyPivotableVariable called on a constant"})
    end
    for clv,coeff in pairs(self.terms) do
      if clv.isPivotable then return clv end
    end
    return nil
  end,
  substituteOut = function (self, outvar, expr, subject, solver)
    local multiplier = self.terms[outvar]
    self.terms[outvar] = nil
    self.constant = self.constant + (multiplier * expr.constant)
    for clv,coeff in pairs(expr.terms) do
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
    for _ in pairs(self.terms) do
      return false
    end
    return true
  end,
  equals = function (self, other)
    if self == other then return true end
    if not (other:prototype() == "Expression" and other.constant == self.constant) then return false end
    -- This is wasteful but I am lazy and lua is fast and most expressions are small
    for k,v in pairs(self.terms) do
      if not (other.terms[k] == v) then return false end
    end
    for k,v in pairs(other.terms) do
      if not (self.terms[k] == v) then return false end
    end
    return true
  end,

  __tostring = function (self) -- worth it for debugging, eh
    local rv = ""
    local needsplus = false
    if (not cassowary.approx(self.constant, 0) or self:isConstant()) then
      rv = rv .. self.constant
      if self:isConstant() then return rv end
      needsplus = true
    end
    for clv, coeff in gPairs(self.terms) do
      if needsplus then rv = rv .. " + " end
      rv = rv .. coeff .. "*" .. clv.value
      needsplus = true
    end
    return rv
  end,
  empty = function() return cassowary.Expression(nil, 1, 0) end,
  fromConstant = function(c) return cassowary.Expression(c) end,
  fromValue    = function(v) return cassowary.Expression(nil, v, 0) end,
  fromVariable = function(v) return cassowary.Expression(v,1,0) end
}

local _constraintStringify = function (self) return self.strength .. " {" .. self.weight .. "} (" .. self.expression .. ")" end

local abcon_init = function (self, strength, weight)
    self.hashcode = cassowary.gensym()
    self.strength = strength or cassowary.Strength.required
    self.weight = weight or 1
    return self
  end

cassowary.AbstractConstraint = std.object {
  _type = "AbstractConstraint",
  isEditConstraint = false,
  isInequality = false,
  isStayConstraint = false,
  _init = function(self, ...)
    local specializer = {}
    local newObject
    local args = {...}
    if args[1] and type(args[1]) == "table" and not args[1].prototype then -- I am inheriting
      specializer = table.remove(args,1)
      newObject = std.object.mapfields(self,specializer)
    else -- I am instantiating
      newObject = std.object.mapfields(self,{})
      newObject:initializer(unpack(args))
    end
    return newObject
  end,
  initializer = abcon_init,
  required = function (self) return self.strength == cassowary.Strength.required end,
  __tostring = _constraintStringify
}

local _editStayInit = function (self, cv, strength, weight)
  self = abcon_init(self, strength,weight)
  self.variable = cv
  self.expression = cassowary.Expression(cv, -1, cv.value)
  return self
end


cassowary.EditConstraint = cassowary.AbstractConstraint {
  _type = "EditConstraint",
  isEditConstraint = true,
  initializer = _editStayInit,
  __tostring = function (self) return "edit: ".._constraintStringify(self) end
}

cassowary.StayConstraint = cassowary.AbstractConstraint {
  _type = "StayConstraint",
  isStayConstraint = true,
  initializer = _editStayInit,
  __tostring = function (self) return "stay: ".._constraintStringify(self) end
}

cassowary.Constraint = cassowary.AbstractConstraint({
  _type = "Constraint",
  initializer = function (self, cle, strength, weight)
    self = cassowary.AbstractConstraint.initializer(self, strength, weight)
    self.expression = cle
    return self
  end,
})

cassowary.Inequality = cassowary.Constraint {
  _type = "Inequality",
  cloneOrNewCle = function (self, cle)
    if type(cle)=="table" and cle.clone then return cle:clone() else return cassowary.Expression(cle) end
  end,
  initializer = function (self, a1, a2, a3, a4, a5)  
    -- This disgusting mess copied from slightyoff's disgusting mess
    if (type(a1) == "number" or a1:prototype() == "Expression") and type(a3) == "table" and a3:prototype() == "AbstractVariable" then
      local cle, op, cv, strength, weight = a1, a2,a3,a4,a5
      self = cassowary.Constraint.initializer(self, self:cloneOrNewCle(cle), strength, weight)
      if op == "<=" then
        self.expression:multiplyMe(-1)
        self.expression:addVariable(cv)
      elseif op == ">=" then
        self.expression:addVariable(cv, -1)
      else
        error(cassowary.InternalError { description = "Invalid operator in c.Inequality constructor"})
      end
    elseif type(a1) == "table" and a1:prototype() == "AbstractVariable" and a3 and (type(a3) == "number" or a3:prototype() == "Expression") then
      local cle, op, cv, strength, weight = a3,a2,a1,a4,a5
      self = cassowary.Constraint.initializer(self, self:cloneOrNewCle(cle), strength, weight)
      if op == ">=" then -- a switch!
        self.expression:multiplyMe(-1)
        self.expression:addVariable(cv)
      elseif op == "<=" then
        self.expression:addVariable(cv, -1)
      else
        error(cassowary.InternalError { description = "Invalid operator in c.Inequality constructor"})
      end
    elseif type(a1) == "table" and a1:prototype() == "Expression" and type(a3) == "number" then
      -- I feel like I'm writing Java
      local cle1, op, cle2, strength, weight = a1,a2,a3,a4,a5
      self = cassowary.Constraint.initializer(self, self:cloneOrNewCle(cle1), strength, weight)
      if op == "<=" then
        self.expression:multiplyMe(-1)
        self.expression:addVariable(self:cloneOrNewCle(cle2))
      elseif op == ">=" then
        -- Just keep turning the crank and the code keeps coming out
        self.expression:addVariable(self:cloneOrNewCle(cle2), -1)
      else
        error(cassowary.InternalError { description = "Invalid operator in c.Inequality constructor"})
      end
    elseif type(a1) == "number" and type(a3) == "table" and a3:prototype() == "Expression" then
      -- Polymorphism makes a lot of sense in strongly-typed languages
      local cle1, op, cle2, strength, weight = a3,a2,a1,a4,a5
      self = cassowary.Constraint.initializer(self, self:cloneOrNewCle(cle1), strength, weight)
      if op == ">=" then
        self.expression:multiplyMe(-1)
        self.expression:addVariable(self:cloneOrNewCle(cle2))
      elseif op == "<=" then
        self.expression:addVariable(self:cloneOrNewCle(cle2), -1)
      else
        error(cassowary.InternalError { description = "Invalid operator in c.Inequality constructor"})
      end
    elseif type(a1) == "table" and a1:prototype() == "Expression" and type(a3) == "table" and a3:prototype() == "Expression" then
      -- but in weakly-typed languages it really doesn't gain you anything.
      local cle1, op, cle2, strength, weight = a1,a2,a3,a4,a5
      self = cassowary.Constraint.initializer(self, self:cloneOrNewCle(cle2), strength, weight)
      if op == ">=" then
        self.expression:multiplyMe(-1)
        self.expression:addExpression(self:cloneOrNewCle(cle1))
      elseif op == "<=" then
        self.expression:addExpression(self:cloneOrNewCle(cle1), -1)
      else
        error(cassowary.InternalError { description = "Invalid operator in c.Inequality constructor"})
      end
    elseif type(a1) == "table" and a1:prototype() == "Expression" then
      self = cassowary.Constraint.initializer(self, a1, a2, a3)
    elseif a2 == ">=" then
      self = cassowary.Constraint.initializer(self, cassowary.Expression(a3), a4, a5)
      self.expression:multiplyMe(-1)
      self.expression:addVariable(a1)
    elseif a2 == "<=" then
      self = cassowary.Constraint.initializer(self, cassowary.Expression(a3), a4, a5)
      self.expression:addVariable(a1,-1)
    else
      error(cassowary.InternalError { description = "Invalid operator in c.Inequality constructor"})
    end
    return self
  end,
  isInequality = true,
  __tostring = function (self)
    return _constraintStringify(self) .. " >= 0) id: ".. self.hashcode
  end
}

cassowary.Equation = cassowary.Constraint {
  _type = "Equation",
  initializer = function (self, a1, a2, a3, a4)
    local isExpression   = function(f) return (type(f)=="table" and f:prototype() == "Expression") end
    local isVariable     = function(f) return (type(f)=="table" and f:prototype() == "AbstractVariable") end
    local isNumber       = function(f) return (type(f)=="number") end
    if (isExpression(a1) and not a2 or type(a2) == "table" and a2:prototype() == "Strength") then
      self = cassowary.Constraint.initializer(self, a1, a2, a3)
    elseif isVariable(a1) and isExpression(a2) then
      local cv,cle,strength,weight = a1,a2,a3,a4
      self = cassowary.Constraint.initializer(self, cle:clone(), strength, weight)
      self.expression:addVariable(cv, -1)
    elseif isVariable(a1) and isNumber(a2) then
      local cv,val,strength,weight= a1,a2,a3,a4
      self = cassowary.Constraint.initializer(self, cassowary.Expression(val), strength, weight)
      self.expression:addVariable(cv, -1)      
    elseif isExpression(a1) and isVariable(a2) then
      local cle,cv,strength,weight= a1,a2,a3,a4
      self = cassowary.Constraint.initializer(self, cle:clone(), strength, weight)
      self.expression:addVariable(cv, -1)
    elseif (isNumber(a1) or isExpression(a1) or isVariable(a1)) and
           (isNumber(a2) or isExpression(a2) or isVariable(a2)) then
      a1 = isExpression(a1) and a1:clone() or cassowary.Expression(a1)
      a2 = isExpression(a2) and a2:clone() or cassowary.Expression(a2)
      self = cassowary.Constraint.initializer(self, a1,a3,a4)
      self.expression:addExpression(a2, -1)
    else
      error("Bad initializer to Equation")
    end
    assert(self.strength:prototype() == "Strength")
    return self
    end,
  __tostring = function(self) return _constraintStringify(self) .. " = 0" end   
}

cassowary.SimplexSolver = cassowary.Tableau {
  _type = "SimplexSolver",
  initializer = function(self)
    cassowary.Tableau.initializer(self)
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
    self.rows[self.objective] = cassowary.Expression.empty
    self.editVariableStack = { 1 }
    if cassowary.trace then
      cassowary:tracePrint("objective expr == "..self.rows[self.objective])
    end
  end,
  add = function (self, ...)
    local args = {...}
    for k=1, #args do self:addConstraint(args[k]) end
    return self
  end,
  addEditConstraint = function (self, cn, eplus_eminus, prevEConstant)
    local i = #{self.editVarMap}
    local cvEplus, cvEminus = eplus_eminus[1], eplus_eminus[2]
    local ei = cassowary.EditInfo { constraint = cn, 
      editPlus = cvEplus, 
      editMinus = cvEminus, 
      prevEditConstant = prevEConstant, 
      index = i }
    self.editVarMap[cn.variable] = ei
    self.editVarList[i+1] = {v = cn.variable, info = ei}
  end,
  addConstraint = function(self, cn)
    cassowary:traceFnEnterPrint("addConstaint: "..cn)
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
  addConstraintNoException = function (self,cn)
    cassowary:traceFnEnterPrint("addConstaintNoException: "..cn)
    return pcall(self.addConstraint, self, cn)
  end,
  addEditVar = function (self, v, strength, weight)
    cassowary:traceFnEnterPrint("addEditVar: " .. v .. " @ " .. strength .. " {" .. weight + "}");
    return self:addConstraint(cassowary.EditConstraint(v, strength or cassowary.Strength.strong, weight));
  end,
  beginEdit = function(self)
    assert(#(self.editVarMap) > 0)
    self.infeasibleRows = Set {}
    self:resetStayConstants();
    self.editVariableStack[#(self.editVariableStack)+1] = #(self.editVarMap)
    return self;
  end,
  endEdit = function ( self )
    assert(#(self.editVarMap) > 0)
    self:resolve()
    table.remove(self.editVariableStack)
    self:removeEditVarsTo(self.editVariableStack[#(self.editVariableStack)])
    return self
  end,
  removeAllEditVars = function(self)
    self:removeEditVarsTo(1)
  end,
  removeEditVarsTo = function(self, n)
    for k=n,#(self.editVarList) do
      if self.editVarList[k] then
        local v = self.editVarMap[k].v
        self:removeConstraint(v.constraint)
      end
      self.editVarList[k] = nil
    end
  end,
  addPointStays = function(self, points)
    cassowary:traceFnEnterPrint("addPointStays: "..points)
    for i = 1,#points do
      local p = points[i]
      self:addStay(p.x, cassowary.Strength.weak, 2^i)
      self:addStay(p.y, cassowary.Strength.weak, 2^i)
    end
    return self
  end,
  addStay = function (self, v, strength, weight)
    local cn = cassowary.StayConstraint(v, strength or cassowary.Strength.weak, weight or 1)
    self:addConstraint(cn)
  end,
  removeConstraint = function (self, cn)
    cassowary:traceFnEnterPrint("removeConstraint: "..cn)
    self.needsSolving = true
    self:resetStayConstants()
    local zrow = self.rows[self.objective]
    local evars = self.errorVars[cn]
    cassowary:tracePrint("evars: "..evars)
    if evars then
      for i =1,#evars do
        local cv = evars[i]
        local expr = self.rows[cv]
        if not expr then
          zrow:addVariable(cv, -cn.weight * cn.strength.symbolicWeight.value, self.objective, self)
        else
          zrow:addExpression(expr, -cn.weight * cn.strength.symbolicWeight.value, self.objective, self)
        end
        cassowary:tracePrint("now evars: "..evars)
      end
    end
    local marker = self.markerVars[cn]
    self.markerVars[cn] = nil
    if not marker then error(cassowary.InternalError { description = "Constraint not found in removeConstraint"}) end
    cassowary:tracePrint("Looking to remove var "..marker)
    if not self.rows[marker] then
      local col = self.columns[marker]
      cassowary:tracePrint("Must pivot - cols are "..col)
      local exitVar
      local minRatio = 0
      for i=1,#col do local v = col[i]
        if v.isRestricted then
          local expr = self.rows[v]
          local coeff = expr:coefficientFor(marker)
          cassowary:tracePrint("Marker "..marker.."'s coefficient in "..expr.." is "..coeff)
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
        for i=1,#col do local v = col[i]
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
        if #col == 0 then self:removeColumn(marker)
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
    if eVars then
      for i=1,#eVars do local v = eVars[i]
        if not (v == marker) then self:removeColumn(v) end
      end
    end
    if cn.isStayConstraint then
      if eVars then 
        for i = 1,#(self.stayPlusErrorVars) do
          eVars[self.stayPlusErrorVars[i]] = nil
          eVars[self.stayMinusErrorVars[i]] = nil
        end
      end
    elseif cn.isEditConstraint then
      assert(evars)
      local cei = self.editVarMap[cn.variable]
      self:removeColumn(cei.editMinus)
      self.editVarMap[cn.variable] = nil
    end

    if eVars then self.errorVars[eVars] = nil end
    if self.autoSolve then
      self:optimize(self.objective)
      self:setExternalVariables()
    end
    return self
  end,
  reset = function (self)
    error(cassowary.InternalError { description = "reset not implemented" })
  end,
  resolveArray = function (self, newEditConstants)
    cassowary:traceFnEnterPrint("resolveArray: "..newEditConstants)
    local l = #newEditConstants
    for v,cei in pairs(self.editVarMap) do
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
  suggestValue = function(self, v, x)
    cassowary:traceFnEnterPrint("suggestValue: "..v.. " "..x)
    local cei = self.editVarMap[v] or error(cassowary.Error {description = "suggestValue for variable " .. v .. ", but var is not an edit variable"})
    local delta = x - cei.prevEditConstant
    cei.prevEditConstant = x
    self:deltaEditConstant(delta, cei.editPlus, cei.editMinus)
  end,
  solve = function (self)
    if not self.needsSolving then return self end
    self:optimize(self.objective)
    self:setExternalVariables()
    return self
  end,
  setEditedValue = function(self, v, n)
    assert("Nobody calls this")
  end,
  addVar = function (self, v)
    assert("Or this")
  end,
  getInternalInfo = function(self)
    error("Unimplemented")
  end,
  addWithArtificialVariable = function (self, expr)
    self.artificialCounter = self.artificialCounter + 1
    local av = cassowary.SlackVariable { value = self.artificialCounter, prefix = "a"}
    local az = cassowary.ObjectiveVariable { name = "az" }
    local azRow = expr:clone()
    self:addRow(az, azRow)
    self:addRow(av, expr)
    self:optimize(az)
    local azTableauRow = self.rows[az]
    if not cassowary.approx(azTableauRow.constant, 0) then
      self:removeRow(az)
      self:removeColumn(av)
      error(cassowary.RequiredFailure)
    end
    local e = self.rows[av]
    if e then
      if e.isConstant then
        self:removeRow(az)
        self:removeColumn(av)
        return
      end
      self:pivot(e:anyPivotableVariable(), av)
    end
    assert(not self.rows[ev])
    self:removeRow(az)
    self:removeColumn(av)
  end,
  tryAddingDirectly = function (self, expr)
    cassowary.traceFnEnterPrint("tryAddingDirectly "..expr)
    local subject = self:chooseSubject(expr)
    if not subject then
      cassowary.traceFnExitPrint("Returning false")
      return false
    end
    expr:newSubject(subject)
    if self:columnsHasKey(subject) then
      self:substituteOut(subject, expr)
    end
    self:addRow(subject, expr)
    cassowary.traceFnExitPrint("Returning true")
    return true
  end
}

return cassowary
