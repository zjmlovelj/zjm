-- tokenize() make a conditions string to a table.
-- data structure for building tree from tokenized condition expression
-- basically a binary tree: each node has at most a left child and a right child; either child can be nil.
-- has a root.
-- for example: not (A==B and (C<D or X~=1) and Y<1)
--                    not
--                       \
--                      and(1)
--                    /      \
--                   <       and(2)
--                  / \     /     \
--                 Y   1   or      ==
--                       /    \   /  \
--                     ~=      <  A   B
--                    / \     / \
--                   X   1   C   D
-- when traversing the tree, start from the right-most node:
--  A==B -> C < D --> X ~= 1 --> or --> and(2) --> Y < 1 --> and(1) --> not
-- this is implemented by putting the tree nodes into a stack.
-- when adding the node:
--  - when root is empty, add current node as root.
-- creating subtree for a single condition expression without and/or/not:
--  - when current node is an identifier, number or quoted string, and a symbol
--    is to be added, move the symbol to root, and move the previous node as its left child.
--  A    -->       ==       -->       ==
--                /                  /  \
--               A                  A    1
--  - when an operator is added, check if it has higher presendence than current root
--      - if lower, change the new operator to be root, and move previous root to new root's right child
--      - if higher, move
local E = require('Schooner.Compiler.Errors')
local common = require('Schooner.SchoonerCommon')

local m = {}
local charset = {
    identifier = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.',
    -- in theory we don't support \r\n\t in Condition. but just in case.
    escape = '\\',
    singleQuote = '\'',
    doubleQuote = '"',
    space = ' \r\n\t',
    operator = '~=<>',
    group = '()',
    keyword = { 'and', 'or', 'not', 'AND', 'OR', 'NOT' }
}

local convertTable = {
    [0] = "0",
    [1] = "1",
    [2] = "2",
    [3] = "3",
    [4] = "4",
    [5] = "5",
    [6] = "6",
    [7] = "7",
    [8] = "8",
    [9] = "9",
    [10] = "A",
    [11] = "B",
    [12] = "C",
    [13] = "D",
    [14] = "E",
    [15] = "F",
    [16] = "G"
}

-- convert charset into dictionary of single char for quicker lookup.
for key, value in pairs(charset) do
    local singleChars = {}
    if type(value) == 'string' then
        for i = 1, value:len() do
            singleChars[value:sub(i, i)] = true
        end
    else
        for _, v in ipairs(value) do
            singleChars[v] = true
        end
    end
    charset[key] = singleChars
end

function m.getCharType(c)
    for k, v in pairs(charset) do
        if v[c] == true then
            return k
        end
    end
    E:conditionInvalidChar(c)
end

function m.processChar(t, i)
    if m.tokenType == 'inEscape' then
        m.tokenType = 'inQuote'
        return
    elseif m.tokenType == 'inQuote' then
        if t == 'escape' then
            m.tokenType = 'inEscape'
            return
        else
            if t == m.quoteType then
                -- end of quote; yield
                local yieldStartIndex = m.startIndex
                local yieldEndIndex = i
                m.startIndex = nil
                m.tokenType = 'space'
                return 'quotedString', yieldStartIndex, yieldEndIndex
            end
        end
    elseif m.tokenType == t and t ~= 'group' then
        -- within same token; return
        return
    else
        local yieldStartIndex = m.startIndex
        local yieldTokenType = m.tokenType

        if t == 'singleQuote' then
            m.tokenType = 'inQuote'
            m.quoteType = 'singleQuote'
        elseif t == 'doubleQuote' then
            m.tokenType = 'inQuote'
            m.quoteType = 'doubleQuote'
        else
            m.tokenType = t
        end
        m.startIndex = i

        -- if previous token is space, nothing to yield
        -- otherwise, yield previous token and start next one.
        if yieldTokenType ~= 'space' then
            -- end of a new token; yield
            local yieldEndIndex = i - 1
            return yieldTokenType, yieldStartIndex, yieldEndIndex
        else
            return
        end
    end
end

function m.getNumFromChar(char)
    for k, v in pairs(convertTable) do
        if v == char then
            return k
        end
    end
    return 0
end

-- change str to Dec num
function m.convertStr2Dec(text, base)
    local baseTable = {}
    local len = string.len(text)
    local index = len

    while (index > 0) do
        local char = string.sub(text, index, index)
        baseTable[#baseTable + 1] = m.getNumFromChar(char)
        index = index - 1
    end

    local num = 0
    for digit, value in ipairs(baseTable) do
        num = num + value * (base ^ (digit - 1))
    end
    return num
end

function m.toNumber(s)
    local ret
    -- dec or hex number
    if string.match(s, "^([-+]?)([0-9]+)$") or
    string.match(s, "^0x([0-9a-fA-F]+)$") then
        ret = tonumber(s)

    elseif string.match(s, "^0o([0-7]+)$") then
        -- oct number
        -- take string start with the third char
        local retuint = string.sub(s, 3)
        ret = m.convertStr2Dec(retuint, 8)
    elseif string.match(s, "^[-+]?(.inf)$") or string.match(s, "^[-+]?(.INF)$") or
    string.match(s, "^[-+]?(.Inf)$") then
        if s:sub(1, 1) == '-' then
            ret = '-.INF'
        else
            ret = '.INF'
        end
    elseif string.match(s, ".NAN") or string.match(s, ".NaN") or
    string.match(s, ".nan") then
        ret = '.NAN'

        -- float num
    elseif string.match(s, "^[-+]?[0-9]+%.[0-9]+$") or
    string.match(s, "^[-+]?[0-9]+%.[0-9]+[eE][-+]?[0-9]+$") or
    string.match(s, "^[-+]?%.[0-9]+[eE][-+]?[0-9]+$") or
    string.match(s, "^[-+]?%.[0-9]+$") then
        ret = tonumber(s)
    else
        ret = nil
    end
    return ret
end

function m.checkForRestrictedConditionNames(stringValue)
    if string.lower(stringValue) == common.PRODUCT or string.lower(stringValue) ==
    string.lower(common.STATION_TYPE) or string.lower(stringValue) ==
    common.MODE then
        E:conditionInvalidVariable(stringValue)
    end
end

function m.insertToTable(n, tokenType, stringValue, ret)
    if n ~= nil then
        table.insert(ret, { type = 'number', value = n })
    else
        if tokenType == "identifier" then
            if charset.keyword[stringValue] == true then
                table.insert(ret, { type = 'keyword', value = stringValue })
            else
                table.insert(ret, { type = tokenType, value = stringValue })
            end
        else
            table.insert(ret, { type = tokenType, value = stringValue })
        end
    end
end

-- separate input string into tokens.
-- @arg input   string to parse
-- @return      list of tokens following input order
--              each token is a table with `tokenType` and `value` keys
--              tokenType: predefined string:
--                  operator: and or not
--                  identifier: condition variable
--                  quotedString: as name
--                  number: as name
--                  symbol: <=>~
--                  parentheses: ()
--              value: the string value of token.
function m.tokenize(input)
    local ret = {}

    if input == nil or input == '' then
        return {}
    end

    -- append an space after input string to finish the last token when last char is not space.
    input = input .. ' '
    m.startIndex = 1
    m.tokenType = 'space'
    m.quoteType = nil

    for i = 1, input:len() do
        local c = input:sub(i, i)
        local t = m.getCharType(c)
        local tokenType, startIndex, endIndex = m.processChar(t, i)
        if tokenType ~= nil then
            local stringValue = input:sub(startIndex, endIndex)
            local n = m.toNumber(stringValue)
            m.checkForRestrictedConditionNames(stringValue)
            m.insertToTable(n, tokenType, stringValue, ret)
        end
    end
    return ret
end

return m
