local clone = require('Schooner.SchoonerHelpers').clone
local dump = require('Schooner.SchoonerHelpers').dump
local C = require('Schooner.Compiler.CompilerHelpers')
local common = require('Schooner.SchoonerCommon')

-- Library to build a tree from CSV entries.
-- Each layer of the tree is for a key (ex: Layer 1 = Technology, Layer 2 = Coverage).
-- Example tree that support 3 keys with a few values in leaf nodes:
--         {T1, T2}
--         /      \
--       {C1}    {C2}
--        /           \
--    {P1={}, P2={}}  {Px={}}
-- Tree leaf (root[T1][C1][P1]) stores the test/limit item.
local M = {}

-- Helper function to split a row into all possible combinations of filter values
-- @arg: row - CSV content
-- @arg: keys - keys to parse (e.g. Technology, Mode)
-- Input: {Technology = 'T1', Mode = {'Production', 'Audit'}}
-- Output: {
-- {Technology = 'T1', Mode = 'Production'},
-- {Technology = 'T1', Mode = 'Audit'},
-- }
function M.splitRows(row, keys)
    local ret = { clone(row) }
    for _, key in ipairs(keys) do
        -- Ignore string-valued keys (e.g. Technology = 'T1') or nil
        if type(row[key]) == 'string' or row[key] == nil then
            goto continue
        end
        -- For each key, keep the expanded rows in a temporary table
        local temp = {}
        for _, r in ipairs(ret) do
            for _, v in ipairs(row[key]) do
                local copy = clone(r)
                copy[key] = v
                table.insert(temp, copy)
            end
        end
        ret = clone(temp)
        ::continue::
    end
    return ret
end

-- Split each row of CSV content by filter values, and merge all into a single table
-- @arg: csvContent - rows of CSV
-- @arg: keys - keys to process
function M.splitAndMerge(csvContent, keys)
    local ret = {}
    for _, item in ipairs(csvContent) do
        local split = M.splitRows(item, keys)
        for _, newRow in ipairs(split) do
            -- Keep track of original row number for error reporting
            newRow.index = item.originalRowIdx + common.NUM_HEADER_LINES
            table.insert(ret, newRow)
        end
    end
    return ret
end

-- Build a tree for given table (e.g. CSV content), using given keys.
-- @arg: csvContent - CSV content in Lua table format
-- @arg: keys - keys to look for in table, used to build tree in particular order
-- @arg: duplicateHandler - function to handle duplicate checking for different CSV types
function M.buildTree(csvContent, keys, duplicateHandler)

    local message =
    "[Internal] duplicateHandler in buildTree must be a function, but got %s"
    message = message:format(type(duplicateHandler))
    assert(type(duplicateHandler) == 'function', message)

    local tree = {}
    for _, row in ipairs(csvContent) do
        local node = tree
        for i, key in ipairs(keys) do
            -- Empty filter (e.g. Product/StationType) is set to nil
            local value = row[key] or ''
            -- Either has seen value before, or start new node
            node[value] = node[value] or {}
            node = node[value]
            -- Looking at leaf
            if i == #keys then
                if node.conditionData == nil then
                    -- noConditions == true means we've seen a duplicate entry with nil conditions
                    local identifiers = C.extractIdentifiers(row.conditions)
                    node.conditionData = {
                        seenDuplicate = false,
                        noConditions = row.conditions == nil,
                        firstSeenIdx = row.index,
                        identifiersCounter = C.updateIdentifiersCounter({},
                                                                        identifiers),
                        numEntries = 1,
                        isSetLimit = C.isSetLimit(row)
                    }
                    if row.conditions ~= nil then
                        node.conditionData[row.conditions] = true
                    end
                    node.entries = {}
                else
                    node.conditionData.seenDuplicate = true
                end
                if node.conditionData.seenDuplicate then
                    duplicateHandler(row, node.conditionData)
                end
                table.insert(node.entries, row)
            end
        end
    end
    return tree
end

-- TODO: Use OOP to build tree rdar://111764096
-- Duplicate entries in Main.csv are currently NOT handled with Tree.lua
local duplicateHandlers = { [common.LIMITS] = C.processDuplicateLimitEntries }
setmetatable(duplicateHandlers, {
    __index = function(_, k)
        local message = '[Internal] Unsupported CSV type "%s" for buildTree'
        message = message:format(tostring(k))
        error(message)
    end
})

-- @arg: csvType - string value indicating CSV being parsed
function M.buildTreeForCSV(csvType, csvContent, keys)
    return M.buildTree(csvContent, keys, duplicateHandlers[csvType])
end

-- adding a node to an existing tree
-- @arg keys: array of tree nodes
function M.add(tree, keys, errorOnDuplicate)
    if errorOnDuplicate ~= nil and type(errorOnDuplicate) ~= 'boolean' then
        error('tree.add: errorOnDuplicate should be nil or bool')
    end
    local node = tree
    for i, key in ipairs(keys) do
        -- last key; set node
        if i == #keys then
            -- assuming #keys is consistent.
            if errorOnDuplicate == true then
                if node[key] ~= nil then
                    error('tree.add: ' .. dump(keys) .. ' already exists.')
                end
            end
            node[key] = {}
            return
        end

        if node[key] == nil then
            -- new node
            node[key] = {}
        end
        node = node[key]
    end
end

-- return a leaf node with all its subsub as key, like
-- {sub0={}, sub1={}, ...}
-- return nil when testParameters is not found.
function M.findInTree(tree, values)
    local node = tree
    for _, value in ipairs(values) do
        if node == nil then
            error('value not found: ' .. value)
        end
        node = node[value]
    end
    return node
end

return M
