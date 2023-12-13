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

-- Optionally check if specific API was loaded via
--[[
if _G.availableAPIs.specific then
-- ... doSomething ...
end
]]

--[[
-- Create parameters / instances for this module
database_Model.object = Image.create() -- Use any AppEngine CROWN
database_Model.counter = 1 -- Short docu of variable
database_Model.varA = 'value' -- Short docu of variable
--...
]]

-- Parameters to be saved permanently if wanted
database_Model.parameters = {}
--database_Model.parameters.paramA = 'paramA' -- Short docu of variable
--database_Model.parameters.paramB = 123 -- Short docu of variable
--...

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--[[
-- Some internal code docu for local used function to do something
---@param content auto Some info text if function is not already served
local function doSomething(content)
  _G.logger:info(nameOfModule .. ": Do something")
  database_Model.counter = database_Model.counter + 1
end
database_Model.doSomething = doSomething
]]

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************

return database_Model
