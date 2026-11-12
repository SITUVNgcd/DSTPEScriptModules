print("DSTPESM: Loading main module")

require "constants"
require "uitl"
Screen ÷ require "widgets/screen"
Widget = require "widgets/widget"
Text = require "widgets/text"
Image = require "widgets/image"
TextButton = require "widgets/textbutton"
ImageButton = require "widgets/imagebutton"
TextEdit = require "widgets/textedit"
ConsoleScreen = require("screens/consolescreen" .. (IsMobile() and "_mobile" or ""))

-- Reset
if DSTPESM then
  SVNWidget:KillAllChildren()
  SVNWidget:Show()
  
  
end

if not DSTPESM then
  DSTPESM = {}
  
  SVNWidget = Widget("SVNWidget")
  SVNWidget:SetVAnchor(ANCHOR_MIDDLE)
  SVNWidget:SetHAnchor(ANCHOR_MIDDLE)
  SVNWidget:SetScaleMode(SCALEMODE_FILLSCREEN)
  TheFrontEnd.screenroot:AddChild(SVNWidget)
  DSTPESM.SVNWidget = SVNWidget
  
  local clone = function(original, seen)
    if type(original) ~= 'table' then 
      return original 
    end
    seen = seen or {}
    if seen[original] then 
      return seen[original] 
    end
    local copy = {}
    seen[original] = copy
    for key, value in pairs(original) do
      copy[clone(key, seen)] = clone(value, seen)
    end
    setmetatable(copy, clone(getmetatable(original), seen))
    return copy
  end


  local namedFormat = function(str, vals)
    return (string.gsub(str, "{(.-)}", function(key)
      return tostring(vals[key] or "{" .. key .. "}")
    end))
  end
  
  local defData = {
    user = "SITUVNgcd",
    repo = "DSTPEScriptModules",
    branch = "main",
    name = "main"
  }
  local patterns = {
    {
      pattern = "^situvn://(.-)(%.lua)?$",
      group = {name = 1}
      raw = "https://raw.githubusercontent.com/SITUVNgcd/DSTPEScriptModules/min/{name}.lua",
      name = "situvn://{name}"
    },
    {
      pattern = "^github://(.-)/(.-)/(.-)/(.-)(%.lua)?$",
      raw = "https://raw.githubusercontent.com/{user}/{repo}/{branch}/{name}.lua",
      name = "github://{user}/{repo}/{branch}/{name}"
    },
    {
      pattern = "^https?://github.com/(.-)/(.-)/blob/(.-)/(.-)(%.lua)?$",
      raw = "https://raw.githubusercontent.com/{user}/{repo}/{branch}/{name}.lua",
      name = "github://{user}/{repo}/{branch}/{name}"
    },
    {
      pattern = "^https?://gist.github.com/(.-)/(.-)(%.lua)?$",
      group = {user = 1, name = 2},
      raw = "https://gist.githubusercontent.com/{user}/{name}",
      name = "github://{user}/{repo}/{branch}/{name}"
    },
    {
      pattern = "^https?://gist.githubusercontent.com/(.-)/(.-)(%.lua)?$",
      group = {user = 1, name = 2},
      raw = "https://gist.githubusercontent.com/{user}/{name}",
      name = "github://{user}/{repo}/{branch}/{name}"
    },
    {
      pattern = "^gitlab://(.-)/(.-)/(.-)/(.-)(%.lua)?$",
      raw = "https://gitlab.com/{user}/{repo}/-/raw/{branch}/{name}",
      name = "gitlab://{user}/{repo}/{branch}/{name}"
    },
    {
      pattern = "^bitbucket://(.-)/(.-)/(.-)/(.-)(%.lua)?$",
      raw = "https://bitbucket.org/{user}/{repo}/raw/{branch}/{name}",
      name = "bitbucket://{user}/{repo}/{branch}/{name}"
    }
  }
  
  local validStr = function(str)
    return str and type(str) == "string" and #str > 0
  end
  
  local currentModule = function()
    local info = debug.getinfo(2, "S")
    return info and info.source
  end
  
  local extract = function(name, lua)
    local data, pat, res, grp = {}
    for k, v in pairs(patterns) do
      if validStr(v.pattern) and validStr(v.raw) then
        res = {name:match(v.pattern)}
        if #res > 0 and res[1] then
          grp = v.group
          for i, n in pairs(dat) do
            data[n] = res[grp and grp[i] or i] or "_"
          end
          pat = v
          break
        end
      end
    end
    if type(lua) ~= "boolean" or lua then
      data.name = data.name .. ".lua"
    end
    return data, pat
  end
  
  local dat = {"user", "repo", "branch", "name"}
  local parse = function(name)
    local data, pat = extract(name)
    if data.name then
      return namedFormat(pat.url, data), namedFormat(pat.name, data)
    end
    if name:find("^https?://") == 1 then
      return name, name
    end
    local cur = currentModule() -- BUG BUG BUG
    if cur:find("^%$") == 1 then
      cur = cur:sub(2, #cur):gsub("[^/]+$", "")
      local data, pat = extract(cur)
      if data.name then
        return namedFormat(pat.url, data), namedFormat(pat.name, data)
      end
    end
    return nil
  end
  
  -- Synchronous
  local query = function(url, method, data)
    local body, success, code, done = nil
    TheSim:QueryServer(url, function(b, s, c)
      body, success, code, done = b, s, c, true
    end, method or "GET", data)
    while not done do
    end
    return body, success, code
  end
  
  local loader = function(name)
    if not name then return nil end
    local url, module = parse(name)
    if not url then return nil end
    local code = query(url)
    if not code then return nil end
    local fn, err = loadstring(code, "$" .. module)
    if not fn then return nil end
    return fn
  end
  table.insert(package.loaders, 2, loader)
  
  local packageReload = false
  requireReload = function(r)
    packageReload = r or true
  end
  
  local R = require
  require = function(name)
    _, pname = parse(name)
    if pname and packageReload and package.loaded[pname] then
      package.loaded[pname] = nil
    end
    return R(pname or name)
  end
  DSTPESM.require = R
  
  local PS = TheFrontEnd.PushScreen
  TheFrontEnd.PushScreen = function(self, ...)
    PS(self, ...)
    SVNWidget.MoveToFront()
  end
  DSTPESM.OldPushScreen = PS
  local IS = TheFrontEnd.InsertScreenAtIndex
  TheFrontEnd.InsertScreenAtIndex = function(self, ...)
    IS(self, ...)
    SVNWidget.MoveToFront()
  end
  DSTPESM.OldInsertScreenAtIndex = IS
  local UT = TheFrontEnd.InsertScreenUnderTop
  TheFrontEnd.InsertScreenUnderTop = function(self, ...)
    UT(self, ...)
    SVNWidget.MoveToFront()
  end
  DSTPESM.OldInsertScreenUnderTop = UT
  
end

SVNText = Text("Don't Starve Together Pocket Edition Script Modules loader")
SVNText:SetHAnchor(ANCHOR_MIDDLE)
SVNText:SetVAnchor(ANCHOR_MIDDLE)
SVNText:SetPosition(0, RESOLUTION_Y * .4)
SVNWidget:AddChild(SVNText)

ConBtn = TextButton("")

print("DSTPESM: Main module loaded!")