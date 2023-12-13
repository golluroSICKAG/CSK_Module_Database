---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find helper functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local funcs = {}
-- Providing standard JSON functions
funcs.json = require('Data/Database/helper/Json')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Create JSON list for dynamic table
local function createQueryJsonList(columnNames, content)

  local orderedTable = {}
  local dataList = {}

  if content[1] ~= nil then
    for n in pairs(content[1]) do
      table.insert(orderedTable, n)
    end
    table.sort(orderedTable)

    if #content == 1 then
      table.insert(dataList, {data1 = 'ID'})
    elseif #content == 2 then
      table.insert(dataList, {data1 = 'ID', data2 = columnNames[1]})
    elseif #content == 3 then
      table.insert(dataList, {data1 = 'ID', data2 = columnNames[1], data3 = columnNames[2]})
    elseif #content == 4 then
      table.insert(dataList, {data1 = 'ID', data2 = columnNames[1], data3 = columnNames[2], data4 = columnNames[3]})
    elseif #content == 5 then
      table.insert(dataList, {data1 = 'ID', data2 = columnNames[1], data3 = columnNames[2], data4 = columnNames[3], data5 = columnNames[4]})
    elseif #content == 6 then
      table.insert(dataList, {data1 = 'ID', data2 = columnNames[1], data3 = columnNames[2], data4 = columnNames[3], data5 = columnNames[4], data6 = columnNames[5]})
    end

    for _, value in ipairs(orderedTable) do
      if #content == 1 then
        table.insert(dataList, {data1 = content[1][value]})
      elseif #content == 2 then
        table.insert(dataList, {data1 = content[1][value], data2 = content[2][value]})
      elseif #content == 3 then
        table.insert(dataList, {data1 = content[1][value], data2 = content[2][value], data3 = content[3][value]})
      elseif #content == 4 then
        table.insert(dataList, {data1 = content[1][value], data2 = content[2][value], data3 = content[3][value], data4 = content[4][value]})
      elseif #content == 5 then
        table.insert(dataList, {data1 = content[1][value], data2 = content[2][value], data3 = content[3][value], data4 = content[4][value], data5 = content[5][value]})
      elseif #content == 6 then
        table.insert(dataList, {data1 = content[1][value], data2 = content[2][value], data3 = content[3][value], data4 = content[4][value], data5 = content[5][value], data6 = content[6][value]})
      end
    end
  end

  if #dataList == 0 then
    if #content == 1 then
      dataList = {{data1 = '-'},}
    elseif #content == 2 then
      dataList = {{data1 = '-', data2 = '-'},}
    elseif #content == 3 then
      dataList = {{data1 = '-', data2 = '-', data3 = '-'},}
    elseif #content == 4 then
      dataList = {{data1 = '-', data2 = '-', data3 = '-', data4 = '-'},}
    elseif #content == 5 then
      dataList = {{data1 = '-', data2 = '-', data3 = '-', data4 = '-', data5 = '-'},}
    elseif #content == 6 then
      dataList = {{data1 = '-', data2 = '-', data3 = '-', data4 = '-', data5 = '-', data6 = '-'},}
    else
      dataList = {{data1 = '-', data2 = '-', data3 = '-', data4 = '-', data5 = '-', data6 = '-'},}
    end
  end

  local jsonstring = funcs.json.encode(dataList)
  return jsonstring
end
funcs.createQueryJsonList = createQueryJsonList

--- Function to create a list with numbers
---@param size int Size of the list
---@return string list List of numbers
local function createStringListBySize(size)
  local list = "["
  if size >= 1 then
    list = list .. '"' .. tostring(1) .. '"'
  end
  if size >= 2 then
    for i=2, size do
      list = list .. ', ' .. '"' .. tostring(i) .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySize = createStringListBySize

--- Function to convert a table into a Container object
---@param content auto[] Lua Table to convert to Container
---@return Container cont Created Container
local function convertTable2Container(content)
  local cont = Container.create()
  for key, value in pairs(content) do
    if type(value) == 'table' then
      cont:add(key, convertTable2Container(value), nil)
    else
      cont:add(key, value, nil)
    end
  end
  return cont
end
funcs.convertTable2Container = convertTable2Container

--- Function to convert a Container into a table
---@param cont Container Container to convert to Lua table
---@return auto[] data Created Lua table
local function convertContainer2Table(cont)
  local data = {}
  local containerList = Container.list(cont)
  local containerCheck = false
  if tonumber(containerList[1]) then
    containerCheck = true
  end
  for i=1, #containerList do

    local subContainer

    if containerCheck then
      subContainer = Container.get(cont, tostring(i) .. '.00')
    else
      subContainer = Container.get(cont, containerList[i])
    end
    if type(subContainer) == 'userdata' then
      if Object.getType(subContainer) == "Container" then

        if containerCheck then
          table.insert(data, convertContainer2Table(subContainer))
        else
          data[containerList[i]] = convertContainer2Table(subContainer)
        end

      else
        if containerCheck then
          table.insert(data, subContainer)
        else
          data[containerList[i]] = subContainer
        end
      end
    else
      if containerCheck then
        table.insert(data, subContainer)
      else
        data[containerList[i]] = subContainer
      end
    end
  end
  return data
end
funcs.convertContainer2Table = convertContainer2Table

--- Function to get content list out of table
---@param data string[] Table with data entries
---@return string sortedTable Sorted entries as string, internally seperated by ','
local function createContentList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return table.concat(sortedTable, ',')
end
funcs.createContentList = createContentList

--- Function to get content list as JSON string
---@param data string[] Table with data entries
---@return string sortedTable Sorted entries as JSON string
local function createJsonList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return funcs.json.encode(sortedTable)
end
funcs.createJsonList = createJsonList

--- Function to create a list from table
---@param content string[] Table with data entries
---@return string list String list
local function createStringListBySimpleTable(content)
  local list = "["
  if #content >= 1 then
    list = list .. '"' .. content[1] .. '"'
  end
  if #content >= 2 then
    for i=2, #content do
      list = list .. ', ' .. '"' .. content[i] .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySimpleTable = createStringListBySimpleTable

---@param pos int Position to start to search for a slash
---@param path string Full file path to search for subfolders
local function createRecursiveFolder(pos, path)
  local foundPos = string.find(path, '/', pos)
  if foundPos then
    local found2ndPos = string.find(path, '/', foundPos+1)
    if found2ndPos and found2ndPos ~= #path then
      local folderToCheck = string.sub(path, 1, found2ndPos)
      local folderExists = File.isdir(folderToCheck)
      if not folderExists then
        local suc = File.mkdir(folderToCheck)
      end
      return createRecursiveFolder(foundPos+1, path)
    else
      local folderExists = File.isdir(path)
      if folderExists then
        --_G.logger:info(nameOfModule .. ': Folder: "' .. path .. '" already exists.')
      else
        local suc = File.mkdir(path)
        return
      end
    end
  else
    return
  end
end
funcs.createRecursiveFolder = createRecursiveFolder

local function createFolder(path)
  if string.sub(path, 1, 1) == '/' then
    createRecursiveFolder(1, path)
  else
    createRecursiveFolder(1, '/' .. path)
  end
end
funcs.createFolder = createFolder

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************