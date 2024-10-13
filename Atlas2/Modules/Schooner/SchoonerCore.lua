require "GroupStateMachine"

local M = {}
local conditionRunner = require("Schooner.ConditionRunner")
local schooner = require("Schooner.SchoonerStationInfo")
local helpers = require("Schooner.SchoonerHelpers")
local limitsRecordsSanitizer =
require("Schooner.SchoonerLimitsRecordsSanitizer")
local common = require("Schooner.SchoonerCommon")
local utils = require("Schooner.Compiler.Utils")
local pl = require('pl.import_into')()
local dump = helpers.dump
local C = require('Schooner.Compiler.CompilerHelpers')

-- Values setup once for the station
local enableExitOnFailureRecord = false
local schedulerThreads = nil
local limitVersionFunction = nil

-- constants
local MAIN = common.MAIN
local TEARDOWN = common.TEARDOWN
local ACTIONS = common.ACTIONS
local LIMITS = common.LIMITS

-- compiler output keys
local MAIN_TESTS = common.MAIN_TESTS
local MAIN_ACTIONS = common.MAIN_ACTIONS
local TEARDOWN_TESTS = common.TEARDOWN_TESTS
local TEARDOWN_ACTIONS = common.TEARDOWN_ACTIONS

-- coverage table keys
local REQUIRED_COVERAGE_KEYS = common.REQUIRED_COVERAGE_KEYS
local OPTIONAL_COVERAGE_KEYS = common.OPTIONAL_COVERAGE_KEYS

-- Group Function Table and defaults
local schoonerGroupFT = {}
local loopsLeft = 1
local intendedLoopsPerDetection = 1

-- Device Function Table and defaults
local schoonerDeviceFT = {}

-- static: initialize once, reused in every test cycle.
groupConditionVariables = {}
local policy = {}
staticCoverageTable = {}
currentRunCoverageTable = {}

-- for Sampling plugin overriding:
--   - use mock plugin when testing
--   - potentially for Nyquist 2.0
local samplingPluginFromUser = nil

-- pass conditions between main dag and teardown dag
local conditionsForDevices = {}

local loaded, conditionEvaluator = xpcall(Atlas.loadPlugin, debug.traceback,
                                          'ConditionEvaluator')
if loaded == false then
    helpers.debugPrint(
    'ConditionEvaluator is not supported by current local Atlas version.')
    conditionEvaluator = nil
end

-- global var for whether station could do sampling.
-- station could do sampling when there are sampled test
--  and station is secured.
-- If there is no sampled test or station is insecure when group launches,
--  no nyquist plugin will be launched.
-- Only when doSampling == true can a DUT possibly enable sampling for itself,
--  and submit result to Nqyuist server.
-- When doSampling is false, DUT will run all test 100%, and no result will be
--  submitted to Nyquist server.
local doSampling = false

-- table to store nyquistDUT plugins.
-- store it here instead of adding it to DUT's device plugin
-- so user cannot use them in action
local nyquistDUTPlugins = {}

-- stores schooner generated limit version.
-- may be overridden by user's function later
-- so may not be the final registered version.
-- {DeviceName:LimitVersion}
local limitVersionTable = {}

-- Group Function Table defaults
schoonerGroupFT.loopAgain = function()
    -- clean up policy objects
    policy = {}

    -- loop per detection
    loopsLeft = loopsLeft - 1
    if loopsLeft <= 0 then
        loopsLeft = intendedLoopsPerDetection
        return false
    end
    helpers.debugPrint("Returning true for loopAgain since loopsLeft = " ..
                       loopsLeft)
    return true
end
schoonerGroupFT.groupShouldExit = function(groupPluginTable)
    return shouldExitFunction and shouldExitFunction(groupPluginTable) or false
end

-- Device Function Table defaults
schoonerDeviceFT.scheduleFinalDAG = function(dag, deviceName, _)
    M.scheduleRecordAndLimitSanitizationCoverage(dag, deviceName)
end

local function evaluateConditionExpression(deviceName,
                                           conditionsExpression)
    local conditions = conditionsForDevices[deviceName]
    local conditionValues = M.resolveConditionExpression(deviceName,
                                                         conditionsExpression,
                                                         conditions)
    local success, evaluatedExpressionResult =
    xpcall(conditionEvaluator.eval, debug.traceback, conditionsExpression,
           conditionValues)
    return success, evaluatedExpressionResult
end

-- Resolve a conditional expression into a key/val pair.
-- The key will be the name of the condition while the value
-- is the value that the condition variable has resolved to.
function M.resolveConditionExpression(deviceName, expression, conditions)
    local conditionValues = {}
    local tokens = conditionEvaluator.tokenize(expression)
    for _, token in ipairs(tokens) do
        if token.type == 'identifier' then
            local valueInConditions = conditions[token.value]
            if valueInConditions == nil then
                local msg = 'condition value: ' .. token.value ..
                            ' is not defined/scheduled'
                helpers.printAndFailDevice(deviceName, msg)
            else
                conditionValues[token.value] = valueInConditions
            end
        end
    end

    return conditionValues
end

-- Use eval function from ConditionEvaluator plugin to check conditional expression
--
-- There are two columns in the limit table that can contain conditional expressions:
-- 1) Required
-- 2) Conditions
--
-- This function will use the ConditionEvaluator plugin to transform
-- a conditional expression into a true/false value
-- based on the run-time values of the condition variables.
-- @returns: true if succees. false, msg on failure
function M.handleLimitConditionExpression(deviceName,
                                          limits,
                                          limitTblColumn)
    if limitTblColumn == nil or
    (limitTblColumn ~= 'conditions' and limitTblColumn ~= 'required') then
        local msg = "Missing limit table column identifier.  The two "
        msg = msg .. "possible identifiers are `required` or `conditions`"
        helpers.printAndFailDevice(deviceName, msg)
        return false, msg
    end

    for _, limitRow in ipairs(limits) do
        local expression = limitRow[limitTblColumn]
        if type(expression) == "string" then
            local success, evaluatedExpressionResult =
            evaluateConditionExpression(deviceName, expression)
            if success then
                limitRow[limitTblColumn] = evaluatedExpressionResult
            else
                local msg = "Limit table " .. limitTblColumn ..
                            " column has an invalid condition expression: " ..
                            expression .. ', error message: ' ..
                            evaluatedExpressionResult
                helpers.printAndFailDevice(deviceName, msg)
                return false, msg
            end
        end
    end

    return true
end

schoonerDeviceFT.scheduleDAG = function(iter, dag, deviceName, plugins, _)
    helpers.clearThreads(dag)
    -- Set thread limit according to value in station info.
    -- The default behavior is unlimited threads; only override if user passes int > 0 in group script.
    if schedulerThreads ~= nil then
        dag.threads(schedulerThreads)
    end

    -- First iteration runs init test coverage
    -- Second iteration runs main test coverage
    -- Third iteration runs teardown test coverage
    local coverageFunctionMap = {
        [1] = M.scheduleInitCoverage,
        [2] = M.scheduleMainCoverage,
        [3] = M.scheduleTeardownCoverage,
        [4] = function() return false end
    }

    setmetatable(coverageFunctionMap, {
        __index = function(item)
            M.errorOut("no schedule function defined for iter " .. item)
        end
    })

    local func = coverageFunctionMap[iter]

    local ok, result = pcall(func, dag, deviceName, plugins)
    if ok == false then
        helpers.printAndFailDevice(deviceName, result)
        return false
    end
    return result
end

function M.submitNyquistResult(deviceName)
    if not doSampling then
        -- do not submit when overall sampling is disabled:
        --    - no sample test
        --    - station securty fails
        return
    end

    local conditions = conditionsForDevices[deviceName]
    if conditions[common.ENABLE_SAMPLING_FLAG] == 'NO' then
        -- do not sumbit when current device doesn't enable sampling
        return
    end

    local nyquistDUT = nyquistDUTPlugins[deviceName]
    if nyquistDUT == nil then
        -- this should not happen but just being defensive here
        helpers.printAndFailDevice(deviceName,
                                   'Error: nyquistDUT is nil when submitting ' ..
                                   'result to Nyquist server. Please contact ' ..
                                   'Schooner-FactorySW@group.apple.com')
    end

    local mainTests = currentRunCoverageTable[deviceName][MAIN_TESTS]
    local mainActions = currentRunCoverageTable[deviceName][MAIN_ACTIONS]
    for _, test in ipairs(mainTests) do
        local samplingGroup = test.SamplingGroup
        if samplingGroup ~= '' and nyquistDUT.shouldRun(samplingGroup) then
            for _, actionIndex in ipairs(test.actions) do
                local action = mainActions[actionIndex]
                local r = action.resolvable
                if not r.isCancelled() then
                    -- fail: fail; pass/relaxedpass: pass
                    local result =
                    r.overallResult() ~= Group.overallResult.fail and
                    nyquistDUT.result.pass or nyquistDUT.result.fail
                    nyquistDUT.addResult(samplingGroup, result)
                end
            end
        end
    end

    nyquistDUT.finish()

    nyquistDUTPlugins[deviceName] = nil
end

-- Get all registered station info and put it in the right spots
function M.schoonerSetup(schoonerStationInfo)
    if schoonerStationInfo["groupFT"] then
        -- totally, gft can have setup/teardown, start/stop and getSlots.
        -- here we take directly from user code getSlots, stop and teardown;
        -- schooner has dedicated implmentation for setup and start below
        helpers.tableOverride(schoonerStationInfo["groupFT"], schoonerGroupFT,
                              { "getSlots", "stop", "teardown" })

    end

    if not (Group.getDeviceOrphanedLimits and
    Group.getDeviceOrphanedRecordsCount and Group.addDeviceLimits) then
        error(
        'Schooner uses orphaned records which are not supported by current ' ..
        'local Atlas version. Please upgrade Atlas to a version with ' ..
        'orphaned records APIs, like Group.getDeviceOrphanedLimits().')
    end

    -- need this group setup function to initialize group conditions
    schoonerGroupFT.setup = function(resourceURLs)
        local groupPlugins = {}
        if schoonerStationInfo.groupFT.setup ~= nil then
            groupPlugins = schoonerStationInfo.groupFT.setup(resourceURLs)
        else
            if helpers.isNonEmptyTable(resourceURLs) then
                local msg = 'You must implement '
                msg = msg .. 'groupFunctionTable.setup(resourceURLs) '
                msg = msg .. 'when having resources'
                M.errorOut(msg)
            end
        end

        local coverageFile = 'coverage/coverage'
        staticCoverageTable, groupConditionVariables =
        M.schoonerGroupSetup(coverageFile, groupPlugins)
        return groupPlugins
    end

    -- setting limits for each device
    schoonerGroupFT.start = function(groupPlugins)
        local allDevices = Group.allDevices()

        if schoonerStationInfo.groupFT.start ~= nil then
            schoonerStationInfo.groupFT.start(groupPlugins)
        end

        M.disableSamplingIfStationInsecure()
        if doSampling then
            local nyquistDUTs = { nyquistPlugin.createNyquistDUTs(#allDevices) }
            for i, device in ipairs(allDevices) do
                nyquistDUTPlugins[device] = nyquistDUTs[i]
            end
        end
    end

    schoonerDeviceFT.teardown = function(deviceName, devicePlugins)
        -- fail device if user supplies sampling nyquist, for testing purpose.
        if samplingPluginFromUser then
            local msg =
            "Using user-supplied Sampling Plugin. Device cannot PASS."
            helpers.printAndFailDevice(deviceName, msg)
        end

        -- if do it in action, user will be able to access nyquist plugins in their action
        -- which has the risk of polluting test result there.
        -- on M1 Macbook Air submitNyquistResult() takes 0.7-1.1s for each DUT
        -- in a 2-slot-1-group example station.
        -- Another potential place is in scheduleDAG before scheduling teardown coverage
        -- with risk that main test finished but Atlas stopped/crashed in teardown
        -- but result has been submitted to Nyquist
        -- in a schooner sync meeting the team didn't think there are much
        --  difference so just do it in teardown now.
        M.submitNyquistResult(deviceName)

        if schoonerStationInfo.deviceFT and
        schoonerStationInfo.deviceFT.teardown then
            return schoonerStationInfo.deviceFT.teardown(deviceName,
                                                         devicePlugins)
        end
    end

    if schoonerStationInfo["deviceFT"] then
        helpers.tableOverride(schoonerStationInfo["deviceFT"], schoonerDeviceFT,
                              { "setup" })
    end

    if schoonerStationInfo["loopCountPerDetection"] then
        intendedLoopsPerDetection = schoonerStationInfo["loopCountPerDetection"]
        loopsLeft = intendedLoopsPerDetection
    end

    GSM.registerGroupFunctionTable(schoonerGroupFT)
    GSM.registerDeviceFunctionTable(schoonerDeviceFT)

    if schoonerStationInfo["shouldExitFunction"] then
        shouldExitFunction = schoonerStationInfo["shouldExitFunction"]
    end

    if schoonerStationInfo["detectionTimeout"] then
        GSM.setDetectionTimeout(schoonerStationInfo["detectionTimeout"][1],
                                schoonerStationInfo["detectionTimeout"][2])
    end

    if schoonerStationInfo["readyForAutomatedHandling"] then
        if schoonerStationInfo["groupFT"]["getSlots"] then
            local msg = 'getSlots cannot be overriden if '
            msg = msg .. 'factory automation is enabled. '
            msg = msg .. 'Remove your custom implementation of '
            msg = msg .. 'getSlots() to fix this error'
            error(msg)
        end
        GSM.registerAutomatedHandlingCallback(
        schoonerStationInfo["readyForAutomatedHandling"])
    end

    if schoonerStationInfo["automationFixtureControlCallbacks"] then
        if not schoonerStationInfo["readyForAutomatedHandling"] then
            msg = 'automationFixtureControlCallbacks cannot be defined ' ..
                  'unless readyForAutomatedHandling is also defined.' ..
                  '  Have you defined readyForAutomatedHandling ' ..
                  'in your group script?'

            error(msg)
        end
        local callbacks =
        schoonerStationInfo["automationFixtureControlCallbacks"]
        GSM.registerAutomationFixtureControlCallbacks(callbacks)
    end

    if schoonerStationInfo["endTestingOnFailureRecord"] then
        enableExitOnFailureRecord = true
    end

    if schoonerStationInfo['disableGroupScriptDebugPrint'] then
        helpers.disableDebugLogs()
    end

    if schoonerStationInfo['saveDAG'] then
        GSM.saveDAG()
    end

    samplingPluginFromUser = schoonerStationInfo.samplingPluginFromUser

    -- Get thread limit from station info.
    schedulerThreads = schoonerStationInfo["schedulerThreads"]

    limitVersionFunction = schoonerStationInfo["limitVersionFunction"]
end

function M.getSchoonerVersion()
    local schoonerVersion = utils.absolutePath("Assets/SchoonerVersion.txt")
    local ret, content = pcall(helpers.readFile, schoonerVersion)
    if ret == true then
        return content
    else
        error("Failed to open Schooner version file at " ..
              tostring(schoonerVersion))
    end
end

function M.getLimitVersion() return limitVersionTable end

function M.schoonerMain(...)
    local schoonerVersion = M.getSchoonerVersion()
    print("Starting Schooner " .. schoonerVersion)
    local schoonerStationInfo = schooner.getRegisteredStationInfo()
    M.schoonerSetup(schoonerStationInfo)
    GSM.groupStateMachineMain(...)
end

-- return true/false for whether given item is in given list.
-- given list could be table or a symble-separated-list-string.
-- default separator is comma (,).
-- treating empty string as all and return true.
function M.inArray(array, item, sep)
    if sep == nil then
        sep = ','
    end

    if array == '' or array == nil then
        return true
    end

    if type(array) == 'string' then
        array = helpers.splitBySeveralDelimiter(array, sep .. ' ')
    elseif type(array) ~= 'table' then
        local msg = 'in: array should be table or '
        msg = msg .. 'symbol-separated-string while getting ' .. type(array)
        M.errorOut(msg)
    end

    return helpers.hasVal(array, item)
end

-- return fullName: testName + subTestName
function M.fullName(testDef)
    assert(testDef.testName ~= nil, 'testName key is nil.')
    assert(testDef.subTestName ~= nil, 'subTestName key is nil.')
    return testDef.testName .. ' ' .. testDef.subTestName
end

-- generate max action index for each action
-- used to determine whether the last action of test has been scheduled.
function M.generateMaxActionIndexForTest(testDefs)
    if testDefs == nil then
        return
    end
    for _, testDef in ipairs(testDefs) do
        testDef.maxActionIndex = helpers.max(testDef.actions)
    end
end

-- split condition tables per types
-- and initialize group conditions
-- @return: groupConditionVariables table
function M.initializeGroupConditionVariables(groupConditions,
                                             groupPlugins)
    -- allow nil or empty conditions
    local groupConditionVars = {}
    if helpers.isNonEmptyTable(groupConditions) then
        for _, setting in ipairs(groupConditions) do
            local name = setting.name
            helpers.debugPrint('initializing group condition ' .. name)
            local value = conditionRunner.runConditionGenerator(name,
                                                                setting.generator,
                                                                groupPlugins)
            -- validator will error out for invalid value
            conditionRunner.runConditionValidator(name, setting.validator, value)
            groupConditionVars[name] = value
        end
    end

    helpers.debugPrint('groupConditionVars: ' .. dump(groupConditionVars))
    return groupConditionVars
end

function M.convertLimitPriorityStringToNumber(limits)
    if limits ~= nil and next(limits) ~= nil then
        for _, limit in ipairs(limits) do
            if limit.priority ~= nil then
                helpers.debugPrint('Converting limit priority ' ..
                                   limit.priority .. ' to ' ..
                                   Group.priority[limit.priority])
                limit.priority = Group.priority[limit.priority]
            end
        end
    end
end

-- NyquistPlugin requires certain format of table as default
-- {1:{groupName, rate};2:{groupName,rate}}
-- shark: [refinement]: is it better for plugin to takes an key-value dictionary?
local function generateDefaultSamplingTableForNyquistPlugin(samplings)
    local samplingTable = {}
    for name, numRate in pairs(samplings) do
        if numRate < 1 or numRate > 99 then
            error('Sampling group ' .. tostring(name) ..
                  'has invalid sampling rate: ' .. tostring(numRate) ..
                  ', expecting 1-99')
        end
        table.insert(samplingTable, { name, numRate })
    end
    return samplingTable
end

function M.getMode()
    local groupArgs = GSM.groupArguments
    if groupArgs == nil then
        error("group args does not exist in station configuration plist")
    end
    if type(groupArgs) ~= "table" then
        error("group args in station plist must be an array")
    end

    local mode = groupArgs[#groupArgs]
    local msg = 'mode (last group arg in station configuration plist) '
    msg = msg .. 'should be a non-empty string'
    assert(helpers.isNonEmptyString(mode), msg)
    return mode
end

local function loadNyquist1Plugin()
    local nyquistPluginLoaded, plugin = xpcall(Atlas.loadPlugin,
                                               debug.traceback, 'NyquistPlugin')
    if nyquistPluginLoaded == false then
        error('Has Sampling test but failed to load Nyquist Plugin; error = ' ..
              tostring(nyquistPlugin))
    end
    return plugin
end

function M.initializeNyquist(samplings)
    if not doSampling then
        return
    end
    if helpers.isNilOrEmptyTable(samplings) then
        return
    end

    if samplingPluginFromUser ~= nil then
        nyquistPlugin = samplingPluginFromUser
    else
        nyquistPlugin = loadNyquist1Plugin()
    end

    local samplingTable =
    generateDefaultSamplingTableForNyquistPlugin(samplings)
    -- Upload sampling group name and rate to nyquist server as default
    nyquistPlugin.setDefaultSamplingRate(samplingTable)
end

-- Add additional limits that catch the following errors:
-- 1) orphaned limits
-- 2) orphaned records
-- 3) mismatch between number of pregistered vs end-of-test limits
-- See the following Radar for additional details:
-- rdar://84655335 ([Runner] Records checking after test coverage finish) for details
--
-- @arg limits - All limits
function M.addAdditionalLimits(limits)
    -- Processing orphan records/limits
    limitsRecordsSanitizer.addOrphanedItemToLimitsTable(limits,
                                                        limitsRecordsSanitizer.dataType
                                                        .typeOrphanedRecords)
    limitsRecordsSanitizer.addOrphanedItemToLimitsTable(limits,
                                                        limitsRecordsSanitizer.dataType
                                                        .typeOrphanedLimits)

    -- Register limit count
    limitsRecordsSanitizer.setPreRegisteredLimitsCount(limits)
end

-- generate a new limit table with only keys Atlas needs before registering
-- rdar://119533714 reports a bug when AtlasCore2 crashes if limit to register
-- has mode = {"production"}
function M.cleanUpLimits(limits)
    local ret = {}
    for i, limit in ipairs(limits) do
        ret[i] = {
            -- names
            testname = limit.testname,
            subtestname = limit.subtestname,
            subsubtestname = limit.subsubtestname,

            -- units & priority
            units = limit.units,
            priority = limit.priority,

            -- actual bounds
            relaxedLowerLimit = limit.relaxedLowerLimit,
            lowerLimit = limit.lowerLimit,
            upperLimit = limit.upperLimit,
            relaxedUpperLimit = limit.relaxedUpperLimit,

            -- allowed list for set record
            allowedList = helpers.isNonEmptyTable(limit.allowedList) and
            limit.allowedList or nil
        }
    end

    return ret
end

function M.loadSchoonerCoverage(coverageFile)
    local coverageTable = require(coverageFile)

    -- handle mode & stationType
    -- find & mark tests that is not current mode/stationType

    local mode = M.getMode()
    helpers.debugPrint('mode: ' .. mode)

    local coverageTableForMode = coverageTable[mode]
    if not helpers.isNonEmptyTable(coverageTableForMode) then
        M.errorOut('Invalid Mode: the mode `' .. mode ..
                   '` is not valid for the current overlay. Please choose a different mode that is supported.')
    end
    local mainTestDefs = coverageTableForMode[MAIN_TESTS]
    local teardownTestDefs = coverageTableForMode[TEARDOWN_TESTS]

    M.generateMaxActionIndexForTest(mainTestDefs)
    M.generateMaxActionIndexForTest(teardownTestDefs)

    M.convertLimitPriorityStringToNumber(coverageTableForMode[LIMITS])

    -- check station security in group setup
    doSampling = M.hasSamplingTest(coverageTableForMode) and
                 Security.isStationSecure()
    M.initializeNyquist(coverageTableForMode[common.SAMPLING])
    local DORCField = common.DisableOrphanedRecordChecking
    coverageTableForMode[DORCField] = coverageTable[DORCField]

    M.ensureLimitVersionFunctionWhenDORC(coverageTableForMode[DORCField])

    return coverageTableForMode
end

function M.ensureLimitVersionFunctionWhenDORC(DORC)
    -- when orphaned record checking is disabled, station can apply limit
    -- outside of limit table, so schooner may not have all the information
    -- to generate correct limit version
    -- here schooner requires station to provide limit override function.
    if DORC and limitVersionFunction == nil then
        error('Orphaned record checking is disabled; expecting station to ' ..
              'provide limit version override function but did not get it.')
    end
end

function M.checkConditionTable(conditions)
    -- nil or empty is supported.
    if helpers.isNilOrEmptyTable(conditions) then
        return
    end
    for k in pairs(conditions) do
        if helpers.hasVal({ 'group', 'test', 'init' }, k) == false then
            -- this only happens when manually modify coverage.lua
            M.errorOut('Invalid condition type in coverage.lua: ' .. k ..
                       '; expecting group, init or test; is coverage.lua ' ..
                       'generated by Schooner compiler?')
        end
    end
end

-- return true if any test has sampling group
function M.hasSamplingTest(coverageTable)
    if coverageTable[MAIN_TESTS] ~= nil then
        for _, test in ipairs(coverageTable[MAIN_TESTS]) do
            if test.SamplingGroup ~= nil and test.SamplingGroup ~= '' then
                helpers.debugPrint('Sampling test found.')
                return true
            end
        end
    end

    return false
end

-- check is there all require keys in Coverage table
-- check is there anyone else key beside require keys and option keys
-- error out if there is any other keys or missing require keys.
function M.checkCoverageKey(coverageTable)
    for coverageKey in pairs(coverageTable) do
        if not helpers.doesItemExistInArray(REQUIRED_COVERAGE_KEYS, coverageKey) and
        not helpers.doesItemExistInArray(OPTIONAL_COVERAGE_KEYS, coverageKey) then
            local msg = 'The compiler output has key: ' .. coverageKey ..
                        ', which is not allowed in this version.  Please' ..
                        ' make sure the version of Schooner used to compile your ' ..
                        ' overlay matches the version of Schooner at run-time.'
            M.errorOut(msg)
        end
    end
    for _, requiredKey in ipairs(REQUIRED_COVERAGE_KEYS) do
        if coverageTable[requiredKey] == nil then
            local msg = 'The compiler output need key: ' .. requiredKey ..
                        ', which not found in coverage table. Please' ..
                        ' make sure the version of Schooner used to compile your ' ..
                        ' overlay matches the version of Schooner at run-time.'
            M.errorOut(msg)
        end
    end
end

function M.schoonerGroupSetup(coverageFile, groupPlugins)
    helpers.debugPrint('groupSetup for ' .. coverageFile)
    local coverageTable = M.loadSchoonerCoverage(coverageFile)
    M.checkCoverageKey(coverageTable)

    if coverageTable.testPlanAttribute.requireConditionValidator then
        if conditionEvaluator == nil then
            local msg = 'Test Plan '
            msg = msg .. ' use condition, which is not supported'
            msg = msg ..
                  ' by current local Atlas version. Please upgrade Atlas to'
            msg = msg .. ' a version with the ConditionEvaluator plugin.'
            error(msg)
        end
    end

    -- Set limits only available after Atlas 2.35.3.x
    -- and rdar://122520697 is fixed in 2.35.4.0
    local minAtlasSetLimits = "2.35.4.1"
    if (Atlas.compareVersionTo(minAtlasSetLimits) ==
    Atlas.versionComparisonResult.lessThan) and coverageTable[common.LIMIT_INFO] and
    coverageTable[common.LIMIT_INFO].usesAllowedList == true then
        M.reportIncompatibleAtlasVersion('Set limits', minAtlasSetLimits)
    end

    local groupConditionVariables = {}
    M.checkConditionTable(coverageTable.conditions)
    if coverageTable.conditions and coverageTable.conditions.group then

        groupConditionVariables = M.initializeGroupConditionVariables(
                                  coverageTable.conditions.group, groupPlugins)
    end
    groupConditionVariables['Mode'] = M.getMode()
    return coverageTable, groupConditionVariables
end

function M.errorOut(msg)
    -- rdar://107698977 (Stop launching new atlas group process when there is error)
    error('ErrorOut: ' .. tostring(msg))
end

-- order current tests from its dependencies.
-- if any deps is skipped, depth-first-search for the skipped test's deps.
-- deps: list of int index of given test's dependencies
-- for example {2, 3} means this test should run after tests[2] and tests[3]
-- if tests[2] is skipped due to stationType, will go through tests[2]'s deps as well.
function M.orderTests(dag,
                      testDefs,
                      testIndex,
                      deps,
                      lastInitConditionResolvable)
    local currentTestDef = testDefs[testIndex]
    if helpers.isNilOrEmptyTable(deps) then
        if lastInitConditionResolvable and currentTestDef.resolvableStartAction then
            -- addAction already ensure lastInitConditionResolvable points to actions that has no dependency in the test
            -- which are the first few actions in the dag.
            -- so only needs to handle the case when test has no dependency but has condition
            -- which add extra starting action.
            dag.order(lastInitConditionResolvable,
                      currentTestDef.resolvableStartAction)
        end
        return
    end

    for _, i in ipairs(deps) do
        local testDef = testDefs[i]
        if testDef.skipped then
            helpers.debugPrint('test ' .. M.fullName(testDef) ..
                               ' is skipped; looking for its deps. ' ..
                               dump(testDef.deps))

            M.orderTests(dag, testDefs, testIndex, testDef.deps,
                         lastInitConditionResolvable)
        else
            helpers.debugPrint(
            'orderTest: ' .. M.fullName(testDefs[i]) .. '->' ..
            M.fullName(currentTestDef))
            -- if current test has condition with a choice node/test,
            -- order to the choice test; otherwise order to the test itself.
            -- like if T1 --> T2, and T2 has condition,
            -- T1 --> T2_choice_test ==> T2 (==> is choice path, not ordianry ordering.
            local currentTestResolvable =
            currentTestDef.resolvableStart or currentTestDef.resolvable
            local depsTestResolvable = testDef.resolvable
            if testDef.resolvableStart then
                -- with choice node; use weak ordering, like
                -- if T1 --> T2 and T1 has choice node, T1 might be skipped due to condition but T2 should still run.
                -- make this T1_choice_Test =(choice)=> T1 -(weak)-> T2
                -- so if T1_choice_Test returns nil, T1 is cancelled and T2 still run.
                helpers.debugPrint('weak ordering: ' .. M.fullName(testDef) ..
                                   ' -> ' .. M.fullName(currentTestDef))
                dag.orderTest(false, depsTestResolvable, currentTestResolvable)
            else
                dag.orderTest(depsTestResolvable, currentTestResolvable)
            end
        end
    end
end

-- schedule action to initialize Init condition variables
-- return the last resolvable which run before any test actions.
function M.initializeInitConditionVariables(initConditionVarDefs,
                                            dag,
                                            conditions,
                                            allDevicePluginNames)
    if initConditionVarDefs == nil then
        return nil
    end

    -- previous resolvable; when this end will connect to the 1st test's 1st action.
    local prev = nil

    for _, conditionVarDef in ipairs(initConditionVarDefs) do
        local name = conditionVarDef.name
        local validator = conditionVarDef.validator
        if (name == common.ENABLE_SAMPLING_FLAG) then
            -- EnableSampling does not have user supplied valdiator
            -- use Schooner predefined one.
            validator = common.ENABLE_SAMPLING_VALIDATOR
        end
        local r = dag.add('schooner_condition_init_' .. name,
                          'Schooner/ConditionRunner.lua', allDevicePluginNames,
                          name, conditionVarDef.generator, validator)

        conditions[name] = r

        -- run init condition validator sequentially
        if prev then
            dag.order(prev, r)
        end
        prev = r
    end
end

-- Populate conditions table with test conditions from coverage.lua file
-- For now, simply populate test conditions with the name of the test condition itself
-- Transforming the test condition name into a resolvable will be done later
-- within the runner.
function M.initializeTestConditionVariables(testConditionVarDefs,
                                            conditions)
    for _, setting in ipairs(testConditionVarDefs) do
        local name = setting.name
        helpers.debugPrint('Initializing test condition ' .. name ..
                           dump(setting))
        setting.name = nil
        conditions[name] = setting
    end
end

function M.handleTestStopOnFail(testDef)
    local sof = testDef.StopOnFail
    -- shark preference: nil/true/false is better than string "Y"/"N" internally
    if sof ~= nil and type(sof) ~= 'boolean' then
        M.errorOut('[Internal] test.StopOnFail should be nil or boolean value.')
    end

    if sof then
        if testDef.resolvable.stopOnFail == nil then
            M.errorOut('Test [' .. testDef.testName .. ' ' ..
                       testDef.subTestName .. '] requested StopOnFail ' ..
                       'but Atlas2 does not support test.stopOnFail(). ' ..
                       'Upgrade Atlas2 with test.stopOnFail() to use ' ..
                       'Main table StopOnFail feature.')
        end
        testDef.resolvable.stopOnFail()
    end
end

-- create test if necessary; return the test for current action.
function M.getTest(testDef, dag)
    local test
    if testDef.resolvable == nil then
        test = dag.addTest(testDef.testName, testDef.subTestName)
        testDef.resolvable = test
        testDef.criticals = {}
        M.handleTestStopOnFail(testDef)
    else
        test = testDef.resolvable
    end
    return test
end

function M.handleFindOutputsActions(testDef, actionDefs, coverage)
    local findOutputsActions = testDef.findOutputsActions
    local test = testDef.resolvable
    for inputName, action in pairs(findOutputsActions or {}) do
        if action.resolvable == nil then
            -- For the same test, only create find.outputs actions
            -- once. All actions in this test will share this action
            local args = {}
            for testParameters, arg in pairs(action) do
                if arg.dag == nil then
                    -- find.outputs within same dag: in main or teardown
                    local actionResolvable =
                    actionDefs[arg.actionIdx].resolvable
                    if arg.returnIdx then
                        actionResolvable =
                        actionResolvable.unpack(arg.returnIdx)
                    end
                    table.insert(args, actionResolvable)
                else
                    -- find.outputs in teardown using data from main
                    assert(arg.dag == MAIN,
                           'invalid arg.dag: ' .. tostring(arg.dag) ..
                           '; only support ' .. MAIN .. ' now.')
                    local actionResolvable =
                    coverage[MAIN .. 'Actions'][arg.actionIdx].resolvable

                    local actionValue = M.getResolvableValue(actionResolvable,
                                                             arg.returnIdx)
                    table.insert(args, actionValue)
                end

                -- insert value first, then setting
                -- so the last item is always not nil
                -- this is to support when the last action returns nil
                local t = { testParameters = testParameters, meta = arg.meta }
                table.insert(args, t)
            end
            -- inputName in the same test is unique
            local r = test.add('findOutputsAction-' .. inputName,
                               'Schooner/FindOutputsGenerator.lua', {}, args)
            action.resolvable = r
        end
    end
end

function M.isResolvable(r) return type(r) == 'table' and r.isComplete ~= nil end

function M.getResolvableValue(r, returnIdx)
    local value
    if M.isResolvable(r) then
        if r.isComplete() == true and r.isCancelled() == false then
            if returnIdx then
                value = r.unpack(returnIdx).returnValue()
            else
                value = r.returnValue()
            end
            helpers.debugPrint('resolvable has value: ' .. tostring(value))
        else
            helpers.debugPrint('resolvable did not complete or is cancelled: ')
            value = nil
        end
    else
        -- r is not resolvable; just return it as value.
        value = r
    end
    return value
end

-- dagName: main or teardown.
-- in main, conditions should be resolvable or value, so can directly used to schedule action.
-- in teardown, condition could be an resovlable from previous test,
-- so need to use its value (or nil when the resolvable didn't run).
function M.getArgs(argDefs, actionDefs, conditions, coverage, testDef)
    local args = {}
    if helpers.isNilOrEmptyTable(argDefs) then
        return {}
    end

    for argIndex, arg in ipairs(argDefs) do
        helpers.debugPrint('arg: ' .. dump(arg))
        assert(type(arg) == 'table' and
               (next(arg) == nil or arg.value ~= nil or arg.action ~= nil or
               arg.condition ~= nil or arg.findOutputsActionName ~= nil),
               'arg should be table with "value", "action", "condition" or "findOutputsActionName" key: ' ..
               dump(arg) .. 'In special cases, arg can also be {value=nil}={}.')
        -- User specifies "null" as action arg in test def.
        if next(arg) == nil then
            args[argIndex] = nil
        elseif arg.action ~= nil then
            -- use resolvable from other action.
            local actionIdx = arg.action.actionIdx
            local returnIdx = arg.action.returnIdx
            local r
            if arg.action.dag ~= nil then
                local dagName = arg.action.dag
                -- args is from a previous dag, which has finished.
                local otherDAGActions = coverage[dagName .. ACTIONS]
                local resolvable = otherDAGActions[actionIdx].resolvable
                if (resolvable == nil) then
                    -- skipped action.
                    helpers.debugPrint('action of resolvable is skipped. ' ..
                                       'using nil.')
                else
                    r = M.getResolvableValue(resolvable, returnIdx)
                end
            else
                -- arg is refering to an action in the same dag.
                r = actionDefs[actionIdx].resolvable
                if returnIdx ~= nil then
                    r = r.unpack(returnIdx)
                end
            end

            args[argIndex] = r
        elseif arg.findOutputsActionName ~= nil then
            local name = arg.findOutputsActionName
            local r = testDef.findOutputsActions[name].resolvable
            assert(r, '[internal] findOutputAction ' .. name .. ' do not exist')
            args[argIndex] = r
        elseif arg.condition ~= nil then
            -- condition variable
            -- for init & test conditions, conditions[conditionName] is the resolveable of the init condition's action
            -- for group conditions, conditions[conditionName] is the actual value of the group condition's return val
            local conditionName = arg.condition
            if conditions[conditionName] == nil then
                local msg = 'Condition ' .. conditionName ..
                            'is not initialized; using nil as value'
                helpers.debugPrint(msg)
            end
            args[argIndex] = conditions[conditionName]
        elseif arg.value ~= nil then
            -- just value.
            args[argIndex] = arg.value
        else
            local msg = 'arg should only have one of value, '
            msg = msg .. 'condition or action key.'
            M.errorOut(msg)
        end
    end

    return args
end

-- Add action resolvable to test condition.
local function addTestConditionResolvable(actionDef,
                                          actionResolvable,
                                          conditions,
                                          dag)
    if actionDef.testConditions == nil then
        return
    end

    for name, testConditionReturnIdx in pairs(actionDef.testConditions) do
        local testConditionDef = conditions[name]

        if testConditionDef ~= nil then
            if name == common.ENABLE_SAMPLING_FLAG then
                local validatorAction = dag.add(
                                        'schooner_test_condition_' .. name ..
                                        '_validator',
                                        'Schooner/ConditionValidator.lua', nil,
                                        name, common.ENABLE_SAMPLING_VALIDATOR,
                                        actionResolvable.unpack(
                                        testConditionReturnIdx.returnIdx))

                conditions[name] = validatorAction
            else
                local validatorAction = dag.add(
                                        'schooner_test_condition_' .. name ..
                                        '_validator',
                                        'Schooner/ConditionValidator.lua', nil,
                                        name, testConditionDef.validator,
                                        actionResolvable.unpack(
                                        testConditionReturnIdx.returnIdx))

                conditions[name] = validatorAction
            end
        else -- Should not happen since test conditions are checked during compile time
            local errMsg = "Test condition " .. name .. " does not exist. "
            errMsg = errMsg .. "Check condition table to make sure this "
            errMsg = errMsg .. "condition is defined."
            error(errMsg)
        end
    end
end

local function validatePluginName(pluginName,
                                  allDevicePluginNames,
                                  testDef,
                                  actionDef)
    for _, plugin in ipairs(allDevicePluginNames) do
        if plugin == pluginName then
            return
        end
    end
    error(string.format(
          "Unknown plugin '%s' referenced by test '%s' action '%s'", pluginName,
          M.fullName(testDef), actionDef.name))
end

function M.reportIncompatibleAtlasVersion(feature, expectedVersion)
    local msg = "Current Atlas version %s"
    msg = msg .. " does not support %s. "
    msg = msg .. "Please upgrade to version >= %s"
    msg = string.format(msg, Atlas.version, feature, expectedVersion)
    error(msg)
end

function M.addAction(actionDef,
                     testDef,
                     plugins,
                     allDevicePluginNames,
                     args,
                     conditions,
                     dag)
    helpers.debugPrint('adding action: ' .. M.fullName(testDef) .. ' ' ..
                       actionDef.name)
    local test = testDef.resolvable
    -- filename: user must provide it. Schooner support CSV action and Lua action so
    -- if user doesn't provide action file name we don't know if this is actionName.csv or actionName.lua

    -- resolve plugin alias
    -- atlas expect a table like {'plugin1', alias='plugin2'}
    -- while plugins table from yaml is a list: {1='plugin1', x='plugin2'}
    local pluginsForAction = {}
    if plugins then
        for _, plugin in ipairs(plugins) do
            if type(plugin) == 'table' then
                helpers.debugPrint('Plugin Alias found!')
                for k, v in pairs(plugin) do
                    validatePluginName(v, allDevicePluginNames, testDef,
                                       actionDef)
                    pluginsForAction[k] = v
                end
            else
                validatePluginName(plugin, allDevicePluginNames, testDef,
                                   actionDef)
                -- plugin name without alias
                table.insert(pluginsForAction, plugin)
            end
        end
    end

    local action
    -- Schedule DQ node on behalf of user (only available after 2.34.5.1)
    if actionDef.dataQuery == true then
        if (Atlas.compareVersionTo("2.34.5.1") ==
        Atlas.versionComparisonResult.lessThan) then
            M.reportIncompatibleAtlasVersion('data query actions', "2.34.5.1")
        else
            action = test.addDataQuery(actionDef.name)
        end
    else
        -- For corner case when there is a single action arg which is a table: {'xyz', 'abc'}.
        -- Atlas cannot tell if the last arg in test.add is a table of args, or a single table.
        -- Solution: we wrap arg in {}. This also handles any single-arg situation.
        local numArgs = utils.findProperLength(args)
        if numArgs == 1 then
            args = { args }
        end
        action = test.add(actionDef.name, actionDef.filename, pluginsForAction,
                          table.unpack(args, 1, numArgs))
    end

    addTestConditionResolvable(actionDef, action, conditions, dag)
    actionDef.resolvable = action
    return action
end

local function orderDependentActionResolvable(dag, action, depAction, conditions)
    local r = nil

    -- If action is dependent on a an action that has a test condition, order current condition
    -- to dependent action's validator resolvable.
    if depAction.testConditions ~= nil then
        for name, _ in pairs(depAction.testConditions) do
            r = conditions[name] -- Test condition validator resolvable
            assert(r ~= nil, 'test condition ordering dependency is nil')
            dag.order(r, action)
        end
    else
        r = depAction.resolvable
        assert(r ~= nil, 'action dependency is nil')
        dag.order(r, action)
    end

    return r
end

function M.orderActions(test, action, deps, actionDefs, conditions)
    if helpers.isNonEmptyTable(deps) then
        -- has deps.
        for _, dependentActionIndex in ipairs(deps) do
            orderDependentActionResolvable(test, action,
                                           actionDefs[dependentActionIndex],
                                           conditions)
        end
    end
end

function M.applyPolicy(policyType, testFullName, actionName, action, dag)
    -- this works because the coverage is scheduled sequentially of each device:
    --   the 1st device create the policy object, the other devices reuse it.
    if helpers.isNonEmptyString(policyType) then
        assert(policyType == 'rendezvous' or policyType == 'exclusion',
               'Unsupported policy type: ' .. policyType ..
               ', expecting rendezvous or exclusion')

        -- example: policy: rendezvous
        if policy[testFullName] == nil then
            policy[testFullName] = {}
        end
        local policyObject = policy[testFullName][actionName]
        if policyObject == nil then
            policyObject = Group.createPolicy(Group.syncType[policyType])
            policy[testFullName][actionName] = policyObject
        end
        dag.policy(policyObject, action)
        helpers.debugPrint('policy applied: ' .. testFullName .. ' ' ..
                           policyType)
    end
end

function M.checkCritical(actionDef, testDef)
    if not actionDef.background then
        table.insert(testDef.criticals, actionDef.resolvable)
    end
end

-- if test has condition, schedule choice node by:
-- 0. create a dummy startAction
-- 1. order(strong, start, test):  startAction -> Test's critical actions
-- 2. create a condition action, which run the condition expression and return true or nil:
--        true: when condtion eval as true
--        nil: when condition eval as false
--    action args: array of condition key and values used in the expression
--    like [key1, value1, key2, value2, ...].
--    The reason of not using a table is value could be resolvable which can only be arg, not inside a table arg.
-- 3. add a choice node using the condition action, with choice path:
--    {
--        true: startAction
--    }
--    When condition expression is true, it will run the start node then the test.
--    When condition expression is false, it will cancel the startAction along with the test.
--    When current test has condition, tests depending on this test will has weak order (see orderTests)
--     so when current test is cancelled due to condition the next test can still run.
function M.handleCondition(dag, testDef, actionDefs, conditions)
    if testDef.Conditions == '' then
        return
    end

    local startAction = dag.add('schooner_start_action_' .. M.fullName(testDef),
                                'Schooner/StartTest.lua', {})

    -- Pointing startAction to all actions of the current test
    -- so the current test can be skipped by condition
    for _, action in ipairs(testDef.actions) do
        dag.order(startAction, actionDefs[action].resolvable)
    end

    local tokens = conditionEvaluator.tokenize(testDef.Conditions)
    -- values: array: [key1, value1, key2, value2, ...]
    -- this is to make sure resolvable is resolved to value when passing in as arg.
    -- if atlas support resolvable in table this can be simplified.
    local values = {}
    for _, token in ipairs(tokens) do
        if token.type == 'identifier' then
            if conditions[token.value] == nil then
                error('identifier ' .. token.value ..
                      ' is not defined/scheduled')
            end
            table.insert(values, token.value)
            table.insert(values, conditions[token.value])
        end
    end
    -- choiceTest is to simplify orderTests.
    local choiceTest = dag.addTest('schooner_choice_test_' ..
                                   M.fullName(testDef))
    local conditionAction = choiceTest.add(
                            'schooner_condition_action_' .. M.fullName(testDef),
                            'Schooner/Choice.lua', {}, testDef.testName,
                            testDef.subTestName, testDef.Conditions,
                            table.unpack(values))
    choiceTest.critical(conditionAction)
    dag.addChoice('schooner_choice_node_' .. M.fullName(testDef),
                  { [true] = startAction }, conditionAction)

    -- resovlableStart: starting test, any test depends on this one
    -- should order to this starting test.
    testDef.resolvableStart = choiceTest
    -- starting action of this test; used to order with the last init condition action.
    testDef.resolvableStartAction = conditionAction
end

-- steps when all actions of a test are scheduled
-- 0. if test has condition, schedule choice node
-- 1. set critical actions
-- 2. order tests
-- 3. set test retry (TODO)
function M.handleTestScheduled(dag,
                               testDefs,
                               actionDefs,
                               testIndex,
                               actionIndex,
                               conditions,
                               lastInitConditionResolvable)
    local testDef = testDefs[testIndex]
    local test = testDef.resolvable
    if testDef.maxActionIndex == actionIndex then
        helpers.debugPrint('all actions of test ' .. M.fullName(testDef) ..
                           ' has been scheduled.')

        -- 8.1 Conditions
        M.handleCondition(dag, testDef, actionDefs, conditions)

        -- 8.2 critical
        test.critical(testDef.criticals)

        -- 8.3 test order
        M.orderTests(dag, testDefs, testIndex, testDef.deps,
                     lastInitConditionResolvable)

        -- 8.4 retry
        -- TODO(shark) add test retry when Atlas support it
    end
end

-- shared by both test dag and final dag
-- function scheduleActions(dag, plugins, testDefs, actionDefs, conditions)
-- @param dag         scheduler
-- @param plugins     plugin table
-- @param coverage    full coverage table, including xTests, xActions while x is the dag name
--                    Also includes limits and conditions.
--                    This is useful for cross-dag reference, like teardown use an output from main test.
-- @param dagName     string, "main" or "teardown" for main test and teardown test
-- @param conditions  table, key: condition var name. value: resolvable or value.
function M.scheduleActions(dag, plugins, coverage, dagName, conditions)
    local testDefs = coverage[dagName .. 'Tests']
    local actionDefs = coverage[dagName .. 'Actions']
    local allDevicePluginNames = helpers.tableKeys(plugins)
    for actionIndex, actionDef in ipairs(actionDefs) do
        -- 0. skip if skipped: not current product
        if not actionDef.skipped then
            -- 1. find its test
            local testDef = testDefs[actionDef.testIdx]
            local test = M.getTest(testDef, dag)
            M.handleFindOutputsActions(testDef, actionDefs, coverage)

            -- 2. plugins
            local pluginsForAction = actionDef.plugins == '*' and
                                     allDevicePluginNames or actionDef.plugins

            -- 3. args
            local args = M.getArgs(actionDef.args, actionDefs, conditions,
                                   coverage, testDef)

            -- 4. test.add()
            local action = M.addAction(actionDef, testDef, pluginsForAction,
                                       allDevicePluginNames, args, conditions,
                                       dag)

            -- 5. action deps
            M.orderActions(test, action, actionDef.deps, actionDefs, conditions)

            -- 6. apply policy
            M.applyPolicy(actionDef.policy, M.fullName(testDef), actionDef.name,
                          action, dag)

            -- 7. critical: any non-background actions are critical.
            M.checkCritical(actionDef, testDef)

            -- 8. if test finish: all actions of this test have been scheduled
            M.handleTestScheduled(dag, testDefs, actionDefs, actionDef.testIdx,
                                  actionIndex, conditions)
        end
    end
end

function M.disableSamplingIfStationInsecure()
    if doSampling and not Security.isStationSecure() then
        doSampling = false
        helpers.debugPrint(
        "Nyquist sampling disabled because station is insecure.")
    end
end

-- for each test with SampleGroup, ask nyquistDUT if it should run
-- update user's condition to skip test based on
-- 0. doSampling
-- 1. EnableSampling
-- 2. ShouldRun
-- only main tests could be sampled.
function M.handleSamplingTests(coverage, deviceName)
    if not doSampling then
        return
    end

    local tests = coverage[MAIN_TESTS]

    for _, test in ipairs(tests) do
        if test.SamplingGroup ~= '' then
            local nyquistDUT = nyquistDUTPlugins[deviceName]
            if nyquistDUT == nil then
                M.errorOut('device ' .. deviceName .. ' has Sampling test' ..
                           M.fullName(test) .. ' but nyquistDUT Plugin ' ..
                           'is missing. Please contact ' ..
                           'Schooner-FactorySW@group.apple.com')
            end

            local enableSampling = common.ENABLE_SAMPLING_FLAG
            if nyquistDUT.shouldRun(test.SamplingGroup) == false then
                if helpers.isNonEmptyString(test.Conditions) then
                    test.Conditions = enableSampling .. '== "NO" and ' ..
                                      test.Conditions
                else
                    test.Conditions = enableSampling .. ' == "NO"'
                end
            end
        end
    end
end

-- Reset the limit version at the end of every test cycle
-- so that the limit version generated by a previous test cycle does not
-- bleed into future test cycle(s)
local function resetLimitVersion(deviceName) limitVersionTable[deviceName] = nil end

-- The init coverage is used to resolve init condition values before the main coverage.
-- This allows limits to be applied based on the conditional evaluation in the limit table's
-- conditions column
function M.scheduleInitCoverage(dag, deviceName, plugins)
    currentRunCoverageTable[deviceName] = helpers.clone(staticCoverageTable)
    local coverage = currentRunCoverageTable[deviceName]
    -- Per COF/SOF discussion, any action error out should exit DAG
    -- so Init dag enable exit on error by default
    dag.enableExitOnError()
    if enableExitOnFailureRecord == true then
        dag.enableExitOnFailureRecord()
    end
    -- Starting with Atlas 2.34, amiok is enabled by default.
    if (Atlas.compareVersionTo("2.34.0.0") ==
    Atlas.versionComparisonResult.lessThan) then
        dag.enableExitOnAmIOkay()
    end

    -- get group conditions
    local conditions = helpers.clone(groupConditionVariables)
    conditionsForDevices[deviceName] = conditions

    local allDevicePluginNames = helpers.tableKeys(plugins)
    if coverage.conditions and coverage.conditions.init then
        -- initialize Init conditions sequentially
        if coverage.conditions.init then
            M.initializeInitConditionVariables(coverage.conditions.init, dag,
                                               conditions, allDevicePluginNames)
        end
    end

    return true
end

-- Populate existing condition table with init condition resolvable values from
-- the init dag
local function populateInitConditionsWithResolvables(conditions)
    for k, _ in pairs(conditions) do
        if type(conditions[k]) == 'table' then -- Do not process group or test conditions
            local val = M.getResolvableValue(conditions[k])
            conditions[k] = val -- Set to already resolved value
        end
    end
end

local function createDuplicateLimitErrorMsg(limit)
    local msg = "Duplicate limits found.  Limit with testname:"
    msg = msg .. limit.testname .. ", subtestname: " .. limit.subtestname
    if limit.subsubtestname ~= nil then
        msg = msg .. ", subsubtestname: " .. limit.subsubtestname
    end
    msg = msg .. " has >=2 different set of limit values"
    msg = msg .. " at run-time.  Please modify "
    msg = msg .. " your limit table's condition column to ensure that the "
    msg = msg .. " conditional expressions of these duplicate limits cannot "
    msg = msg .. " both resolve to true during run-time. "

    return msg
end

-- Create a unique identifier for a single limit entry
--
-- @arg limit- A limit entry from Schooner's compiler output
--
-- @return string formatted key
local function createLimitKey(limit)
    local testname = limit.testname
    local subtestname = limit.subtestname
    local subsubtestname = limit.subsubtestname

    local limitKey = "testname:" .. testname
    limitKey = limitKey .. ",subtestname: " .. subtestname

    -- Limits will also use subSubTest as part of its key
    if (subsubtestname ~= nil) then
        limitKey = limitKey .. ",subsubtestname: " .. subsubtestname
    end

    return limitKey
end

-- This function will filter out all duplicate limits by checking their conditions field.
--
-- If a duplicate limit cannot be filtered out, it means that there are >= 2 distinct limit entries
-- which satisfy the following:
--
-- 1) They share the same test identifiers (test, subtest, subsubtest)
-- 2) Their conditional expressions both resolved to true
--
-- @return - filteredLimitsArray - array-styled table of filtered limits
function M.filterDuplicateLimits(deviceName, limits)
    local filteredLimits = {}

    for _, limit in ipairs(limits) do
        local limitKey = createLimitKey(limit)

        if limit.conditions ~= nil and limit.conditions == true then
            if filteredLimits[limitKey] ~= nil then
                local errMsg = createDuplicateLimitErrorMsg(limit)
                helpers.printAndFailDevice(deviceName, errMsg)
            end
            filteredLimits[limitKey] = limit
            -- If limit entry has an empty conditions field then
            -- no duplication can ocur, since the compiler will catch:
            -- 1) duplicate limits (same mode) both with nil condition
            -- 2) duplicate limits (same mode) one with nil condition one without
        elseif limit.conditions == nil then
            filteredLimits[limitKey] = limit
        end
    end

    -- Convert from dict to array since Atlas limit registration expects limits
    -- to be in an array format
    local filteredLimitsArr = helpers.convertDictionaryValuesToArray(
                              filteredLimits)
    return filteredLimitsArr
end

-- set "skipped" for actions & tests in incoming coverageTable
-- if the tests/action shouldn't run in given stationType or product
function M.filterTests(testDefs, actions, filterValue, filterField)
    if testDefs == nil or filterValue == nil then
        return
    end
    for _, testDef in ipairs(testDefs) do
        local field = testDef[filterField]
        if field == nil then
            goto continue
        end
        if not helpers.hasVal(testDef[filterField], filterValue) then
            -- not current stationType; mark test as skipped
            helpers.debugPrint('test "' .. M.fullName(testDef) .. '" is for ' ..
                               filterField .. ': ' ..
                               helpers.dump(testDef[filterField]) ..
                               ', while current ' .. filterField .. ' is ' ..
                               filterValue .. '; skipped')
            testDef.skipped = true
        end
        ::continue::
    end

    -- find & mark actions to skip
    for _, actionDef in ipairs(actions) do
        local t = testDefs[actionDef.testIdx]
        if t.skipped then
            actionDef.skipped = true
        end
    end
end

-- If certain limits are not applicable to a given filterValue, we need to filter them out.
-- For instance, suppose we have a coverage limit that only applies to station type 'J1020'.
-- In cases where the current station type is not 'J1020', we should filter out this limit.
-- when there there is nothing to filter, return a copy of the limits
-- to make sure any update to the return limit will not affect the original limits
-- usually original limits comes from staticCoverage.limits.
function M.filterLimits(limitDefs, filterValue, filterField)
    if limitDefs == nil then
        return nil
    end

    if filterValue == nil then
        return helpers.clone(limitDefs)
    end

    local filteredLimits = {}
    for _, limitDef in ipairs(limitDefs) do
        local didNotHaveField = limitDef[filterField] == nil or
                                helpers.isEmptyTable(limitDef[filterField])
        local supportCurrentFilterValue =
        not didNotHaveField and
        helpers.hasVal(limitDef[filterField], filterValue)

        if didNotHaveField or supportCurrentFilterValue then
            local newLimit = helpers.clone(limitDef)
            newLimit[filterField] = nil
            table.insert(filteredLimits, newLimit)
        else
            -- not current stationType/product; mark limit as skipped
            helpers.debugPrint('limit "' .. createLimitKey(limitDef) ..
                               '" is for ' .. filterField .. ': ' ..
                               helpers.dump(limitDef[filterField]) ..
                               ', while current ' .. filterField .. ' is ' ..
                               filterValue .. '; skipped')
        end
    end
    return filteredLimits
end

function M.scheduleMainCoverage(dag, deviceName, plugins)
    -- Per COF/SOF discussion, any action error out should exit DAG
    -- so Main dag enable exit on error by default
    dag.enableExitOnError()
    if enableExitOnFailureRecord == true then
        dag.enableExitOnFailureRecord()
    end
    -- Starting with Atlas 2.34, amiok is enabled by default.
    if (Atlas.compareVersionTo("2.34.0.0") ==
    Atlas.versionComparisonResult.lessThan) then
        dag.enableExitOnAmIOkay()
    end

    -- schedule actions for main table
    local coverage = currentRunCoverageTable[deviceName]
    local conditions = conditionsForDevices[deviceName]
    local limits = coverage[LIMITS]

    M.handleSamplingTests(coverage, deviceName)
    populateInitConditionsWithResolvables(conditions)

    M.filterTests(coverage[MAIN_TESTS], coverage[MAIN_ACTIONS],
                  conditions.StationType, common.STATION_TYPE)
    M.filterTests(coverage[MAIN_TESTS], coverage[MAIN_ACTIONS],
                  conditions.Product, common.PRODUCT)

    if coverage.conditions and coverage.conditions.test then
        -- Initialize Test conditions
        M.initializeTestConditionVariables(coverage.conditions.test, conditions)
    end

    M.scheduleActions(dag, plugins, coverage, MAIN, conditions)
    limits = M.filterLimits(limits, conditions.StationType, common.STATION_TYPE)
    limits = M.filterLimits(limits, conditions.Product, common.PRODUCT)

    if coverage.testPlanAttribute.limitsHasConditions then -- need update
        local result, msg = M.handleLimitConditionExpression(deviceName, limits,
                                                             common.CONDITIONS)
        if not result then
            return false, msg
        end
        limits = M.filterDuplicateLimits(deviceName, limits)
    end

    M.addAdditionalLimits(limits)

    Group.addDeviceLimits(deviceName, M.cleanUpLimits(limits))

    -- Generate limit version
    M.generateLimitVersionString(deviceName, limits)
    return true
end

-- We'll generate some conditions in the coverage test
-- When the coverage test is complete, we should get the coverage return value to refresh our conditionsForDevices table
-- These values will be used in the following functions, for example in the orphanedRequiredLimitsForDevice calculation
local function refreshConditionsAfterFinishedCoverage(deviceName,
                                                      tableName)
    local conditions = conditionsForDevices[deviceName]

    for key, value in pairs(conditions) do
        if type(value) == 'table' and value.isComplete ~= nil then
            -- resolvable; get its value
            if value.isComplete() == true and value.isCancelled() == false then
                conditions[key] = value.returnValue()
                local msg = 'condition get value in ' .. tableName .. ': '
                msg = msg .. key .. '=' .. dump(conditions[key])
                helpers.debugPrint(msg)
            else
                helpers.debugPrint('condition not assigned value in Main: ' ..
                                   key)
                conditions[key] = nil
            end
        end
    end
end

function M.scheduleTeardownCoverage(dag, deviceName, plugins)
    local coverage = currentRunCoverageTable[deviceName]
    if (Atlas.compareVersionTo("2.34.0.0") ~=
    Atlas.versionComparisonResult.lessThan) then
        dag.enableContinueOnAmIOkay()
    end

    if coverage[TEARDOWN_TESTS] == nil then
        helpers.debugPrint('no teardown tests to run; skipping teardown dag.')
        return false
    end

    -- Refresh condition table after finished main coverage
    refreshConditionsAfterFinishedCoverage(deviceName, MAIN)

    local conditions = conditionsForDevices[deviceName]

    M.filterTests(coverage[TEARDOWN_TESTS], coverage[TEARDOWN_ACTIONS],
                  conditions.StationType, common.STATION_TYPE)
    M.filterTests(coverage[TEARDOWN_TESTS], coverage[TEARDOWN_ACTIONS],
                  conditions.Product, common.PRODUCT)

    M.scheduleActions(dag, plugins, coverage, TEARDOWN, conditions)
    return true
end

-- Using current main coverage definition, builds and returns list of all tests and actions with their resolvables.
-- @details The result is an array of dictionaries, where each dictionary provides a single test definition:
-- {
--      {
--         Technology = ..,
--         Coverage = ..,
--         TestParameters = ..,

--         Outputs = {
--             Out1 = {
--                 Resolvable = resolvable,
--                 ReturnIndex = index
--             },
--             Out2 = {
--                 Resolvable = resolvable,
--                 ReturnIndex = index
--             }
--         },

--         Actions = {
--             Action1 = resolvable,
--             Action2 = resolvable
--         }
--     }
-- }
-- @note The function is not expected to be called by Schooner users directly, and should
--       only be called by unit/integration tests frameworks to provide access to action results.
function M.getMainCoverageTestResults(deviceName)
    local mainTests = currentRunCoverageTable[deviceName][MAIN_TESTS]
    local mainActions = currentRunCoverageTable[deviceName][MAIN_ACTIONS]

    assert(mainTests ~= nil, "Main Tests not found")
    assert(mainActions ~= nil, "Main Actions not found")

    local results = {}
    for _, testDef in ipairs(mainTests) do

        local testEntry = {
            Technology = testDef.Technology,
            Coverage = testDef.Coverage,
            TestParameters = testDef.TestParameters,
            Actions = {},
            Outputs = {}
        }
        -- Populate actions
        for _, actionIndex in ipairs(testDef.actions) do
            local actionDef = mainActions[actionIndex]
            testEntry.Actions[actionDef.name] = actionDef.resolvable
        end

        -- Populate outputs
        if testDef.outputs then
            for outputName, outputDef in pairs(testDef.outputs) do
                local actionDef = mainActions[outputDef.actionIdx]
                testEntry.Outputs[outputName] = {
                    Resolvable = actionDef.resolvable,
                    ReturnIndex = outputDef.returnIdx
                }
            end
        end
        table.insert(results, testEntry)
    end
    return results
end

local function publishOrphanedRecords(dag, deviceName, deviceResult)
    local DORC = staticCoverageTable[common.DisableOrphanedRecordChecking]
    if DORC == true then
        helpers.debugPrint('Orphaned Record Checking is disabled.')
        return
    end

    local orphanedRecordsCount = Group.getDeviceOrphanedRecordsCount(deviceName)
    helpers.debugPrint(deviceName ..
                       " scheduleFinalDAG getDeviceOrphanedRecordsCount: " ..
                       orphanedRecordsCount)
    if deviceResult == Group.overallResult.pass then
        if orphanedRecordsCount > 0 then
            dag.add("OrphanedRecordsCheck", "Schooner/RecordPublisher.lua", nil,
                    false,
                    limitsRecordsSanitizer.dataType.typeOrphanedRecords.test,
                    limitsRecordsSanitizer.dataType.typeOrphanedRecords.subtest,
                    limitsRecordsSanitizer.dataType.typeOrphanedRecords
                    .subsubtest,
                    limitsRecordsSanitizer.dataType.typeOrphanedRecords.errMsg)
        end
    end
end

local function publishPreRegisteredLimits(dag, deviceName)
    local currRegisteredLimitsCount = Group.getDeviceLimitsCount(deviceName)
    local preRegisteredLimitsCount =
    limitsRecordsSanitizer.getPreRegisteredLimitsCount()
    helpers.debugPrint(deviceName ..
                       " scheduleFinalDAG currRegisteredLimitsCount: " ..
                       currRegisteredLimitsCount ..
                       ". preRegisteredLimitsCount: " ..
                       preRegisteredLimitsCount)
    if currRegisteredLimitsCount ~= preRegisteredLimitsCount then
        dag.add("LimitsOnlyRegsisteredOnce", "Schooner/RecordPublisher.lua",
                nil, false,
                limitsRecordsSanitizer.dataType.typePreRegisteredLimits.test,
                limitsRecordsSanitizer.dataType.typePreRegisteredLimits.subtest,
                limitsRecordsSanitizer.dataType.typePreRegisteredLimits
                .subsubtest,
                limitsRecordsSanitizer.dataType.typePreRegisteredLimits.errMsg)
    end
end

local function publishOrphanedRequiredLimits(dag, deviceName, deviceResult)
    local orphanedRequiredLimitsForDevice =
    limitsRecordsSanitizer.getOrphanedRequiredLimits(
    currentRunCoverageTable[deviceName][LIMITS], deviceName)
    helpers.debugPrint(deviceName ..
                       " scheduleFinalDAG OrphanedRequiredLimitsCount: " ..
                       #orphanedRequiredLimitsForDevice)
    if deviceResult == Group.overallResult.pass then
        if #orphanedRequiredLimitsForDevice > 0 then
            dag.add("OrphanedLimitsCheck", "Schooner/RecordPublisher.lua", nil,
                    false,
                    limitsRecordsSanitizer.dataType.typeOrphanedLimits.test,
                    limitsRecordsSanitizer.dataType.typeOrphanedLimits.subtest,
                    limitsRecordsSanitizer.dataType.typeOrphanedLimits
                    .subsubtest,
                    limitsRecordsSanitizer.dataType.typeOrphanedLimits.errMsg)
        end
    end
    return orphanedRequiredLimitsForDevice
end

-- return the overridden limit version to register
local function overrideLimitVersion(deviceName, originalVersion)
    helpers.debugPrint("Schooner generated limit version string for device " ..
                       deviceName .. ": " .. tostring(originalVersion) .. '(' ..
                       type(originalVersion) .. ')')
    if limitVersionFunction then
        -- register custom limit version string
        local prefix = staticCoverageTable.limitInfo.limitVersionPrefix
        local conditions = conditionsForDevices[deviceName]

        local success, ver = xpcall(limitVersionFunction, debug.traceback,
                                    prefix, M.getMode(), conditions,
                                    originalVersion)
        if not success then
            helpers.printAndFailDevice(deviceName,
                                       'Limits Version Override function errors out; check device.log for details.')
            return
        end

        -- Overridden limit version should be string
        assert(type(ver) == 'string',
               'Override limit version should be a string while got an ' ..
               type(ver))
        helpers.debugPrint("Overridden limit version string for device " ..
                           tostring(deviceName) .. ": " .. tostring(ver))

        return ver
    end
    return originalVersion
end

--[[
--! @brief check if sw version exceed 48, by concatenating
-- 1. StationVersion from plist
-- 2. limit table version, if exists
-- 3. schooner generated conditional string, if any
-- if exceeds, find the index of conditional string and return it
-- errors out if not found; user shouldn't see this.
-- if not, return the original conditional string, which is good to use.
-- additionally, if orignal conditional string is '', convert to nil.
-- @params deviceName: as name
-- @params version: existing conditional string
-- @returns conditional string to use.
]]
local function limitVersionLengthCheck(deviceName, version, indexVersion)
    if version == nil or string.len(version) == 0 then
        -- For a version with no value
        -- it signifies that we have not selected any specific condition limits.
        return ""
    end

    -- if limits version is '', don't need to check this.
    local limitInfo = staticCoverageTable.limitInfo
    local prefix = limitInfo.limitVersionPrefix
    local swVersion = Atlas.stationVersion
    -- assemble the final version
    if prefix then
        swVersion = swVersion .. '_' .. prefix
    end

    if helpers.isNonEmptyString(version) then
        swVersion = swVersion .. '_' .. version
    end

    local swVersionLength = string.len(swVersion)
    if swVersionLength > common.INSIGHT_SOFTWARE_VERSION_LENGTH_MAX then
        -- need to use index.
        local index = indexVersion
        assert(index ~= nil,
               '[Internal] limit version string ' .. version ..
               ' not found in pre-calculate ' ..
               'list. Please contact Schooner team.')

        print(
        "Schooner Limits Version Map: from " .. version .. " to " .. index ..
        " for device: " .. deviceName)

        return index
    end
    return version
end

function M.limitVersionCombo(limit, limitInfo)
    local withMode = limitInfo.withMode
    local withProduct = limitInfo.withProduct
    local withStationType = limitInfo.withStationType
    local ret = {}
    if limit.conditions then
        ret[#ret + 1] = limit.conditionString
    end
    if withMode and limit.modeString then
        ret[#ret + 1] = limit.modeString
    end
    if withProduct and limit.productString then
        ret[#ret + 1] = limit.productString
    end
    if withStationType and limit.stationTypeString then
        ret[#ret + 1] = limit.stationTypeString
    end
    return ret
end

function M.generateLimitVersionString(deviceName, limits)
    local limitInfo = staticCoverageTable.limitInfo
    if limitInfo == nil then
        return
    end
    resetLimitVersion(deviceName)
    local limitVersionPool = {}
    local limitIndexVersion = 0
    for _, limit in ipairs(limits) do
        if limit.duplicate then
            local pool = M.limitVersionCombo(limit, limitInfo)
            local limitVersionForEachRow = pl.stringx.join('_', pool)
            table.insert(limitVersionPool, limitVersionForEachRow)

            local limitNameString = C.createLimitName(limit.testname,
                                                      limit.subtestname,
                                                      limit.subsubtestname)
            local limitPositionInfo =
            limitInfo.limitPositionInfos[limitNameString]
            if limitPositionInfo ~= nil then
                local limitValue =
                limitPositionInfo.comboStringsMap[limitVersionForEachRow]
                if utils.isValidNumber(limitValue) and
                utils.isValidNumber(limitPositionInfo.weight) then
                    limitIndexVersion = limitValue * limitPositionInfo.weight +
                                        limitIndexVersion
                else
                    helpers.debugPrint(
                    "limitValue or limit weight is not a valid number: " ..
                    limitValue .. " or" .. limitPositionInfo.weight)
                end
            end
        end
    end

    table.sort(limitVersionPool)
    -- the 2nd part of limitsVersion: conditional string.
    -- limit table version(or called prefix elsewhere) not included.
    -- after the join, conditional string is never nil; empty string when nothing there
    local conditionalString
    local haveConditionalLimits = not helpers.isEmptyTable(
                                  limitInfo.limitPositionInfos)
    if haveConditionalLimits then
        if helpers.isNonEmptyTable(limitVersionPool) then
            conditionalString = pl.stringx.join('_', limitVersionPool)
        end
        conditionalString = limitVersionLengthCheck(deviceName,
                                                    conditionalString,
                                                    tostring(limitIndexVersion))
    end

    -- assemble the final schooner-generated limit version
    -- It might not be the final version; station code may override it later
    -- in final dag.
    local limitTableVersion = limitInfo.limitVersionPrefix

    local limitsVersionFromSchooner = helpers.join('_', {
        limitTableVersion,
        conditionalString
    })
    -- store it in global var so final dag can use it in registerLimitVersion()
    limitVersionTable[deviceName] = limitsVersionFromSchooner
end

local function registerLimitVersion(dag, deviceName)
    -- if previous result is '', there is no limit table version or
    -- conditional limits. use nil.
    local version = limitVersionTable[deviceName]
    version = overrideLimitVersion(deviceName, version)
    if version ~= nil then
        dag.add('schooner_register_limit_version_action',
                'Schooner/RegisterLimitVersionAction.lua', nil, version)
    else

        helpers.debugPrint('Schooner does not have a limits version to set;' ..
                           ' skip setting limits version.')
    end

    -- store the overridden limitVersion for unit test
    limitVersionTable[deviceName] = version
end

-- This function will schedule actions that submit a failure record for the following scenarios:
-- 1) Orphaned Records
-- 2) Number of limits before and after test execution
-- 3) Orphaned Limits that are also marked as `required` in the limits table
function M.scheduleRecordAndLimitSanitizationCoverage(dag, deviceName)
    if (Atlas.compareVersionTo("2.34.0.0") ~=
    Atlas.versionComparisonResult.lessThan) then
        dag.enableContinueOnAmIOkay()
    end

    helpers.clearThreads(dag)

    -- Refresh condition table after finished teardown coverage
    refreshConditionsAfterFinishedCoverage(deviceName, TEARDOWN)

    -- Check expression in "Required" column in limit table to determine if limit is required
    local coverage = currentRunCoverageTable[deviceName]
    local result, msg = M.handleLimitConditionExpression(deviceName,
                                                         coverage[LIMITS],
                                                         'required')

    -- If there are any failing records during the overlay’s test execution, then no need to publish
    -- orphaned record/limit failure records. See the following Radar for additional details:
    -- rdar://89330284 (Orphaned Records & Limits Check Only Applied After All Tests Pass).
    -- Atlas 2.35 deprecate Group.getDeviceOverallResult
    local getDeviceResult = Group.getDeviceCurrentResult or
                            Group.getDeviceOverallResult
    local deviceResult = getDeviceResult(deviceName)
    helpers.debugPrint("scheduleFinalDAG getDeviceCurrentResult(2: pass): " ..
                       deviceResult)

    -- Check for orphaned records
    publishOrphanedRecords(dag, deviceName, deviceResult)

    -- Check for orphaned limits that are also marked as `required`
    local orphanedRequiredLimitsForDevice =
    publishOrphanedRequiredLimits(dag, deviceName, deviceResult)

    -- Verify user has not added new limits after initial registration
    -- despite device result.
    publishPreRegisteredLimits(dag, deviceName)

    registerLimitVersion(dag, deviceName)

    -- for testing
    return orphanedRequiredLimitsForDevice, result, msg
end

local metatable = getmetatable(_G)
metatable.__index.main = M.schoonerMain
setmetatable(_G, metatable)

return M
