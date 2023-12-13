---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the Database_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_Database'

-- Timer to update UI via events after page was loaded
local tmrDatabase = Timer.create()
tmrDatabase:setExpirationTime(300)
tmrDatabase:setPeriodic(false)

-- Reference to global handle
local database_Model

-- ************************ UI Events Start ********************************

Script.serveEvent('CSK_Database.OnNewStatusActiveDatabaseName', 'Database_OnNewStatusActiveDatabaseName')
Script.serveEvent('CSK_Database.OnNewStatusDatabaseName', 'Database_OnNewStatusDatabaseName')
Script.serveEvent('CSK_Database.OnNewStatusDatabaseLocation', 'Database_OnNewStatusDatabaseLocation')

Script.serveEvent('CSK_Database.OnNewStatusColumnList', 'Database_OnNewStatusColumnList')

Script.serveEvent('CSK_Database.OnNewStatusRegisteredEvent', 'Database_OnNewStatusRegisteredEvent')

Script.serveEvent('CSK_Database.OnNewStatusQuery', 'Database_OnNewStatusQuery')
Script.serveEvent('CSK_Database.OnNewTableContent', 'Database_OnNewTableContent')
Script.serveEvent('CSK_Database.OnNewStatusDataSelection', 'Database_OnNewStatusDataSelection')

Script.serveEvent("CSK_Database.OnNewStatusLoadParameterOnReboot", "Database_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_Database.OnPersistentDataModuleAvailable", "Database_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_Database.OnNewParameterName", "Database_OnNewParameterName")
Script.serveEvent("CSK_Database.OnDataLoadedOnReboot", "Database_OnDataLoadedOnReboot")

Script.serveEvent('CSK_Database.OnUserLevelOperatorActive', 'Database_OnUserLevelOperatorActive')
Script.serveEvent('CSK_Database.OnUserLevelMaintenanceActive', 'Database_OnUserLevelMaintenanceActive')
Script.serveEvent('CSK_Database.OnUserLevelServiceActive', 'Database_OnUserLevelServiceActive')
Script.serveEvent('CSK_Database.OnUserLevelAdminActive', 'Database_OnUserLevelAdminActive')

-- ************************ UI Events End **********************************

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
-- ***********************************************
--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("Database_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("Database_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("Database_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("Database_OnUserLevelAdminActive", status)
end

--- Function to get access to the database_Model object
---@param handle handle Handle of database_Model object
local function setDatabase_Model_Handle(handle)
  database_Model = handle
  if database_Model.userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)
end

--- Function to update user levels
local function updateUserLevel()
  if database_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("Database_OnUserLevelAdminActive", true)
    Script.notifyEvent("Database_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("Database_OnUserLevelServiceActive", true)
    Script.notifyEvent("Database_OnUserLevelOperatorActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrDatabase()

  updateUserLevel()

  Script.notifyEvent("Database_OnNewStatusActiveDatabaseName", database_Model.currentActiveDatabase)

  Script.notifyEvent("Database_OnNewStatusColumnList", database_Model.databaseColumnsInfo)
  Script.notifyEvent("Database_OnNewStatusRegisteredEvent", database_Model.parameters.registeredEvent)

  Script.notifyEvent("Database_OnNewStatusDatabaseName", database_Model.parameters.nameOfDatabase)
  Script.notifyEvent("Database_OnNewStatusDatabaseLocation", database_Model.parameters.locationOfDatabase)

  Script.notifyEvent("Database_OnNewStatusQuery", database_Model.query)

  local jsonString = database_Model.helperFuncs.createQueryJsonList(database_Model.databaseColumns, database_Model.queryContent)
  Script.notifyEvent('Database_OnNewTableContent', jsonString)

  Script.notifyEvent("Database_OnNewStatusLoadParameterOnReboot", database_Model.parameterLoadOnReboot)
  Script.notifyEvent("Database_OnPersistentDataModuleAvailable", database_Model.persistentModuleAvailable)
  Script.notifyEvent("Database_OnNewParameterName", database_Model.parametersName)

end
Timer.register(tmrDatabase, "OnExpired", handleOnExpiredTmrDatabase)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrDatabase:start()
  return ''
end
Script.serveFunction("CSK_Database.pageCalled", pageCalled)

local function setDatabaseName(name)
  database_Model.parameters.nameOfDatabase = name
  database_Model.query = 'select * from ' .. name
  handleOnExpiredTmrDatabase()
end
Script.serveFunction('CSK_Database.setDatabaseName', setDatabaseName)

local function setDatabaseLocation(path)
  database_Model.parameters.locationOfDatabase = path
  database_Model.parameters.databasePath = database_Model.parameters.locationOfDatabase .. database_Model.parameters.nameOfDatabase .. '.db'
end
Script.serveFunction('CSK_Database.setDatabaseLocation', setDatabaseLocation)

local function createDatabase()
  local suc = database_Model.createDatabase()
  database_Model.queryContent = {}
  handleOnExpiredTmrDatabase()
  return suc
end
Script.serveFunction('CSK_Database.createDatabase', createDatabase)

local function loadDatabase()
  if File.exists(database_Model.parameters.locationOfDatabase .. database_Model.parameters.nameOfDatabase .. ".db") then
    database_Model.parameters.databasePath = database_Model.parameters.locationOfDatabase .. database_Model.parameters.nameOfDatabase .. '.db'
    database_Model.loadDatabase()
    database_Model.queryContent = {}
    database_Model.query = 'select * from ' .. database_Model.parameters.nameOfDatabase
    handleOnExpiredTmrDatabase()
  else
    _G.logger:info(nameOfModule .. ": Database does not exist")
  end
end
Script.serveFunction('CSK_Database.loadDatabase', loadDatabase)

local function setQuery(query)
  _G.logger:fine(nameOfModule .. ": Set query to: " .. query)
  database_Model.query = query
end
Script.serveFunction('CSK_Database.setQuery', setQuery)

--- Function to get the current selected entry
---@param selection string Full text of selection
---@param pattern string Pattern to search for
local function setSelection(selection, pattern)
  local selected
  if selection == "" then
    selected = ''
  else
    local _, pos = string.find(selection, pattern)
    if pos == nil then
      _G.logger:fine(nameOfModule .. ": Did not find selection")
      selected = ''
    else
      pos = tonumber(pos)
      local endPos = string.find(selection, '"', pos+1)
      selected = string.sub(selection, pos+1, endPos-1)

      if selected == nil then
        selected = ''
      end
    end
  end
  return selected
end

local function selectEntryViaUI(selection)
  database_Model.selection = selection
  Script.notifyEvent('Database_OnNewStatusDataSelection', selection)
end
Script.serveFunction('CSK_Database.selectEntryViaUI', selectEntryViaUI)

local function callQuery(query)
  if query then
    database_Model.queryContent = database_Model.exec(query)
  else
    database_Model.queryContent = database_Model.exec(database_Model.query)
  end
  if not database_Model.queryContent then
    database_Model.queryContent = {}
  end

  local jsonString = database_Model.helperFuncs.createQueryJsonList(database_Model.databaseColumns, database_Model.queryContent)
  Script.notifyEvent('Database_OnNewTableContent', jsonString)

  return database_Model.queryContent
end
Script.serveFunction('CSK_Database.callQuery', callQuery)

local function deleteDataViaUI()
  local pos = setSelection(database_Model.selection, '"data1":"')
  if tonumber(pos) then
    callQuery("DELETE FROM " .. database_Model.parameters.nameOfDatabase .. " WHERE ID='" .. tostring(pos) .. "'")
    callQuery("select * from " .. database_Model.parameters.nameOfDatabase)
  else
    _G.logger:fine(nameOfModule .. ": No selection")
  end
end
Script.serveFunction('CSK_Database.deleteDataViaUI', deleteDataViaUI)

local function setRegisteredEvent(eventName)
  local eventExists = Script.isServedAsEvent(eventName)
  if eventExists then
    Script.deregister(database_Model.parameters.registeredEvent, database_Model.insert)
    database_Model.parameters.registeredEvent = eventName
    Script.register(eventName, database_Model.insert)
  else
    _G.logger:fine(nameOfModule .. ": Event does not exists")
  end
  handleOnExpiredTmrDatabase()
end
Script.serveFunction('CSK_Database.setRegisteredEvent', setRegisteredEvent)

local function setColumnsInfo(columnDefinition)
  database_Model.databaseColumnsInfo = columnDefinition

  Script.releaseObject(database_Model.databaseColumns)
  database_Model.databaseColumns = {}

  local tempColumn
  local startPos = 0
  local endPos = string.find(columnDefinition, ' ')
  if endPos then
    tempColumn = string.sub(columnDefinition, startPos, endPos-1)

    table.insert(database_Model.databaseColumns, tempColumn)

    while true do
      startPos = string.find(columnDefinition, ', ', endPos+1)
      if startPos then
        endPos = string.find(columnDefinition, ' ', startPos+2)
        if endPos then
          tempColumn = string.sub(columnDefinition, startPos+2, endPos-1)
          table.insert(database_Model.databaseColumns, tempColumn)
        else
          break
        end
      else
        break
      end
    end
  end
end
Script.serveFunction('CSK_Database.setColumnsInfo', setColumnsInfo)

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:fine(nameOfModule .. ": Set parameter name: " .. tostring(name))
  database_Model.parametersName = name
end
Script.serveFunction("CSK_Database.setParameterName", setParameterName)

local function sendParameters()
  if database_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(database_Model.helperFuncs.convertTable2Container(database_Model.parameters), database_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, database_Model.parametersName, database_Model.parameterLoadOnReboot)
    _G.logger:fine(nameOfModule .. ": Send Database parameters with name '" .. database_Model.parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_Database.sendParameters", sendParameters)

local function loadParameters()
  if database_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(database_Model.parametersName)
    if data then
      _G.logger:fine(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      database_Model.parameters = database_Model.helperFuncs.convertContainer2Table(data)

      if database_Model.parameters.nameOfDatabase ~= '' then
        loadDatabase()
        setRegisteredEvent(database_Model.parameters.registeredEvent)
      end

      CSK_Database.pageCalled()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_Database.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  database_Model.parameterLoadOnReboot = status
  _G.logger:fine(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_Database.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    database_Model.persistentModuleAvailable = false
  else

    local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule)

    if parameterName then
      database_Model.parametersName = parameterName
      database_Model.parameterLoadOnReboot = loadOnReboot
    end

    if database_Model.parameterLoadOnReboot then
      loadParameters()
    end
    Script.notifyEvent('Database_OnDataLoadedOnReboot')
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setDatabase_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

