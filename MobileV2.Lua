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
local upvalues = {}
local checkuv = {}

local function sortav(newt)
  table.sort(newt, function(old, new)
    return (old:len() > new:len())
  end)
end

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

local function iupvals(t)
  local vals = {}
  for i,v in pairs(t) do
    local f = table.find(upvalues, v)
    if not f then
      table.insert(vals, "v" .. tostring(i))
      table.insert(upvalues, v)
    else
      table.insert(vals, "v" .. tostring(f))
    end
  end
  return "{" .. table.concat(vals, ", ") .. "}"
end

local function GetIndex(Index)
  if tostring(Index):len() < 1 then
    return "[\"" .. tostring(Index) .. "\"] = "
  elseif tonumber(Index) then
    return "[" .. tostring(Index) .. "] = "
  elseif typeof(Index) == "Instance" then
    if Index and Index == game then
      return "[game] = "
    else
      return "[game." .. Index:GetFullName() .. "] = "
    end
  elseif IsInvalid(tostring(Index)) then
    return "[\"" .. tostring(Index) .. "\"] = "
  end
  return tostring(Index) .. " = "
end

local function GetService(part)
  if part.Name == "Workspace" then return "workspace" end
  local Class = (part.ClassName:gsub(" ", ""))
  
  Variaveis[Class] = false
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
        Variaveis[Service] = false
      end
      Name = Service
    else
      if val == Player.Name and Service == "workspace" then
        Variaveis["Players"] = false
        Variaveis["Player"] = "Players.LocalPlayer"
        Names = {"Player.Character"}
      elseif val == Player.Name and LastName == "Players" then
        Variaveis["Players"] = false
        Variaveis["Player"] = "Players.LocalPlayer"
        Names = {"Player"}
      elseif val == "Camera" and LastName == "workspace" then
        Variaveis["CurrentCamera"] = "workspace.CurrentCamera"
        Names = {"CurrentCamera"}
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

local function gettcount(newt)
  local vals = {}
  for ind,val in pairs(newt) do
    table.insert(vals, val)
  end
  return #vals
end

local function CheckFind(Find, Val)
  return typeof(Find) == typeof(Val) and Find == Val or type(Val) == "table" or type(Val) == "function"
end

-- local DV = {}
function Decompile:GetType(part, Lines, Find)
  local type = typeof(part)
  if type == "table" then
    -- if Decompile.antiloop then if table.find(DV, part) then return "{} --[[ Anti Loop ]]" end table.insert(DV, part) end
    
    if Decompile.antiloop then
      if #part < 1 and gettcount(part) > 0 then return "{} --[[ Possible Loop ]]" end
    end
    
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
    local name = getinfo(part).name
    local fname = name and " --[[ " .. name .. " ]]" or ""
    local Script = "function(" .. GetParams(part) .. ")" .. fname
    local UpVal, Cons
    if Decompile.getupvalues then
      pcall(function()
        local upvals = getupvalues(part)
        if #upvals > 0 then
          local ind = iupvals(upvals)
          Script = Script .. "\n  " .. Lines .. "local upvalues = " .. ind .. "\n"
          UpVal = true
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
    elseif Script == tostring(Player.UserId) then
      return Script .. " --[[ UserId ]]"
    end
    return Script
  elseif type == "boolean" then
    return tostring(part)
  elseif type == "string" then
    if part:find("\n") then
      return "[[" .. part .. "]]"
    elseif part:find("\"") then
      return "'" .. part .. "'"
    end
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
  DecInfo = ({Script = part, type = typeof(part)})
  
  local Method
  Variaveis, upvalues, checkuv = {}, {}, {}
  if typeof(part) == "Instance" then
    if part.ClassName == "ModuleScript" then
      part = require(part)
      Method = "require"
    elseif part.ClassName == "LocalScript" then
      part = getsenv(part)
      Method = "getsenv"
    else
      error("invalid argument #1 to 'new' (Expected ModuleScript/LocalScript, got " .. type(part) .. ")")
    end
  elseif type(part) == "table" then
    part = part
  elseif type(part) == "function" then
    part = part
  else
    -- error("invalid argument #1 to 'new' (Expected table/function/Instance, got " .. type(part) .. ")")
  end
  
  local Script = "local Decompile = "
  local Lines, First = "  "
  
  local garbage, info = {}
  
  if Decompile.getgc and DecInfo.type == "Instance" then
    for _,val in (getgc(true)) do
      if type(val) == "function" then
        local Script = tostring(DecInfo.Script:GetFullName())
        local info = getinfo(val)
        local source, short_src = info.source, info.short_src
        if source and source == "=" .. Script or short_src and short_src == Script then
          table.insert(garbage, val)
        end
      end
    end
  end
  if type(part) == "table" then
    Script = Script .. "{"
    
    local Vals = {}
    for Ind,Val in (part) do
      if not Find or CheckFind(Find, Val) then
        table.insert(Vals, Lines .. GetIndex(Ind) .. Decompile:GetType(Val, Lines, Find))
      end
    end
    Script = Script .. "\n" .. table.concat((Vals), ",\n")
    Script = Script .. "\n}"
  else
    Script = Script .. Decompile:GetType(part, "", Find)
  end
  
  if #garbage > 0 then
    Script = Script .. "\n\nlocal garbage = " .. Decompile:GetType(garbage, "", Find)
  end
  
  local NewVar, NewVar1 = {}, {}
  if DecInfo.type == "Instance" then
    Variaveis["script"] = GetFullName(DecInfo.Script)
  end
  for index,value in pairs(Variaveis) do
    if value then
      table.insert(NewVar1, "local " .. index .. " = " .. value)
    else
      table.insert(NewVar, "local " .. index .. " = game:GetService(\"" .. index .. "\")")
    end
  end
  local newuv = {}
  for index,value in pairs(upvalues) do
    local New = "local v" .. tostring(index) .. " = " .. Decompile:GetType(value, "", Find)
    table.insert(newuv, New)
  end
  
  if #newuv > 0 then
    newuv = table.concat(newuv, "\n") .. "\n\n"
    Script = "-- upvalues :\n" .. newuv .. Script
  end
  if #NewVar1 > 0 then
    NewVar1 = table.concat(NewVar1, "\n") .. "\n\n"
    Script = NewVar1 .. Script
  end
  if #NewVar > 0 then
    sortav(NewVar)
    NewVar = table.concat(NewVar, "\n") .. "\n\n"
    Script = NewVar .. Script
  end
  
  if Decompile.setclipboard then
    setclipboard(Script)
  end
  return Script
end

return Decompile
