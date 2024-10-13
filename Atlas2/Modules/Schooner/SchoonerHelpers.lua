local helpers = {}

local pretty = require("pl.pretty")

local debugLog = true

function helpers.disableDebugLogs() debugLog = false end

function helpers.debugPrint(msg)
    if debugLog then
        print('Debug: ' .. tostring(msg))
    end
end

function helpers.try(f, catch_f, ...)
    local status, exception = xpcall(f, debug.traceback, ...)
    if not status then
        catch_f(exception)
    end
end

-- Accept any type variable, dump with indentation.
-- Keep second variable `description` empty to be compatible with previous dump
function helpers.dump(var, description)
    local msg
    if type(var) == "table" then
        msg = pretty.write(var)
    elseif type(var) == "string" then
        msg = '"' .. tostring(var) .. '"'
    else
        msg = tostring(var)
    end

    if description ~= nil then
        msg = tostring(description) .. ": " .. msg
    end
    return msg
end

function helpers.dumpPrint(var, name) print(helpers.dump(var, name)) end

-- string split by a mixed delimiter.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitBySeveralDelimiter("a&&b||c&&d","&|") => {"a","b","c","d"}
function helpers.splitBySeveralDelimiter(input, delimiter)
    if not input or not delimiter then
        return nil
    end
    local resultStrArr = {}
    string.gsub(input, '[^' .. delimiter .. ']+',
                function(w) table.insert(resultStrArr, w) end)
    return resultStrArr
end

-- check if value exists in an array
-- e.g. hasVal({"d", "e",},"d") => true
function helpers.hasVal(valueArr, valueStr)
    for _, value in ipairs(valueArr) do
        if value == valueStr then
            return true
        end
    end
    return false
end

function helpers.isNonEmptyString(str)
    return str ~= nil and type(str) == 'string' and str ~= ''
end

function helpers.isTable(t) return type(t) == 'table' end

function helpers.isNonEmptyTable(t) return helpers.isTable(t) and next(t) ~= nil end

function helpers.isEmptyTable(t) return helpers.isTable(t) and next(t) == nil end

function helpers.isNilOrEmptyTable(t) return t == nil or helpers.isEmptyTable(t) end

-- Convert an input array into an output string using ',' as the default delimiter
-- dividing array elements.
-- Example:
-- array: {"str1", "str2"}
-- str: "str1,str2"
function helpers.convertArrayToString(arr, delimiter)
    local str = ""
    local isFirstElement = true

    if delimiter == nil then
        delimiter = ','
    end
    for _, element in ipairs(arr) do
        if isFirstElement == true then
            str = element
        else
            str = str .. delimiter .. element
        end
    end

    return str
end

-- Swap the keys and values of an input array, creating a new output object with
-- inverted keys and values.
-- Example:
-- inputObject: {1: "A", 2: "B", 3: "C"}
-- outputObject: {A: 1, B: 2, C: 3}
function helpers.invertArray(arr)
    local newMap = {}
    for i, value in ipairs(arr) do
        newMap[value] = i
    end
    return newMap
end

-- For a given dictionary styled Lua table (ex. {'k1'='v1, 'k2' = 'v2'})
-- Generate an array using the dictionary's values (ex. {'v1', 'v2'})
function helpers.convertDictionaryValuesToArray(dict)
    local arr = {}
    for _, v in pairs(dict) do
        table.insert(arr, v)
    end

    return arr
end

-- Returns true if item exists in arr, false otherwise
function helpers.doesItemExistInArray(arr, item)
    for _, element in ipairs(arr) do
        if element == item then
            return true
        end
    end

    return false
end

function helpers.max(list)
    assert(list ~= nil, 'max: given list is nil')
    assert(type(list) == 'table', 'max: given list is not a table')
    assert(next(list) ~= nil, 'max: given list is empty')

    local max = list[1]
    for _, i in ipairs(list) do
        if i > max then
            max = i
        end
    end
    return max
end

-- return a cloned table.
function helpers.clone(org)
    if org == nil then
        return
    end
    local function copy(origin, res)
        for k, v in pairs(origin) do
            if type(v) ~= "table" then
                res[k] = v;
            else
                res[k] = {};
                copy(v, res[k])
            end
        end
    end
    local res = {}
    copy(org, res)
    return res
end

-- return keys of a table
-- e.g. tableKeys({4,5,["a"]="44",}) => {1,2,"a",}
function helpers.tableKeys(input_table)
    if not input_table then
        return nil
    end
    local output_keys = {}
    for k, _ in pairs(input_table) do
        table.insert(output_keys, k)
    end
    return output_keys
end

-- For each of the given keys, copy from source to target
function helpers.tableOverride(source, target, keys)
    for _, key_name in ipairs(keys) do
        if source[key_name] ~= nil then
            target[key_name] = source[key_name]
        end
    end
end

-- trim spaces around given string.
function helpers.trim(s) return s:gsub("^%s*(.-)%s*$", "%1") end

-- return a string of plist which removed spaces.
function helpers.readPlist(path)
    assert(path ~= nil, 'SchoonerHelpers.readPlist(path): path is nil')
    local PlistContent = helpers.readFile(path)
    return PlistContent
end

-- return file content in string. raise error() for error.
function helpers.readFile(path)
    assert(path ~= nil, 'SchoonerHelpers.readFile(path): path is nil')
    local fd = io.open(path, 'r')
    if fd == nil then
        error('Failed to open file at path ' .. tostring(path))
    else
        local content = fd:read("*a")
        fd:close()
        return content
    end
end

function helpers.hexdecode(hex)
    return (hex:gsub("%x%x", function(digits)
        return string.char(tonumber(digits, 16))
    end))
end

function helpers.hexencode(str)
    return (str:gsub(".", function(char)
        return string.format("%2x", char:byte())
    end))
end

function helpers.ls(path, args)
    local cmd = 'ls ' .. path
    if args then
        cmd = cmd .. ' ' .. args
    end
    local f = io.popen(cmd)
    local ret = {}
    for line in f:lines() do
        ret[#ret + 1] = line
    end
    f:close()
    return ret
end

local function createStringOfKey(key)
    local typeKey = type(key)
    local strOfKey = ""

    if typeKey == 'string' then
        strOfKey = string.format("Key - %s", key)
    elseif typeKey == 'number' then
        strOfKey = string.format("Index - %d", key)
    end

    return strOfKey
end

helpers.tableCompareFailType = { typeFail = 1, lenghtFail = 2, valueFail = 3 }

function helpers.compareTable(table1, table2)
    local typeTable1 = type(table1)
    local typeTable2 = type(table2)

    -- failInfo[1] is type of the failure
    local failInfo = {}

    if (typeTable1 ~= 'table') or (typeTable2 ~= 'table') then
        failInfo[1] = helpers.tableCompareFailType['typeFail']
        return false, failInfo
    end

    local numberOfItems = 0
    for k, v1 in pairs(table1) do
        -- v2 could be nil
        local v2 = table2[k]

        local vt1 = type(v1)
        local vt2 = type(v2)
        if vt1 ~= vt2 then
            failInfo[1] = helpers.tableCompareFailType['valueFail']
            failInfo[2] = createStringOfKey(k)
            failInfo['table1'] = {} -- type/value of the element in table 1
            failInfo['table2'] = {} -- type/value of the element in table 2
            failInfo['table1'].type = vt1
            failInfo['table1'].value = nil
            failInfo['table2'].type = vt2
            failInfo['table2'].value = nil
            return false, failInfo
        end

        if vt1 ~= 'table' then
            if v1 ~= v2 then
                -- Within this branch, type of v1/v2 can only be string/number/bool
                -- v1 and v2 have same type but not 'table'
                failInfo[1] = helpers.tableCompareFailType['valueFail']
                failInfo[2] = createStringOfKey(k)
                failInfo['table1'] = {} -- type/value of the element in table 1
                failInfo['table2'] = {} -- type/value of the element in table 2
                failInfo['table1'].type = vt1
                failInfo['table1'].value = v1
                failInfo['table2'].type = vt2
                failInfo['table2'].value = v2
                return false, failInfo
            end
        else
            -- Within this branch, type of both v1 and v2 are 'table'
            local compareResult
            compareResult, failInfo = helpers.compareTable(v1, v2)
            if not compareResult then
                return compareResult, failInfo
            end

            failInfo = {}
        end

        numberOfItems = numberOfItems + 1
    end

    for _, _ in pairs(table2) do
        numberOfItems = numberOfItems - 1
    end

    if (numberOfItems ~= 0) then
        failInfo[1] = helpers.tableCompareFailType['lenghtFail']
        return false, failInfo
    end

    return true
end

function helpers.fileExist(path)
    local file = io.open(path, 'r')
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

function helpers.lsFileName(path, args)
    local cmd = 'ls ' .. path
    if args then
        cmd = cmd .. ' ' .. args
    end
    local f = io.popen(cmd)
    local ret = {}
    for line in f:lines() do
        ret[#ret + 1] = string.match(line, '[^%/]+%w$')
    end
    f:close()
    return ret
end

function helpers.lsDirectory(path)
    local cmd = 'ls -d ' .. path
    cmd = cmd .. '/*/'
    local f = io.popen(cmd)
    local ret = {}
    for line in f:lines() do
        ret[#ret + 1] = string.sub(line, 1, -2):match('[^%/]+%w$')
    end
    f:close()
    return ret
end

-- only call clear threads if Atlas2 < 2.35.
-- Starting from Atlas2 2.35, threadpool limit becomes unlimited.
function helpers.clearThreads(dag)
    if (Atlas.compareVersionTo("2.35.0.0") ==
    Atlas.versionComparisonResult.lessThan) then
        dag.clearThreads()
    end
end

-- extend pl.stringx.join to support schooner special usage
-- return nil if table is empty; otherwise return pl.stringx.join
function helpers.join(sep, s)
    local t = {}

    -- support s being {nil, value}
    for i = 1, #s do
        local v = s[i]
        if v ~= nil then
            table.insert(t, v)
        end
    end

    if helpers.isEmptyTable(t) then
        return nil
    else
        local pl = require('pl.import_into')()
        return pl.stringx.join(sep, t)
    end
end

-- wrapper function to print the error message and fail device
function helpers.printAndFailDevice(device, msg)
    print(msg)
    Group.failDevice(device, msg)
end

return helpers
