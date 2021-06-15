local pl = require 'pl.import_into'()

local query = {}

--- Ask the user to provide some input and repeats until he provides something
-- that is useful. This function is kind of bare bones but powerful, so the
-- idea is that you will probably want to create functions that call this with
-- more easy to use interfaces for a specific type of question eg a yes no
-- question or a textual question with a default or a number or whatever.
-- @param question is the prompt text given before input.
-- @param validator is called on the user input and determines whether or not
--        it is correct and returns it's own version of it, which can be used
--        to implement case insensitivity or defaults or whatever.
-- @return the answer that got through the validator
function query.ask(question, validator)
    while true do
        io.write(question)
        local answer = io.read()
        local result, err = validator(answer)
        if result then return result end
        if err ~= nil then io.write(err, '\n')
        else io.write('Invalid answer\n') end
    end
end

--- Asks a yes or no answer
-- @param question is the question to ask to which (y/n) is added.
-- @return a boolean
function query.bool(question)
    return query.ask(question..' (Y/N) ', function (answer)
        local start = answer:sub(1, 1)
        if start == 'y' or start == 'Y' then return 'y'
        elseif start == 'n' or start == 'N' then return 'n'
        else return nil, '(Y/N)' end
    end) == 'y'
end

--- Asks for a string input and has a default.
-- @param question is the question to ask, to which (default) will be appended.
-- @param default is the answer returned if the user inputs nothing
-- @return the user's input or the default
function query.string(question, default)
    if default then question = question..' ('..default..')' end
    return query.ask(question..' ', function (answer)
        if answer == '' and default then return default
        elseif answer ~= '' then return answer end
        return nil, 'must provide a value'
    end)
end

--- Gives user a set selection of choices and makes them choose one.
-- @param question is what to ask besides the choices.
-- @param ... is the list of choices.
-- @return one of the choices.
function query.choice(question, ...)
    local args = {...}
    local keys = pl.tablex.makeset(args)
    question = question..' ('
    for k, v in ipairs(args) do
        if k > 1 then question = question..'/' end
        question = question..v
    end
    question = question..') '
    return query.ask(question, function (answer)
        if keys[answer] then return answer
        else return false end
    end)
end

return query
