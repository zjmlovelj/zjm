-- File to store constants shared across files
local common = {}

-- Start: Compiler output table keys
common.MAIN = 'main'
common.TEARDOWN = 'teardown'
common.TESTS = 'Tests'
common.ACTIONS = 'Actions'
common.LIMITS = 'limits'
common.CONDITIONS = 'conditions'
common.SAMPLING = 'samplings'
common.LIMIT_INFO = 'limitInfo'
common.TEST_PLAN_ATTRIBUTE = 'testPlanAttribute'

common.MAIN_TESTS = common.MAIN .. common.TESTS
common.MAIN_ACTIONS = common.MAIN .. common.ACTIONS
common.TEARDOWN_TESTS = common.TEARDOWN .. common.TESTS
common.TEARDOWN_ACTIONS = common.TEARDOWN .. common.ACTIONS
-- End: Compiler output table keys

-- Start: Coverage/limit filters
common.MODE = 'mode'
common.PRODUCT = 'product'
common.STATION_TYPE = 'stationType'

common.Column = {
    Product = 'Product',
    StationType = 'StationType',
    Mode = 'Mode'
}
common.ALL_FILTERS = {
    [common.Column.Product] = common.PRODUCT,
    [common.Column.StationType] = common.STATION_TYPE,
    [common.Column.Mode] = common.MODE
}
-- End: Coverage/limit filters

-- Start: Keys for sampling
common.ENABLE_SAMPLING_FLAG = "EnableSampling"
common.ENABLE_SAMPLING_VALIDATOR =
{ type = 'IN', allowedList = { "YES", "NO" } }
-- End: Keys for sampling

-- Start: Keys for conditions
common.CONDITION_TYPE = { 'group', 'init', 'test' }
common.CONDITION_REMOVE_TYPE = { 'group', 'init' }
-- End: Keys for conditions

-- Start: Fields for format checking
common.TECHNOLOGY = 'technology'
common.COVERAGE = 'coverage'
common.TEST_PARAMETERS = 'testParameters'
common.VARIABLE_NAME = 'varName'
common.CONDITION_NAME = 'conditionName'
common.SAMPLE_GROUP_NAME = 'sampleGroupName'
-- End: Fields for format checking

-- Start: limit field names
common.RELAXED_LOWER_LIMIT = 'RelaxedLowerLimit'
common.LOWER_LIMIT = 'LowerLimit'
common.UPPER_LIMIT = 'UpperLimit'
common.RELAXED_UPPER_LIMIT = 'RelaxedUpperLimit'
-- End: limit field names

-- Start: Limit version
common.INSIGHT_SOFTWARE_VERSION_LENGTH_MAX = 48
common.LIMIT_VERSION_HASH_LENGTH = 7
-- End: Limit version

-- Start: Test definition keys
-- A nested table which defines the data-type and required/optional keys at each level.
-- Each (required/optional) key must have a dataType, which is an array of allowed Lua types for that key.
-- Ex: plugins.dataType = {'table', 'string'}
common.TEST_DEF_KEYS = {
    dataType = { 'table' },
    requiredKeys = {
        technology = { dataType = { 'string' } },
        coverage = { dataType = { 'string' } },
        testParameters = { dataType = { 'string' } },
        sequence = {
            dataType = { 'table' },
            requiredKeys = {
                actions = {
                    dataType = { 'table' },
                    requiredKeys = { filename = { dataType = { 'string' } } },
                    optionalKeys = {
                        args = {
                            -- List of user defined values. No subkeys.
                            dataType = { 'table' }
                        },
                        plugins = {
                            -- List of user defined values, or '*'. No subkeys.
                            dataType = { 'table', 'string' }
                        },
                        policy = { dataType = { 'string' } },
                        background = { dataType = { 'boolean' } },
                        deps = {
                            -- List of user defined values. No subkeys.
                            dataType = { 'table' }
                        },
                        dataQuery = { dataType = { 'boolean' } }
                    }
                }
            },
            optionalKeys = {
                -- 'type' is the name of a key
                type = { dataType = { 'string' } }
            }
        }
    },
    optionalKeys = {
        inputs = {
            -- User defined keys and values, so no required/optional subkeys
            dataType = { 'table' }
        },
        outputs = {
            dataType = { 'table' },
            requiredKeys = { lookup = { dataType = { 'table' } } }
        },
        conditions = {
            dataType = { 'table' },
            requiredKeys = { lookup = { dataType = { 'table' } } }
        }
    }
}
-- End: Test definition keys

common.actionsType = { sequential = 'sequential', graph = 'graph' }

-- Start: Keys in compiler output
common.REQUIRED_COVERAGE_KEYS = {
    'mainActions',
    'mainTests',
    'limits',
    'testPlanAttribute'
}
common.OPTIONAL_COVERAGE_KEYS = {
    'samplings',
    'conditions',
    'teardownTests',
    'teardownActions',
    'limitInfo',
    'DisableOrphanedRecordChecking'
}
-- End: Keys in compiler output

-- Start: Magic numbers
common.NUM_FIELDS_IN_DEPS = 3
common.NUM_LIMIT_SPEC = 4
common.NUM_ACTION_SPEC = 4
common.NUM_TEST_SPEC = 3
common.NUM_VAR_SPEC = 4
common.NUM_HEADER_LINES = 1
common.MAX_LENGTH_OF_STATION_VERSION_WITH_DIVIDER = 47
common.MAX_LENGTH_OF_STATION_VERSION = 48
common.DEVICE_RESULT_RETURN_IDX = 4
-- End: Magic numbers

-- Start: ConditionEvaluator token type
common.TOKEN_TYPE_IDENTIFIER = 'identifier'
common.TOKEN_TYPE_OPERATOR = 'operator'
common.TOKEN_TYPE_VALUE = 'value'
common.TOKEN_TYPE_QUOTED_STRING = 'quotedString'
common.TOKEN_TYPE_GROUP = 'group'
-- End: ConditionEvaluator token type

-- Start: Special characters to escape in testParameters
-- E.g. These are the magic characters in Lua patterns, except for '*' (allowed for wildcard matches)
-- '[' and ']' are also omitted since they are not allowed in testParameters from loop syntax
-- '%' is handled separately
common.MAGIC_CHARACTERS = { '%(', '%)', '%.', '%+', '%-', '%?', '%^', '%$' }
-- End: Special characters to escape in testParameters

-- Start: Format style for various fields
-- Formats applied to each field during compilation.
common.FIELD_FORMAT = {
    [common.TECHNOLOGY] = {
        ['format'] = '[_a-zA-Z][_a-zA-Z0-9-]*',
        ['isRequired'] = true
    },
    [common.COVERAGE] = {
        ['format'] = '[_a-zA-Z][_a-zA-Z0-9-]*',
        ['isRequired'] = true
    },
    -- Shark: before adding loop support, TestParameters can be any printable char
    -- including alphanumers + all punctuation: !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~)
    -- Adding loop means [] is blocked.
    -- TODO: need to check if we should allow the others
    [common.TEST_PARAMETERS] = { ['format'] = '[^%[%]]*', ['isRequired'] = false },
    [common.VARIABLE_NAME] = {
        ['format'] = '[_a-zA-Z][_a-zA-Z0-9]*',
        ['isRequired'] = true
    },
    [common.CONDITION_NAME] = {
        ['format'] = '^[a-zA-Z_][0-9a-zA-Z_]*$',
        ['isRequired'] = true
    },
    [common.SAMPLE_GROUP_NAME] = {
        ['format'] = '^[a-zA-Z_][0-9a-zA-Z_]*$',
        ['isRequired'] = true
    }
}
-- End: Format style for various fields

-- Special Technology in Limit table to disable orphaned record checking
common.DisableOrphanedRecordChecking = 'DisableOrphanedRecordChecking'

common.operatorMap = {
    ['=='] = 'EQ',
    ['~='] = 'NE',
    ['>'] = 'GT',
    ['<'] = 'LT',
    ['>='] = 'GE',
    ['<='] = 'LE',
    ['('] = 'LP',
    [')'] = 'RP'
}

-- Key meanings:
-- Tests - conditions/Product/StationType used in Main.csv
-- TestInputs - conditions used in yaml test block inputs key
-- TestConditions - conditions used in yaml test block conditions key (e.g. generating test conditions)
-- Limits - Product/StationType in Limits.csv
-- LimitRequired - conditions used in Required column
-- LimitConditions - conditions used in Conditions column of Limits.csv
common.conditionUsage = {
    Tests = true,
    TestInputs = true,
    TestConditions = true,
    Limits = true,
    LimitRequired = true,
    LimitConditions = true
}

return common
