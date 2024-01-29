local Decompile = {
  WaitDecompile = false,
  getupvalues = false,
  getconstants = false,
  setclipboard = true
}

local Variaveis = {}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function Wait()
  if Decompile.WaitDecompile then
    task.wait()
  end
end

local function GetParams(func)
  local Vals = {}
  for ind = 1, getinfo(func).numparams do
    table.insert(Vals, "Val" .. tostring(ind))
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

function Decompile:Type(part, Lines)Wait()
  local type = typeof(part)
  local Script = "", ""
  
  if type == "table" then
    Script, IsFirst = Script .. "{", false
    
    for a,b in pairs(part) do
      if IsFirst then Script = Script .. ","end
      Script = Script .. "\n"
      if tonumber(a) then
        Script = Script .. Lines .. "  " .. '["' .. a .. '"] = '
      else
        Script = Script .. Lines .. "  " .. tostring(a).. " = "
      end
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
          if b == "Workspace" then
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
        elseif b:find(" ")
        or b:find("0")
        or b:find("1")
        or b:find("2")
        or b:find("3")
        or b:find("4")
        or b:find("5")
        or b:find("6")
        or b:find("7")
        or b:find("8")
        or b:find("9")
        or b:find("_")
        or b:find("-")
        or b:find("+")
        or b:find("/")
        or b:find("|") then
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
  elseif type == "Vector3" then
    Script = Script .. "Vector3.new(" .. tostring(part) .. ")"
  elseif type == "Color3" then
    Script = Script .. "Color3.fromRGB(" .. GetColorRGB(part) .. ")"
  elseif type == "CFrame" then
    Script = Script .. "CFrame.new(" .. tostring(part) .. ")"
  elseif type == "BrickColor" then
    Script = Script .. 'BrickColor.new("' .. tostring(part) .. '")'
  elseif type == "Vector2" then
    Script = Script .. "Vector2.new(" .. tostring(part) .. ")"
  elseif type == "UDim2" then
    Script = Script .. "UDim2.new(" .. tostring(part) .. ")"
  elseif type == "UDim" then
    Script = Script .. "UDim.new(" .. tostring(part) .. ")"
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
  Variaveis = {}
  local function GetClass(partGet)
    if typeof(partGet) == "Instance" then
      if partGet:IsA("LocalScript") then
        return getsenv(partGet)
      elseif partGet:IsA("ModuleScript") then
        if typeof(require(partGet)) == "function" then
          return getupvalues(require(partGet))
        end
        return require(partGet)
      end
    end
    return partGet
  end
  
  local Script, Lines, IsFirst = typeof(part) == "Instance" and "local Script = " .. Decompile:Type(part) .. "\n\n" or "", "  "
  Script = Script .. "local Decompile = {"
  
  if typeof(GetClass(part)) == "table" then
    for a,b in pairs(GetClass(part)) do
      if IsFirst then Script = Script .. ","end
      Script = Script .. "\n"
      if tonumber(a) then
        Script = Script .. Lines .. '["' .. a .. '"] = '
      else
        Script = Script .. Lines .. tostring(a) .. " = "
      end
      Script = Script .. Decompile:Type(b, Lines)
      IsFirst = true
    end
  else
    Script = Script .. "\n" .. Lines .. "[\"1\"] = " .. Decompile:Type(GetClass(part), Lines)
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
