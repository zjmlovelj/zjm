-- The following module is used to sanitize records & limits to prevent the user from accidentally and/or
-- purposefully modifying limits or adding unecessary test records.  There are three scenarios that will
-- cause Schooner to report a failure to Insight:
-- 1) Orphaned limits - Limits that exist but are not associated with any records
-- 2) Orphaned records - Records that exist but are not associated with any limits
-- 3) Pre-registered Limits vs Post-execution Limits.  The number of limits that are registered before any
--    actions are run, should be the same as the number of limits that are registered after all actions
--    are run.  This is to prevent the user from adding limits during their test execution.
local helpers = require('Schooner.SchoonerHelpers')

local limitsRecordsSanitizer = {}
local preRegisteredLimitCount = 0

limitsRecordsSanitizer.dataType = {
    typeOrphanedRecords = {
        test = 'Schooner',
        subtest = 'SchoonerRecordsCheck',
        subsubtest = 'OrphanedRecords',
        errMsg = 'There are >1 orphaned records within your test coverage.  Check atlas.log for details.'
    },
    typeOrphanedLimits = {
        test = 'Schooner',
        subtest = 'SchoonerLimitsCheck',
        subsubtest = 'OrphanedRequiredLimits',
        errMsg = 'There are >1 orphaned required limits within your test coverage.  Check atlas.log for details.'
    },
    typePreRegisteredLimits = {
        test = 'Schooner',
        subtest = 'SchoonerLimitsCheck',
        subsubtest = 'PreRegisteredLimits',
        errMsg = 'Failure: Mismatch between the number of limits in the limits table ' ..
        'and the number of limits after test run.  Make sure all limits ' ..
        'in your test coverage are registered through the JAMA limits table'
    }
}

-- Return a limit nested dictionary that only comprises of limits whose `required` column is marked as true
local function getRequiredLimits(coverageTableLimits)
    local limitsMarkedRequired = {}

    for _, limitEntry in pairs(coverageTableLimits) do
        if limitEntry.required == true then
            if limitsMarkedRequired[limitEntry.testname] == nil then
                limitsMarkedRequired[limitEntry.testname] = {}
            end

            if limitsMarkedRequired[limitEntry.testname][limitEntry.subtestname] ==
            nil then
                limitsMarkedRequired[limitEntry.testname][limitEntry.subtestname] =
                {}
            end

            limitsMarkedRequired[limitEntry.testname][limitEntry.subtestname][limitEntry.subsubtestname] =
            {}
        end
    end

    return limitsMarkedRequired
end

-- Add entry for preregistered limits to the coverage table
local function addLimitEntryToLimitsTable(coverageTableLimits,
                                          limitDataType)
    local limitsForPreregisteredLimits = {
        required = false,
        testname = limitDataType.test,
        subtestname = limitDataType.subtest,
        subsubtestname = limitDataType.subsubtest
    }

    table.insert(coverageTableLimits, limitsForPreregisteredLimits)
end

-- Add limit entry for orphaned limits or records to the coverage table
function limitsRecordsSanitizer.addOrphanedItemToLimitsTable(
coverageTableLimits, orphanedItem)
    return addLimitEntryToLimitsTable(coverageTableLimits, orphanedItem)
end

-- Set the number of limits registered prior to test coverage execution
function limitsRecordsSanitizer.setPreRegisteredLimitsCount(coverageTableLimits)
    addLimitEntryToLimitsTable(coverageTableLimits,
                               limitsRecordsSanitizer.dataType
                               .typePreRegisteredLimits)
    preRegisteredLimitCount = #coverageTableLimits
end

-- Returns the number of limits registered prior to test coverage execution
function limitsRecordsSanitizer.getPreRegisteredLimitsCount()
    return preRegisteredLimitCount
end

local function doesLimitMatchWithSubSubTest(orphanedLimit,
                                            requiredLimits)
    if requiredLimits[orphanedLimit.testname] and
    requiredLimits[orphanedLimit.testname][orphanedLimit.subtestname] and
    requiredLimits[orphanedLimit.testname][orphanedLimit.subtestname][orphanedLimit.subsubtestname] then
        return true
    else
        return false
    end
end

local function doesLimitMatchWithoutSubSubTest(orphanedLimit,
                                               requiredLimits)
    if requiredLimits[orphanedLimit.testname] and
    requiredLimits[orphanedLimit.testname][orphanedLimit.subtestname] and
    requiredLimits[orphanedLimit.testname][orphanedLimit.subtestname][orphanedLimit.subsubtestname] ==
    nil and orphanedLimit.subsubtestname == nil then
        return true
    else
        return false
    end
end

-- Get the number of limit entries that are both orphaned and marked as required in the limits table
function limitsRecordsSanitizer.getOrphanedRequiredLimits(coverageTableLimits,
                                                          deviceName)
    local requiredLimits = getRequiredLimits(coverageTableLimits)
    local orphanedLimits = Group.getDeviceOrphanedLimits(deviceName)
    local orphanedRequiredLimits = {}

    for _, orphanedLimit in pairs(orphanedLimits) do
        if (doesLimitMatchWithSubSubTest(orphanedLimit, requiredLimits) == true) or
        (doesLimitMatchWithoutSubSubTest(orphanedLimit, requiredLimits) == true) then
            table.insert(orphanedRequiredLimits, orphanedLimit)
        end
    end

    -- Inform user of missing limits
    for _, limit in pairs(orphanedRequiredLimits) do
        local subsubtestname
        if limit.subsubtestname == nil then
            subsubtestname = ""
        else
            subsubtestname = limit.subsubtestname
        end

        local msg = "Orphaned Required Limit: "
        msg = msg .. limit.testname .. " "
        msg = msg .. limit.subtestname .. " " .. subsubtestname
        helpers.debugPrint(msg)
    end

    return orphanedRequiredLimits
end

return limitsRecordsSanitizer
