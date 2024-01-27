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

function Decompile:Type(part, Lines)
  local type = typeof(part)
  local Script = "", ""
  
  if type == "table" then
    Script, IsFirst = Script .. "{"
    
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
    
    Script = Script .. "\n" .. Lines .. "}"
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
          Variavel2 = Variavel2 .. "[Players.LocalPlayer.Name]"
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
    Script = Script .. "function()"
    if Decompile.getupvalues then
      local upvalue, constant
      pcall(function()
        if getupvalues and #getupvalues(part) >= 0 then
          for a,b in pairs(getupvalues(part)) do Wait()
            
            if not upvalue then Script = Script .. "\n" .. Lines .. "  local upvalues = {\n" .. Lines .. "    "
            else Script = Script .. ",\n" .. Lines .. "    " end
            Script = Script .. "[" .. a .. "] = " .. Decompile:Type(b, Lines .. "    ")
            upvalue = true
          end
          Script = Script .. "\n" .. Lines .. "  }"
        end
      end)
    end
    if Decompile.getconstants then
      pcall(function()
        if getconstants and #getconstants(part) > 0 then
          for a,b in pairs(getconstants(part)) do Wait()
            
            if not constant then Script = Script .. "\n" .. Lines .. "  local constants = {\n" .. Lines .. "    "
            else Script = Script .. ",\n" .. Lines .. "    " end
            Script = Script .. "[" .. a .. "] = " .. Decompile:Type(b, Lines .. "    ")
            constant = true
          end
          Script = Script .. "\n" .. Lines .. "  }"
        end
      end)
    end
    Script = Script .. "\n" .. Lines .. "end"
  elseif type == "Vector3" then
    Script = Script .. "Vector3.new(" .. tostring(part) .. ")"
  elseif type == "Color3" then
    Script = Script .. "Color3.new(" .. tostring(part) .. ")"
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
  
  local Var = ""
  table.foreach(Variaveis, function(_,Val)
    Var = Var .. "local " .. Val .. "\ = game:GetService(\"" .. Val .. "\"\)\n"
  end)
  
  if Decompile.setclipboard then
    setclipboard(Var .. "\n" .. Script .. "\n}")
  end
  return (Var .. "\n" .. Script .. "\n}")
end

return Decompile
