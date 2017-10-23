package.path = package.path .. ";./?.lua;./?/init.lua;./init.lua"

local HooFSM = require('HooFSM')



describe('HooFSM', function()
    local fsm
    local state, state1, state2
    local transition, transition1, transition2
    local condition, condition1, condition2
    local c, c1, c2

    setup(
    function()
        c, c1, c2 = false, false, false
        function getC() return c end
        function getC1() return c1 end
        function getC2() return c2 end
    end
    )

    before_each(
        function()
            c, c1, c2 = false, false, false
            fsm = HooFSM.StateMachine()
            state = HooFSM.State("State")
            state1 = HooFSM.State("State1")
            state2 = HooFSM.State("State2")
            transition = HooFSM.Transition(state)
            transition1 = HooFSM.Transition(state1)
            transition2 = HooFSM.Transition(state2)
            condition = getC 
            condition1 = HooFSM.Condition(getC1)
            condition2 = HooFSM.Condition(getC2)
        end
    )

    it('StateMachine:addState() adds a state to the machine', function()
        assert.are.equal(#fsm.states, 0)
        fsm:addState(state)
        assert.are.equal(#fsm.states, 1)
    end)

    it('State:addTransition() adds a transition to the state', function()
        assert.are.equal(#state.transitions, 0)
        state:addTransition(transition)
        assert.are.equal(#state.transitions, 1)
    end)

    it('Transition:addCondition() adds a condition to the transition and removes default "true" condition.', function()
        assert.are.equal(#transition.conditions, 1)
        transition:addCondition(condition)
        assert.are.equal(#transition.conditions, 1)
        transition:addCondition(condition1)
        assert.are.equal(#transition.conditions, 2)
    end)

    it('Transition:check() will only return true if all conditions are met', function()
        assert.are.equal(transition:check(), true)
        transition:addCondition(condition)
        assert.are.equal(transition:check(), false)
        c = true
        assert.are.equal(transition:check(), true)
        transition:addCondition(condition1)
        assert.are.equal(transition:check(), false)
        c1 = true
        assert.are.equal(transition:check(), true)
        c = false
        assert.are.equal(transition:check(), false)
    end)

    it('fsm:addState() replaces the empty default state as active state', function()
        fsm:addState(state)
        assert.are.equal(fsm.activeState, state)
    end)

    it('fsm() (instance of StateMachine) will transition to a second state with default condition', function()
        state:addTransition(transition1)
        fsm:addState(state)
        fsm:addState(state1)
        assert.are.equal(fsm.activeState, state)
        fsm()
        assert.are.equal(fsm.activeState, state1)
    end)

    it('fsm() (instance of StateMachine) will transition to a second state only if conditions are met', function()
        transition1:addCondition(condition)
        state:addTransition(transition1)
        fsm:addState(state)
        fsm:addState(state1)
        assert.are.equal(fsm.activeState, state)
        fsm()
        assert.are.equal(fsm.activeState, state)
        c = true
        fsm()
        assert.are.equal(fsm.activeState, state1)
    end)

    it('fsm() (instance of StateMachine) will call callback functions during transition', function()
        state.onExit = function() c1 = true end
        state1.onEnter = function() c2 = true end

        state:addTransition(transition1)
        fsm:addState(state)
        fsm:addState(state1)
        assert.are.equal(c1, false)
        assert.are.equal(c2, false)
        fsm()
        assert.are.equal(c1, true)
        assert.are.equal(c2, true)
    end)

    it('Condition(f, t) works with or without table', function()
        condition = HooFSM.Condition(getC)
        assert.are.equal(condition:check(), false)
        c = true 
        assert.are.equal(condition:check(), true)

        local condi = {getC1 = getC1}
        condition1 = HooFSM.Condition(condi.getC1, condi)
        assert.are.equal(condition1:check(), false)
        c1 = true
        assert.are.equal(condition1:check(), true)
    end)
end)
