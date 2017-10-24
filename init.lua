local HooFSM = {}
HooFSM.debugging = false
HooFSM.debugMode = "print"
HooFSM.debug = function(...)
	if HooFSM.debugging then
		if HooFSM.debugMode == "print" then
			print(...)
		elseif HooFSM.debugMode == "error" then
			local errorString = ""
			for _, entry in pairs({...}) do
				errorString = errorString .. tostring(entry) .. "\t"
				error(errorString, 2)
			end
		else
			print("[!] HooFSM.debug() error! Invalid debug mode! 'print' or 'error' expected. Got " .. HooFSM.debugMode)
		end
	end
end

HooFSM.MetaStateMachine = {
    __call = function(self, states, initialState)
        local newStateMachine = {}
        newStateMachine.states = states or {}
        newStateMachine.activeState = initialState or {transitions={}}
        setmetatable(newStateMachine, HooFSM.StateMachine.Mt)
        newStateMachine.__call = self.updateStateMachine

        if #newStateMachine.states == 0 and initialState then
        	table.insert(newStateMachine.states, initialState)
        end

        return newStateMachine
    end;
}

HooFSM.StateMachine = {
	Mt = {
		__index = function(t, k) 
			if HooFSM.StateMachine[k] then 
				return HooFSM.StateMachine[k] 
			elseif t.activeState then
				return t.activeState[k]
			end
		end;
        __call = function(t, ...) t:updateStateMachine(...) end
	};

	-- If a transition condition is met, call :onExit(newState, ...) on the previous state 
	-- and :onEnter(previousState, ...) on the new one.
	updateStateMachine = function(self, ...)
		for _, transition in ipairs(self.activeState.transitions) do
			if transition:check() then
				self.activeState:onExit(transition.target, ...)
				transition.target:onEnter(self.activeState, ...)
				self:setActiveState(transition.target)
				break
			end
		end
	end;

	addState = function(self, newState, setActiveState)
		setActiveState = setActiveState or false
		if newState then
			if #self.states == 0 then
				setActiveState = true
			end

			table.insert(self.states, newState)

			if setActiveState then
				self.activeState = newState
			end
		else
			HooFSM.debug("[!] HooFSM.StateMachine:addState() error! No newState supplied!")
		end

		return self
	end;

	setActiveState = function(self, newState)
		if newState then
			local contained = false
			for _, state in ipairs(self.states) do
				if state == newState then
					contained = true
					break
				end
			end

			if not contained then
				self:addState(newState)
			end

			self.activeState = newState
		else
			HooFSM.debug("[!] HooFSM.StateMachine:setActiveState() error! No newState supplied!")
		end
	end;

	getActiveState = function(self)
		return self.activeState
	end;
}
setmetatable(HooFSM.StateMachine, HooFSM.MetaStateMachine)

HooFSM.MetaState = {
	__call = function(self, name)
		local newState = {
			transitions = {};
		}
		setmetatable(newState, HooFSM.State.Mt)
		newState.name = name or "Generic State"

		return newState
	end;
}

HooFSM.State = {
	Mt = {
		__index = function(t, k) return HooFSM.State[k] end;
	};

	addTransition = function(self, newTransition)
		if type(newTransition) == "table" then
			if not type(newTransition.check) == "function" then
				newTransition.check = HooFSM.Transition.defaultCheck
			end
			table.insert(self.transitions, newTransition)
		else
			HooFSM.debug("[!] HooFSM.State.addTransition() error! No newTransition of type 'table'!")
		end

		return self
	end;

	onEnter = function() end;
	onExit = function() end;
}
setmetatable(HooFSM.State, HooFSM.MetaState)

-- Defines a transition between states. 
-- self.target, self.conditions, self:check, self:addCondition
HooFSM.MetaTransition = {
	__call = function(self, target, conditions)
		if not target then
			HooFSM.debug("[!] HooFSM.Transition.__call() error! No target supplied!")
			return
		end
		local newTransition = {}
		setmetatable(newTransition, HooFSM.Transition.Mt)
		newTransition.target = target
		if conditions then
			for k, v in ipairs(conditions) do
				HooFSM.Transition.addCondition(newTransition, v)
			end
		else
			newTransition.conditions = { {check = HooFSM.Transition.defaultCheck} }
		end

		return newTransition
	end;
}

HooFSM.Transition = {
	Mt = {
		__index = function(t, k) return HooFSM.Transition[k] end;
	};

	defaultCheck = function()
		return true
	end;

	check = function(self) 
		for _, condition in ipairs(self.conditions) do
			local fulfilled = false
			if condition.t then
				fulfilled = condition.check(condition.t)
			else
				fulfilled = condition:check()
			end
			if not fulfilled then
				return false
			end
		end

		return true
	end;

	addCondition = function(self, newCondition, index)
		if newCondition then
			if type(newCondition) == "function" then
				local func = newCondition
				newCondition = {check = func}
			end
			if type(newCondition) == "table" then
				if type(newCondition.check) == "function" then
					if #self.conditions == 1 then
						if self.conditions[1].check == HooFSM.Transition.defaultCheck then
							table.remove(self.conditions, 1)
						end
					end
					if index then
						if index > #self.conditions then
							index = #self.conditions
						end
						table.insert(self.conditions, index, newCondition)
					else
						table.insert(self.conditions, newCondition)
					end
				else
					HooFSM.debug("[!] HooFSM.Transition:addCondition() error! newCondition:check() does not exist!")
				end
			else
				HooFSM.debug("[!] HooFSM.Transition:addCondition() error! newCondition is not a table!")
			end
		else
			HooFSM.debug("[!] HooFSM.Transition:addCondition() error! No newCondition supplied!")
		end

		return self
	end;
}
setmetatable(HooFSM.Transition, HooFSM.MetaTransition)

-- Defines a condition to be met for state transition
-- self:check
HooFSM.Condition = function(conditionCheck, table)
	local newCondition = {}
	newCondition.t = table
	newCondition.check = conditionCheck

	return newCondition
end

return HooFSM