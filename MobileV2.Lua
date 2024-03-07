local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Decompile = {
  setclipboard = true,
  getupvalues = false,
  getconstants = false,
  getgc = false,
  antiloop = false
}

local DecInfo = {}

local Variaveis = {}

local function IsInvalid(str)
  if str:find(" ")
  or str:find("0")
  or str:find("1")
  or str:find("2")
  or str:find("3")
  or str:find("4")
  or str:find("5")
  or str:find("6")
  or str:find("7")
  or str:find("8")
  or str:find("9")
  or str:find("-")
  or str:find("+")
  or str:find("/")
  or str:find("|") then
    return true
  end
end

local function GetParams(func)
  local Info, Vals = getinfo(func), {}
  for ind = 1, Info.numparams do
    table.insert(Vals, "Val" .. tostring(ind))
  end
  if Info.is_vararg > 0 then
    table.insert(Vals, "...")
  end
  return table.concat(Vals, ", ")
end

local function GetColorRGB(Color)
  local R, G, B
  local split = tostring(Color):gsub(" ", ""):split(",")
  R = math.floor(tonumber(split[1]) * 255)
  G = math.floor(tonumber(split[2]) * 255)
  B = math.floor(tonumber(split[3]) * 255)
  return (tostring(R) .. ", " .. tostring(G) .. ", " .. tostring(B))
end

local function GetIndex(Index)
  if tostring(Index):len() < 1 then
    return "[\"" .. tostring(Index) .. "\"] = "
  elseif tonumber(Index) then
    return "[" .. tostring(Index) .. "] = "
  elseif IsInvalid(tostring(Index)) then
    return "[\"" .. tostring(Index) .. "\"] = "
  else
    return tostring(Index) .. " = "
  end
end

local function GetService(part)
  if part.Name == "Workspace" then return "workspace" end
  local Class = (part.ClassName:gsub(" ", ""))
  
  table.insert(Variaveis, Class)
  return Class
end

local function GetFullName(part)
  if part and part == game then return "game --[[ DataModel ]]" end
  
  local Parent = part.Parent
  
  if Parent and Parent == game then GetService(part) end
  if not part or not Parent then return part.Name .. " --[[ Nil Instance ]]" end
  
  local FullName = part:GetFullName():split(".")
  
  local Names, LastName, Service = {}
  
  for _,val in pairs(FullName) do
    local Name
    if not Service then
      if val == "Workspace" then
        Service = "workspace"
      else
        Service = val:gsub(" ", "")
      end
      Name = Service
    else
      if val == Player.Name and Service == "workspace" then
        Names = {"Players.LocalPlayer.Character"}
        table.insert(Variaveis, "Players")
      elseif val == Player.Name and LastName == "Players" then
        Name = ".LocalPlayer"
      elseif val == "Camera" and LastName == "workspace" then
        Name = ".CurrentCamera"
      else
        if IsInvalid(val) then
          Name = "[\"" .. val .. "\"]"
        else
          Name = "." .. val
        end
      end
    end
    if Name then
      table.insert(Names, Name)
      LastName = Name
    end
  end
  return table.concat(Names)
end

local function CheckFind(Find, Val)
  return typeof(Find) == typeof(Val) and Find == Val or type(Val) == "table" or type(Val) == "function"
end

local DupVals = {}

function Decompile:GetType(part, Lines, Find)
  local type = typeof(part)
  if type == "table" then
    if Decompile.antiloop and table.find(DupVals, part) then return "{} --[[ Anti Loop < Table > ]]" end
    table.insert(DupVals, part)
    local Vals = {}
    local Script = "{\n"
    for Ind,Val in pairs(part) do
      if not Find or Find and CheckFind(Find, Val) then
        table.insert(Vals, "  " .. Lines .. GetIndex(Ind) .. Decompile:GetType(Val, "  " .. Lines, Find))
      end
    end
    if #Vals < 1 then return "{}" end
    Script = Script .. table.concat((Vals), ",\n")
    return Script .. "\n" .. Lines .. "}"
  elseif type == "function" then
    if Decompile.antiloop and table.find(DupVals, part) then return "function(" .. GetParams(part) .. ")end --[[ Anti Loop < Function > ]]"end
    table.insert(DupVals, part)
    local Script = "function(" .. GetParams(part) .. ")"
    local UpVal, Cons
    if Decompile.getupvalues then
      pcall(function()
        local upvals = getupvalues(part)
        if #upvals > 0 then
          UpVal = true
          Script = Script .. "\n  " .. Lines .. "local upvalues = " .. Decompile:GetType(upvals, Lines .. "  ", Find) .. "\n"
        end
      end)
    end
    if Decompile.getconstants then
      pcall(function()
        local cons = getconstants(part)
        if #cons > 0 then
          Cons = true
          if not UpVal then
            Script = Script .. "\n"
          end
          Script = Script .. Lines .. "  local constants = " .. Decompile:GetType(cons, Lines .. "  ", Find) .. "\n"
        end
      end)
    end
    local space = UpVal and Lines or Cons and Lines or ""
    return Script .. space .. "end"
  elseif type == "Instance" then
    return GetFullName(part)
  elseif type == "number" then
    local Script = tostring(part)
    if Script == "inf" then
      return "math.huge"
    end
    return Script
  elseif type == "boolean" then
    return tostring(part)
  elseif type == "string" then
    return "\"" .. part .. "\""
  elseif type == "CFrame" then
    return "CFrame.new(" .. tostring(part) .. ")"
  elseif type == "Color3" then
    return "Color3.fromRGB(" .. GetColorRGB(part) .. ")"
  elseif type == "BrickColor" then
    return "BrickColor.new(\"" .. tostring(part) .. "\")"
  elseif type == "Vector2" then
    return "Vector2.new(" .. tostring(part) .. ")"
  elseif type == "Vector3" then
    return "Vector3.new(" .. tostring(part) .. ")"
  elseif type == "UDim" then
    return "UDim.new(" .. tostring(part) .. ")"
  elseif type == "UDim2" then
    return "UDim2.new(" .. tostring(part) .. ")"
  elseif type == "TweenInfo" then
    return "TweenInfo.new(" .. tostring(part) .. ")"
  elseif type == "Axes" then
    return "Axes.new(" .. tostring(part) .. ")"
  end
  return tostring(part)
end

function Decompile.new(Configs)
  local part = type(Configs) == "table" and Configs.Part or Configs
  local Find = type(Configs) == "table" and Configs.Find or nil
  DecInfo = {
    part = part,
    type = typeof(part)
  }
  
  local Method
  Variaveis = {}
  if typeof(part) == "Instance" then
    if part.ClassName == "ModuleScript" then
      part = require(part)
      Method = "require"
      if type(part) == "function" then
        part = getupvalues(part)
        Method = Method .. ", getupvalues"
      end
    elseif part.ClassName == "LocalScript" then
      part = getsenv(part)
      Method = "getsenv"
    else
      error("invalid argument #1 to 'new' (Expected ModuleScript/LocalScript)")
    end
  elseif type(part) == "table" then
    part = part
  elseif type(part) == "function" then
    part = {part}
  else
    error("invalid argument #1 to 'new' (Expected Table/Instance)")
  end
  
  local Script = "local Decompile = {"
  local Lines, First = "  "
  
  local Vals = {}
  if Decompile.getgc and typeof(DecInfo.part) == "Instance" then
    local garbage = getgc(true)
    for _,val in (garbage) do
      if type(val) == "function" then
        local source = getinfo(val).source
        if source and source == DecInfo.part then
          table.insert(part, val)
        end
      end
    end
  end
  for Ind,Val in (part) do
    if not Find or CheckFind(Find, Val) then
      table.insert(Vals, Lines .. GetIndex(Ind) .. Decompile:GetType(Val, Lines, Find))
    end
  end
  Script = Script .. "\n" .. table.concat((Vals), ",\n")
  Script = Script .. "\n}"
  
  local NewVar = {}
  local VarInp = {}
  for _,Val in (Variaveis) do
    if not table.find(VarInp, Val) then
      table.insert(NewVar, "local " .. Val .. " = game:GetService(\"" .. Val .. "\")")
      table.insert(VarInp, Val)
    end
  end
  if #NewVar > 0 then
    NewVar = table.concat(NewVar, "\n") .. "\n\n"
    Script = NewVar .. Script
  end
  
  if Decompile.setclipboard then
    setclipboard(Script)
  end
  return Script
end

return Decompile
