local errors = require("Schooner.Compiler.Errors")
local helper = require('Schooner.SchoonerHelpers')
local dump = helper.dump
local C = require('Schooner.Compiler.CompilerHelpers')
local common = require('Schooner.SchoonerCommon')

local Condition = {}

-- predefined When column values
Condition.WHEN = { 'Group', 'Init', 'Test' }

-- name: alphanumeric_-
function Condition.validateName(conditions)
    local names = {}
    for _, condition in ipairs(conditions) do
        local name = condition.Name
        if string.lower(name) == common.MODE then
            errors:invalidConditionName(name)
        end
        if names[name] ~= nil then
            errors:duplicatedConditionName(name)
        end
        names[name] = true
        C.checkFieldFormat(name, common.CONDITION_NAME, 'badSpecFieldFormat')
    end
end

function Condition.validateWhen(conditions)
    for _, condition in ipairs(conditions) do
        local when = condition.When
        if helper.hasVal(Condition.WHEN, when) == false then
            errors:invalidConditionWhen(condition.Name, when,
                                        dump(Condition.WHEN))
        end
        -- EnableSampling does not have group condition
        if condition.Name == common.ENABLE_SAMPLING_FLAG and when == 'Group' then
            errors:invalidSamplingConditionType()
        end
    end
end

function Condition.parseAndValidateGenerator(conditions)
    for _, condition in ipairs(conditions) do
        local name = condition.Name
        local when = condition.When
        local generator = condition.Generator
        if when == 'Test' and generator ~= "" then
            errors:testConditionHasGenerator(name, generator)
        end

        if when == 'Group' or when == 'Init' then
            if generator == '' then
                errors:conditionMissingGenerator(name)
            end
            -- Module path can start with dash/underscore, but not dot/slash
            local patternModule = '([a-zA-Z_%-][0-9a-zA-Z/_%.%-]*)'
            local patternFunction = '([a-zA-Z_][0-9a-zA-Z_]*)'
            local pattern = '^' .. patternModule .. ':' .. patternFunction ..
                            '$'
            local module, func = generator:match(pattern)
            if module == nil or func == nil then
                errors:invalidConditionGeneratorFormat(name, generator, pattern)
            end

            -- update generator to parsed value
            condition.generator = { module = module, func = func }
        end
    end
end

function Condition.parseAndValidateValidator(conditions)
    for i, condition in ipairs(conditions) do
        errors:pushLocation('Condition CSV row ' .. i + common.NUM_HEADER_LINES)
        local name = condition.Name
        local validator = condition.Validator

        if name == common.ENABLE_SAMPLING_FLAG then
            goto continue
        end
        -- predefined condition [ENABLE_SAMPLING] shall not have user-defined validator
        if validator == '' then
            errors:conditionMissingValidator(name)
        end

        -- support format:
        -- 1. modulePath:function
        -- 2. IN(commaSeparatedArray)
        -- 3. RANGE(min, max)
        -- Module path can start with dash/underscore, but not dot/slash
        local patternModule = '([a-zA-Z_%-][0-9a-zA-Z/_%.%-]*)'
        local patternFunction = '([a-zA-Z_][0-9a-zA-Z_]*)'
        local patternModuleFunction = '^' .. patternModule .. ':' ..
                                      patternFunction .. '$'
        local patternIN = '^IN%((.+)%)$'
        local patternCommaSeparatedArray = '([^,]+),'

        local patternRANGE = '^RANGE%(%s*([^,]-)%s*,%s*([^,]-)%s*%)$'

        if validator:match(patternModuleFunction) ~= nil then
            local module, func = validator:match(patternModuleFunction)
            condition.validator = {
                type = 'moduleFunction',
                module = module,
                func = func
            }
        elseif validator:match(patternIN) ~= nil then
            local strArray = validator:match(patternIN)
            local array = {}
            -- strArray is like "1", "1, 2" or "1, 2, 3".
            -- strip the ending spaces
            -- append "," so every item in the array match patternCommaSeparatedArray
            strArray = strArray:gsub('[ \t]$', '') .. ','
            for k in strArray:gmatch(patternCommaSeparatedArray) do
                -- strip heading and tailing spaces
                k = k:gsub('[ \t]$', '')
                k = k:gsub('^[ \t]', '')
                -- k should be
                -- 1. number string as number, like 1
                -- 2. or boolean string true or false
                -- 3. or a double/single quoted string, as string, like "1"
                if tonumber(k) then
                    table.insert(array, tonumber(k))
                elseif k == 'true' or k == 'false' then
                    table.insert(array, k == 'true')
                else
                    local patternSingleQuoted = "^'([^']+)'$"
                    local patternDoubleQuoted = '^"([^"]+)"$'
                    local strWithoutQuote =
                    k:match(patternSingleQuoted) or k:match(patternDoubleQuoted)
                    if (strWithoutQuote) then
                        table.insert(array, strWithoutQuote)
                    else
                        errors:invalidConditionValidatorFormat(name, validator)
                    end
                end
            end

            if next(array) == nil then
                -- no allowed value, not supported.
                errors:conditionValidatorEmptyIN(name)
            end

            -- At first allowedList is converted to key-value dict for quicker "in" check later
            -- for example {"a", "b"} --> {"a"=true, "b"=true}
            -- But later found that this doesn't work for number:
            -- {0, 5} --> {[0]=true, [5]=true}: Atlas cannot convert number-key table into OC
            -- and Atlas will exception on this, with exception number being the 1st number; 0 in this case.
            -- so just keep it as an array
            local allowedList = array

            condition.validator = { type = 'IN', allowedList = allowedList }
        elseif validator:match(patternRANGE) ~= nil then
            local min, max = validator:match(patternRANGE)
            local numMin = tonumber(min)
            if numMin == nil then
                errors:conditionValidatorInvalidMinInRANGE(name, validator, min)
            end
            local numMax = tonumber(max)
            if numMax == nil then
                errors:conditionValidatorInvalidMaxInRANGE(name, validator, max)
            end

            condition.validator = { type = 'RANGE', min = numMin, max = numMax }
        else
            errors:invalidConditionValidatorFormat(name, validator)
        end
        errors:popLocation()
        ::continue::
    end
end

function Condition.removeUnusedField(conditions)
    for _, condition in ipairs(conditions) do
        condition.Generator = nil
        condition.Validator = nil
    end
end

-- split condition defs into 3 types as conditions.group, conditions.init and conditions.test
-- also set condition.name from condition.Name to align with other keys like
-- generator and validator.
function Condition.categorize(conditions)
    local group = {}
    local init = {}
    local test = {}
    for _, condition in ipairs(conditions) do
        if condition.When == 'Group' then
            condition.When = nil
            table.insert(group, condition)
        elseif condition.When == 'Init' then
            condition.When = nil
            table.insert(init, condition)
        elseif condition.When == 'Test' then
            condition.When = nil
            table.insert(test, condition)
        else
            error('SHOULD NOT REACH HERE: Unsupported condition WHEN: ' ..
                  condition.When)
        end
        condition.name = condition.Name
        condition.Name = nil
    end

    -- if empty, do not output
    if next(group) == nil then
        group = nil
    end
    if next(init) == nil then
        init = nil
    end
    if next(test) == nil then
        test = nil
    end

    return { group = group, init = init, test = test }
end

function Condition.findKeywordInConditions(conditions, keyword)
    for when, _ in pairs(conditions) do
        if when == 'test' then
            goto continue
        end
        for _, condition in ipairs(conditions[when]) do
            if condition.name == keyword then
                return true
            end
        end
        ::continue::
    end
    return false
end

function Condition.handleProductAsCondition(conditions)
    if conditions.group == nil then
        conditions["group"] = {}
    end
    table.insert(conditions.group, {
        ["validator"] = {
            ["module"] = "Schooner/DefaultConditionGeneratorAndValidator",
            ["func"] = "returnTrue",
            ["type"] = "moduleFunction"
        },
        ["generator"] = {
            ["func"] = "product",
            ["module"] = "Schooner/DefaultConditionGeneratorAndValidator"
        },
        ["name"] = "Product"
    })
end

function Condition.handleStationTypeAsCondition(conditions)
    if conditions.group == nil then
        conditions["group"] = {}
    end
    table.insert(conditions.group, {
        ["validator"] = {
            ["module"] = "Schooner/DefaultConditionGeneratorAndValidator",
            ["func"] = "returnTrue",
            ["type"] = "moduleFunction"
        },
        ["generator"] = {
            ["func"] = "stationType",
            ["module"] = "Schooner/DefaultConditionGeneratorAndValidator"
        },
        ["name"] = "StationType"
    })
end

-- parse Conditions CSV and return parsed condition table (group based on WHEN type)
-- to be used by runner
-- @param conditionCSV    string, path of conditionCSV file
function Condition.processConditions(conditionCSV)
    if conditionCSV == nil then
        -- No condition CSV is provided; supported.
        return {}
    end
    errors:pushLocation(conditionCSV)

    local header, conditions = C.loadCSV(conditionCSV, common.CONDITIONS)
    -- if path is given, it should have valid header.
    C.validateHeader(conditionCSV, header, common.CONDITIONS)

    Condition.validateName(conditions)
    Condition.validateWhen(conditions)
    Condition.parseAndValidateGenerator(conditions)
    Condition.parseAndValidateValidator(conditions)
    Condition.removeUnusedField(conditions)
    local ret = Condition.categorize(conditions)
    errors:popLocation()
    return ret
end

return Condition
