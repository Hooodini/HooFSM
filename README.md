# HooFSM

[![Build Status](https://travis-ci.org/Hooodini/HooFSM.svg?branch=master)](https://travis-ci.org/Hooodini/HooFSM)

HooFSM is a lightweight and flexible finite statemachine implementation with a debugging interface that's inteded to spot issues early on and help you create solid code.

## Installation

HooFSM is exclusively contained in the init.lua. For clarity and easy updates I would recommend adding it as a submodule to your project.

Example of how to include HooFSM in your project:


```lua
local HooFSM = require('HooFSM')
HooFSM.debugging = true
HooFSM.debugMode = "error"
```

## Debugging

As you can see in the above example. There are two variables in HooFSM. 


| Name | Type | Default | Meaning |
| --- | --- | --- | --- |
| debugging | boolean | false | Enables the debugging mode. Errors will be handled. |
| debugMode | string | "print" | Offers two options. 'print' and 'error'. Print will print an error message to stdout. Error will raise an error with stacktrace. |

## Using the active state

You can use the state machine instance to access, insert or call any values or functions in the active state.
Example:
```lua
StateMachine:update(dt) -- Calls update on the active state, unless update is a function defined by StateMachine.
print(StateMachine.someVar) -- Returns someVar from the active state, unless someVar is a variable of StateMachine.
StateMachine.newVar = 42 -- Assigns newVar to the active state. 
```

## API

### HooFSM.StateMachine

#### HooFSM.StateMachine(states, initialState)

- (optional) **states** (Table) - An array table containing states.
- (optional) **initialState** (State) - The state that should be active initially. onEnter() will not be called. 

Returns a new state machine instance.

**Note:** If created without an initialState, an empty state with no transitions is added. You have to manually assign a state with :setActiveState(state)

### StateMachine instance

#### StateMachine(...)

Will call StateMachine:updateStateMachine(...).

#### StateMachine:updateStateMachine(...)

- (optional) **...** - An arbitrary list of parameters. Will be passed to the callbacks onEnter and onExit as is.

#### StateMachine:addState(newState, setActive)

- **newState** (State) - The new state to be added to the state machine.
- (optional) **setActive** (bool) - If true will set the state active without callbacks (onExit / onEnter).

Returns StateMachine.

The state can only be reached if a transition from the active state towards it exists.

#### StateMachine:setActiveState(newActiveState)

- **newActiveState** (State) - Sets a new state as active state. 

This function sets a state as the new active state. If the state is not yet in the list of states, it will be added.

#### StateMachine:getActiveState()

Returns the currently active state. 

### HooFSM.State

#### HooFSM.State(name) 

- **name** (string) - The name of this state. If none is supplied it will be named "Generic State".

Returns a new State instance. 

### State instance

#### State:addTransition(newTransition)

- **newTransition** (Transition) - Adds a new transition to the state. 

Returns State. 

#### State:onEnter(...)

Overwrite this function if you want to react when the state is entered.

#### State:onExit(...)

Overwrite this function if you want to react when this state is left. 

### HooFSM.Transition

#### HooFSM.Transition(target, conditions)

- **target** (State) - The state to transition to.
- **conditions** (Table) - A table containing conditions. Conditions can either be a Condition object or a function.

**Note:** If no conditions are supplied, a default condition is added which always evaluates to true. This will be removed upon adding a condition.

### Transition instance

#### Transition:addCondition(newCondition, index)

- **newCondition** (Condition or function) - A Condition object or a function to be used for checking.
- **index** (number (integers only!)) - The index this condition should be entered at.

Returns Transition.

**Note:** Conditions are checked in order. If you have a lot of them, make sure the ones more likely to fail are at the top for a bit of performance!

#### Transition:check()

Returns whether or not this transition is valid at this time.

### HooFSM.Condition

#### HooFSM.Condition(condition, table)

- **condition** (function) - The function to be used for checking. Should return true if successful.
- **table** (arbitrary) - Arbitrary value passed as first parameter to the condition function. Useful to pass self or any other value you might want to have upon function check.


