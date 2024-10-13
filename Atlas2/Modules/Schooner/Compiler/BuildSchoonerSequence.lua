#!/usr/bin/env AtlasLua

-----------------------
-- ## BuildSchoonerSequence
--
-- Convert Schooner Main CSV & test definitions in YAML to targetPath in Lua
----
-- @author Robert Kaluhiokalani
-- @copyright 2021
-- @script BuildSchoonerSequence
local compilerExecutable = arg[0]
local compilerPath = compilerExecutable:gsub('BuildSchoonerSequence.lua', '')
local pwd = os.getenv('PWD')
if not compilerPath:match('/%w+') then
    -- relative path
    compilerPath = pwd .. '/' .. compilerPath
end

-- this file is in Modules/Schooner/Compiler/
local atlas2ModulesPath = compilerPath .. '/../../'
-- adding Compiler/ folders to lua path, for AtlasLua/Lua
package.path = atlas2ModulesPath .. '/?.lua;'
package.path = package.path .. atlas2ModulesPath .. '/?/init.lua;'
package.path = package.path .. compilerPath .. '?.lua'

-- assuming compiler is in Modules/Schooner/Compiler/
package.cpath = compilerPath .. '../../Mooncake/?.so'

local argparse = require 'argparse'
local C = require('Compiler')
local pl = require('pl.import_into')()
local helpers = require("Schooner.SchoonerHelpers")

-- LuaFormatter off
local parser = argparse()
    :name 'AtlasLua BuildSchoonerSequence.lua'
    :description 'AtlasLua script compile Schooner coverage'
    :epilog 'frogger: https://frogger.apple.com/#/modules/XF.Schooner/Schooner'
parser:option()
    :name '-m --main'
    :description  'Path to main table. Mandatory.'
    :count '1'

parser:option()
    :name '-l --limit'
    :description  'Path to limit table. Omit when no limit file is used, which is rare but supported.'
    :count '0-1'        -- support case that has no limit table.

parser:option()
    :name '-c --condition'
    :description  'Path to condition table. Omit when station does not use condition.'
    :count '0-1'        -- support case that use no condition.

parser:option()
    :name '-s --sample'
    :description  'Path to sampling table'
    :count '0-1'        -- support case that use no sampling.

parser:option()
    :name '-v --limit-version-prefix'
    :description  'Limit version prefix from user'
    :count '0-1'     -- support case that use no limit-version-prefix.

parser:option()
    :name '-p --station-plist'
    :args '*'
    :description  'Input can be single or multiple plist path(s)'
    :count '0-1'     -- support case that use no or multiple station-plist.

parser:option()
    :name '-d --station-plist-directory'
    :args '*'
    :description  'Input can be single or multiple directory path(s)'
    :count '0-1'        -- support case that use no or multiple station-plist-directory.

parser:option()
    :name '-a --station-action-directories'
    :args '+'
    :description  'Input can be single or multiple directory path(s)'
    :count '0-1'        -- support case that use no or multiple action-directory.

parser:option()
    :name '-t --test-definition'
    :args '+'
    :description  ('Test definition file base folder. Mandatory. ' ..
                  'If main table use "aFolder/aYaml.yaml" as CoverageFile, ' ..
                  'the file should be available under baseFolder/aFolder/aYaml.yaml.')
    :count '1'

parser:option()
    :name '-o --output'
    :description  'Path to output file. Mandatory. For example ~/Library/Atlas2/Modules/coverage/coverage.lua'
    :count '1'
-- LuaFormatter on

local args = parser:parse()

-------------------------------------------------------------------------------
--- Main body
-------------------------------------------------------------------------------
local compiledSequence = C.compile(args.main, args.limit, args.condition,
                                   args.sample, args.limit_version_prefix,
                                   args.station_plist,
                                   args.station_plist_directory,
                                   args.station_action_directories,
                                   args.test_definition)

local targetFile = io.open(args.output, 'w')
targetFile:write('return  ' .. pl.pretty.write(compiledSequence))
targetFile:close()

local function dumpCompareFailInfo(failInfo)
    local typeOfFail = failInfo[1]

    if typeOfFail == helpers.tableCompareFailType["typeFail"] then
        print("Compiler output type changed after writing to file")
    elseif typeOfFail == helpers.tableCompareFailType["lenghtFail"] then
        print("Compiler output length changed after writing to file")
    elseif typeOfFail == helpers.tableCompareFailType["valueFail"] then
        local message
        print(failInfo[2])
        print("Before writing:")
        message = string.format("Type: %s, ", failInfo['table1'].type)
        if failInfo['table1'].value ~= nil then
            message = message .. "Value: " .. tostring(failInfo['table1'].value)
        end
        print(message)

        print("After writing:")
        message = string.format("Type: %s, ", failInfo['table2'].type)
        if failInfo['table2'].value ~= nil then
            message = message .. "Value: " .. tostring(failInfo['table2'].value)
        end
        print(message)
    end
end

-- Load coverage table from targetFile and compare with compiledSequence
local readBackSequence = loadfile(args.output)()
local compareResult, failInfo = helpers.compareTable(compiledSequence,
                                                     readBackSequence)
if not compareResult then
    dumpCompareFailInfo(failInfo)
    error("Compiler output changed after writing to file")
end
