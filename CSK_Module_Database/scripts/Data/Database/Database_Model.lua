---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_Database'

local database_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
database_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Check if CSK_PersistentData module can be used if wanted
database_Model.persistentModuleAvailable = CSK_PersistentData ~= nil or false

-- Default values for persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
database_Model.parametersName = 'CSK_Database_Parameter' -- name of parameter dataset to be used for this module
database_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

-- Load script to communicate with the Database_Model interface and give access
-- to the Database_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setDatabase_ModelHandle = require('Data/Database/Database_Controller')
setDatabase_ModelHandle(database_Model)

--Loading helper functions if needed
database_Model.helperFuncs = require('Data/Database/helper/funcs')

-- Create parameters / instances for this module
database_Model.database = Database.SQL.SQLite.create() -- Handle of database

database_Model.currentActiveDatabase = '' -- Name of curretly active database
database_Model.selection = '' -- Selection within UI database entry table
database_Model.query = 'select * from databaseName' -- SQL query to call
database_Model.queryContent = {} -- Result of query
database_Model.nextIDStatement = nil --database_Model.database:prepare("select case when max(ID) is null then 1 else max(ID) + 1 end from dTags")
database_Model.nextID = nil -- Next ID value of nextIDStatement:getColumnInt

database_Model.insertStmt = nil -- Insert statement like 'database_Model.database:prepare("insert into " .. database_Model.parameters.nameOfDatabase .. " values(?,?,?,?)")'

database_Model.databaseColumns = {} -- Column labels of SQL database
database_Model.content = nil -- Temp content for SQL execution

-- Parameters to be saved permanently if wanted
database_Model.parameters = {}
database_Model.parameters.nameOfDatabase = '' -- Name of database to use
database_Model.parameters.locationOfDatabase = "/public/" -- Location of the database
database_Model.parameters.databasePath = database_Model.parameters.locationOfDatabase .. database_Model.parameters.nameOfDatabase .. '.db'
database_Model.parameters.registeredEvent = '' -- Name of event to receive new data entries
database_Model.databaseColumnsInfo = '' -- Database column information like 'Event text, MetaDataLocation text,ImageLocation text'

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Function to close latest used database
local function closeDatabase()
  database_Model.database:close()
  Script.releaseObject(database_Model.database)
  database_Model.database = nil
  collectgarbage()

  database_Model.database = Database.SQL.SQLite.create()

  database_Model.insertStmt = nil
  database_Model.nextIDStatement = nil
end

-- Function to create new database
local function createDatabase()

  if database_Model.parameters.nameOfDatabase ~= '' then

    _G.logger:info(nameOfModule .. ": Create database with name '" .. tostring(database_Model.parameters.nameOfDatabase) .. "'")

    closeDatabase()

    local tempStateString = ''
    for _, v in pairs(database_Model.databaseColumns) do
      tempStateString = tempStateString .. ',?'
    end

    database_Model.content = "create table if not exists " .. database_Model.parameters.nameOfDatabase .." (ID int primary key not null ," .. database_Model.databaseColumnsInfo .. ");"
    database_Model.parameters.databasePath = database_Model.parameters.locationOfDatabase .. database_Model.parameters.nameOfDatabase .. ".db"

    database_Model.helperFuncs.createFolder(database_Model.parameters.locationOfDatabase)

    database_Model.database:openFile(database_Model.parameters.databasePath, "READ_WRITE_CREATE")
    local couldExec = database_Model.database:execute(database_Model.content)
    if couldExec then
      _G.logger:fine(nameOfModule .. ": Could set-up DB")
      database_Model.currentActiveDatabase = database_Model.parameters.nameOfDatabase
    else
      _G.logger:warning(nameOfModule .. ": Could not set-up DB: " .. database_Model.database:getErrorMessage())
    end

    database_Model.nextIDStatement = database_Model.database:prepare("select case when max(ID) is null then 1 else max(ID) + 1 end from " .. database_Model.parameters.nameOfDatabase)
    database_Model.nextIDStatement:step()
    database_Model.nextID = database_Model.nextIDStatement:getColumnInt(0)
    database_Model.insertStmt = database_Model.database:prepare("insert into " .. database_Model.parameters.nameOfDatabase .. " values(?" .. tempStateString .. ")") -- Insert statement
    return true
  else
    _G.logger:info(nameOfModule .. ": No name for database")
    return false
  end
end
database_Model.createDatabase = createDatabase

local function loadDatabase()

  closeDatabase()
  local suc = database_Model.database:openFile(database_Model.parameters.databasePath, "READ_WRITE_CREATE")
  if not suc then
    _G.logger:fine(nameOfModule .. ": Not able to open database")
  else
    database_Model.currentActiveDatabase = database_Model.parameters.nameOfDatabase
    local stmt = database_Model.database:prepare("PRAGMA table_info(" .. database_Model.parameters.nameOfDatabase .. ")")

    local tempString = ''
    local tempStateString = ''
    local firstEntry = true

    -- Get info about used column labels
    while true do
      local check = stmt:step()
      if check == 'ROW' then
        local str = stmt:getColumnsAsString()
        local firstPos = string.find(str, "'")
        if firstPos then
          local secondPos = string.find(str, "'", firstPos+1)
          if secondPos then
            local name = string.sub(str, firstPos+1, secondPos-1)

            if name ~= 'ID' then

              tempStateString = tempStateString .. ',?'
              if firstEntry then
                tempString = tempString .. name
                firstEntry = false
              else
                tempString = tempString .. ', ' .. name
              end

              local typeStartPos = string.find(str, "'", secondPos+1)
              if typeStartPos then
                local typeEndPos = string.find(str, "'", typeStartPos+1)
                if typeEndPos then
                  local columnType = string.sub(str, typeStartPos+1, typeEndPos-1)
                  tempString = tempString .. ' ' .. columnType
                end
              end
            end
          end
        end
      else
        break
      end
    end
    CSK_Database.setColumnsInfo(tempString)

    database_Model.nextIDStatement = database_Model.database:prepare("select case when max(ID) is null then 1 else max(ID) + 1 end from " .. database_Model.parameters.nameOfDatabase)
    if not database_Model.nextIDStatement then
      _G.logger:warning(nameOfModule .. ": Could not prepare nextIDStatement: " .. database_Model.database:getErrorMessage())
    else
      database_Model.nextIDStatement:step()
      database_Model.nextID = database_Model.nextIDStatement:getColumnInt(0)
      database_Model.insertStmt = database_Model.database:prepare("insert into " .. database_Model.parameters.nameOfDatabase .. " values(?" .. tempStateString .. ")") -- Insert statement
    end
  end

  CSK_Database.pageCalled()

end
database_Model.loadDatabase = loadDatabase

-- Function to add new database entry
---@param data1 auto Data1
---@param data2 auto[?] Data2
---@param data3 auto[?] Data3
---@param data4 auto[?] Data4
---@param data5 auto[?] Data5
local function insert(data1, data2, data3, data4, data5)
  if (database_Model.insertStmt ~= nil) then
    if #database_Model.databaseColumns == 1 then
      database_Model.insertStmt:bind(0, database_Model.nextID, data1)
    elseif #database_Model.databaseColumns == 2 then
      database_Model.insertStmt:bind(0, database_Model.nextID, data1, data2)
    elseif #database_Model.databaseColumns == 3 then
      database_Model.insertStmt:bind(0, database_Model.nextID, data1, data2, data3)
    elseif #database_Model.databaseColumns == 4 then
      database_Model.insertStmt:bind(0, database_Model.nextID, data1, data2, data3, data4)
    elseif #database_Model.databaseColumns == 5 then
      database_Model.insertStmt:bind(0, database_Model.nextID, data1, data2, data3, data4, data5)
    end

    if (database_Model.insertStmt:step() == "DONE") then
      database_Model.nextID = database_Model.nextID + 1
    else
      _G.logger:warning(nameOfModule .. ": Could not insert data: " .. database_Model.insertStmt:getErrorMessage())
    end
    database_Model.insertStmt:reset()
  else
    _G.logger:warning(nameOfModule .. ": Could not insert data into DB because statement is not pre-compiled")
  end
end
database_Model.insert = insert

-- Function to execute SQL query
---@param sqlQuery string SQL query
---@return queryResult any[?] Result of query result
local function exec(sqlQuery)
  --print("Query is = " .. sqlQuery) -- Only for debugging
  local queryResult = nil
  if (database_Model.database ~= nil) then
    local tempStmt = database_Model.database:prepare(sqlQuery)
    if (tempStmt ~= nil) then
      local stepResult = tempStmt:step()
      if (stepResult == "DONE") then
        -- SKIP
      elseif (stepResult == "ROW") then
        local tempString = ''

        for i=1, #database_Model.databaseColumns do
          tempString = tempString .. ',' .. tostring(i)
        end


        local tempContentTables = {}
        local columns = tempStmt:getColumns("string:[0" .. tempString .. "]")
        for key, value in pairs(columns) do
          tempContentTables[key] = {}
          table.insert(tempContentTables[key], value)
        end

        local str = tempStmt:getColumnsAsString()
        while (tempStmt:step() == "ROW") do
          str = str .. "\r\n" .. tempStmt:getColumnsAsString()

          local tableString = tempStmt:getColumsForLuaTable()
          local resultTable = tempStmt:getColumns("string:[0" .. tempString .. "]")
          for key, value in pairs(resultTable) do
            table.insert(tempContentTables[key], value)
          end
        end
        --print(str) -- For debugging
        queryResult = tempContentTables
      elseif (stepResult == "ERROR") then
        _G.logger:warning(nameOfModule .. ": Error: " .. tempStmt:getErrorMessage())
      end
    else
      _G.logger:warning(nameOfModule .. ": Could not exec statement: " .. database_Model.database:getErrorMessage())
    end
  else
    _G.logger:warning(nameOfModule .. ": DB is not correctly set-up")
  end
  return queryResult
end
database_Model.exec = exec

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************

return database_Model
