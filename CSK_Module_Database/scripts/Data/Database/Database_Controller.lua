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

-- Script.serveEvent("CSK_Database.OnNewEvent", "Database_OnNewEvent")
Script.serveEvent("CSK_Database.OnNewStatusLoadParameterOnReboot", "Database_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_Database.OnPersistentDataModuleAvailable", "Database_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_Database.OnNewParameterName", "Database_OnNewParameterName")
Script.serveEvent("CSK_Database.OnDataLoadedOnReboot", "Database_OnDataLoadedOnReboot")

Script.serveEvent('CSK_Database.OnUserLevelOperatorActive', 'Database_OnUserLevelOperatorActive')
Script.serveEvent('CSK_Database.OnUserLevelMaintenanceActive', 'Database_OnUserLevelMaintenanceActive')
Script.serveEvent('CSK_Database.OnUserLevelServiceActive', 'Database_OnUserLevelServiceActive')
Script.serveEvent('CSK_Database.OnUserLevelAdminActive', 'Database_OnUserLevelAdminActive')

-- ...

-- ************************ UI Events End **********************************

--[[
--- Some internal code docu for local used function
local function functionName()
  -- Do something

end
]]

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

  -- Script.notifyEvent("Database_OnNewEvent", false)

  Script.notifyEvent("Database_OnNewStatusLoadParameterOnReboot", database_Model.parameterLoadOnReboot)
  Script.notifyEvent("Database_OnPersistentDataModuleAvailable", database_Model.persistentModuleAvailable)
  Script.notifyEvent("Database_OnNewParameterName", database_Model.parametersName)
  -- ...
end
Timer.register(tmrDatabase, "OnExpired", handleOnExpiredTmrDatabase)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrDatabase:start()
  return ''
end
Script.serveFunction("CSK_Database.pageCalled", pageCalled)

--[[
local function setSomething(value)
  _G.logger:info(nameOfModule .. ": Set new value = " .. value)
  database_Model.varA = value
end
Script.serveFunction("CSK_Database.setSomething", setSomething)
]]

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:info(nameOfModule .. ": Set parameter name: " .. tostring(name))
  database_Model.parametersName = name
end
Script.serveFunction("CSK_Database.setParameterName", setParameterName)

local function sendParameters()
  if database_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(database_Model.helperFuncs.convertTable2Container(database_Model.parameters), database_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, database_Model.parametersName, database_Model.parameterLoadOnReboot)
    _G.logger:info(nameOfModule .. ": Send Database parameters with name '" .. database_Model.parametersName .. "' to CSK_PersistentData module.")
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
      _G.logger:info(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      database_Model.parameters = database_Model.helperFuncs.convertContainer2Table(data)
      -- If something needs to be configured/activated with new loaded data, place this here:
      -- ...
      -- ...

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
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
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

