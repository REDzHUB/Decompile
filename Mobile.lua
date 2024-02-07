local Decompile, Libraries = {
  WaitDecompile = false,
  getupvalues = false,
  getconstants = false,
  setclipboard = true
}, {
  "bit32",
  "buffer",
  "coroutine",
  "debug",
  "math",
  "os",
  "string",
  "table",
  "task",
  "utf8"
}

local Variaveis = {}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function Wait()
  if Decompile.WaitDecompile then
    task.wait()
  end
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

local function GetIndex(Index)
  if tostring(Index):len() < 1 then
    return "[\"" .. tostring(Index) .. "\"]"
  elseif tonumber(Index) then
    return "[" .. tostring(Index) .. "]"
  elseif IsInvalid(tostring(Index)) then
    return "[\"" .. tostring(Index) .. "\"]"
  else
    return tostring(Index)
  end
end

function Decompile:Type(part, Lines)Wait()
  local type = typeof(part)
  local Script = "", ""
  
  if type == "boolean" then
    Script = Script .. tostring(part)
  elseif type == "nil" then
    Script = Script .. "nil"
  elseif type == "table" then
    Script, IsFirst = Script .. "{", false
    
    for a,b in pairs(part) do
      if IsFirst then Script = Script .. ","end
      Script = Script .. "\n"
      Script = Script .. Lines .. "  " .. GetIndex(a) .. " = "
      Script = Script .. Decompile:Type(b, Lines .. "  ")
      IsFirst = true
    end
    
    local An = IsFirst and "\n" .. Lines or ""
    Script = Script .. An .. "}"
  elseif type == "string" then
    Script = Script .. '"' .. part .. '"'
  elseif type == "Instance" then
    local first, firstName, Variavel2 = false, "", ""
    local Separator = part:GetFullName():split(".")
    for a,b in pairs(Separator) do
      if not first then
        if not table.find(Variaveis, b) then
          b = b:gsub(" ", "")
          if not game:FindFirstChild(b) then
            return b .. " --[[ nil Instance ]]"
          elseif b == "Workspace" then
            firstName = "workspace"
          else
            firstName = b
            table.insert(Variaveis, b)
          end
        else
          firstName = b
        end
      else
        if b == Player.Name and firstName == "Players" then
          Variavel2 = Variavel2 .. ".LocalPlayer"
        elseif b == Player.Name and firstName == "workspace" then
          table.insert(Variaveis, "Players")
          Variavel2, firstName = "Players.LocalPlayer.Character", ""
        elseif b == "Camera" and firstName == "workspace" then
          Variavel2 = Variavel2 .. ".CurrentCamera"
        elseif IsInvalid(b) then
          Variavel2 = Variavel2 .. '["' .. b .. '"]'
        else
          Variavel2 = Variavel2 .. "." .. b
        end
      end
      first = true
    end
    Script = Script .. firstName .. Variavel2
  elseif type == "function" then
    Script = Script .. "function(" .. GetParams(part) .. ")"
    local HaveVal, constants, upvalues = false, "", ""
    
    if Decompile.getupvalues then
      local uptable = getupvalues and getupvalues(part)
      
      if uptable and typeof(uptable) == "table" and #uptable > 0 then
        upvalues, HaveVal = upvalues .. "\n" .. Lines .. "  local upvalues = {", true
        local FirstVal
        for ind, val in pairs(uptable) do
          if FirstVal then upvalues = upvalues .. ","end
          upvalues = upvalues .. "\n" .. Lines .. "    [" .. tostring(ind) .. "] = " .. Decompile:Type(val, Lines .. "    ")
          FirstVal = true
        end
        upvalues = upvalues .. "\n" .. Lines .. "  }"
      end
    end
    if Decompile.getconstants then
      local uptable = getconstants and getconstants(part)
      
      if uptable and typeof(uptable) == "table" and #uptable > 0 then
        constants, HaveVal = constants .. "\n" .. Lines .. "  local constants = {", true
        local FirstVal
        for ind, val in pairs(uptable) do
          if FirstVal then constants = constants .. ","end
          constants = constants .. "\n" .. Lines .. "    [" .. tostring(ind) .. "] = " .. Decompile:Type(val, Lines .. "    ")
          FirstVal = true
        end
        constants = constants .. "\n" .. Lines .. "  }"
      end
    end
    
    local endType = HaveVal and "\n" .. Lines .. "end" or "end"
    Script = Script .. upvalues .. constants .. endType
  elseif type == "CFrame" then
    Script = Script .. "CFrame.new(" .. tostring(part) .. ")"
  elseif type == "Color3" then
    Script = Script .. "Color3.fromRGB(" .. GetColorRGB(part) .. ")"
  elseif type == "BrickColor" then
    Script = Script .. 'BrickColor.new("' .. tostring(part) .. '")'
  elseif type == "Vector2" then
    Script = Script .. "Vector2.new(" .. tostring(part) .. ")"
  elseif type == "Vector3" then
    Script = Script .. "Vector3.new(" .. tostring(part) .. ")"
  elseif type == "UDim" then
    Script = Script .. "UDim.new(" .. tostring(part) .. ")"
  elseif type == "UDim2" then
    Script = Script .. "UDim2.new(" .. tostring(part) .. ")"
  elseif type == "TweenInfo" then
    Script = Script .. "TweenInfo.new(" .. tostring(part) .. ")"
  elseif type == "Axes" then
    Script = Script .. "Axes.new(" .. tostring(part) .. ")"
  else
    if tostring(part):find("inf") then
      Script = Script .. "math.huge"
    else
      Script = Script .. tostring(part)
    end
  end
  return Script
end

function Decompile.new(part)
  local Metodo;Variaveis = {}
  local function GetClass(partGet)
    if typeof(partGet) == "Instance" then
      if partGet:IsA("LocalScript") then
        Metodo = "getsenv"
        return getsenv(partGet)
      elseif partGet:IsA("ModuleScript") then
        local Script = require(partGet)
        Metodo = "require"
        if typeof(Script) == "function" then
          Metodo = Metodo .. ", getupvalues"
          return getupvalues(Script)
        end
        return Script
      end
    end
    return partGet
  end
  
  local Script, Lines, IsFirst = typeof(part) == "Instance" and "%slocal Script = " .. Decompile:Type(part) .. "\n\n" or "", "  "
  Script = Script .. "local Decompile = {"
  
  local PartClass = GetClass(part)
  if typeof(PartClass) == "table" then
    for a,b in pairs(PartClass) do
      if IsFirst then Script = Script .. ","end
      Script = Script .. "\n"
      Script = Script .. Lines .. GetIndex(a) .. ' = '
      Script = Script .. Decompile:Type(b, Lines)
      IsFirst = true
    end
  else
    Script = Script .. "\n" .. Lines .. "[\"1\"] = " .. Decompile:Type(PartClass, Lines)
  end
  
  if Metodo then
    Script = Script:format("local Method = " .. Metodo .. "\n")
  else
    Script = Script:format("")
  end
  
  local Var, list = "", {}
  table.foreach(Variaveis, function(_,Val)
    if table.find(list, Val) then return end
    Var = Var .. "local " .. Val .. "\ = game:GetService(\"" .. Val .. "\")\n"
    table.insert(list, Val)
  end)
  
  if Decompile.setclipboard then
    setclipboard(Var .. "\n" .. Script .. "\n}")
  end
  return (Var .. "\n" .. Script .. "\n}")
end

return Decompile
