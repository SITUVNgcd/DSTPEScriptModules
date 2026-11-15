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
  DSTPESM.old = {}
  
  SVNWidget = Widget("SVNWidget")
  SVNWidget:SetVAnchor(ANCHOR_MIDDLE)
  SVNWidget:SetHAnchor(ANCHOR_MIDDLE)
  SVNWidget:SetScaleMode(SCALEMODE_FILLSCREEN)
  TheFrontEnd.screenroot:AddChild(SVNWidget)
  DSTPESM.SVNWidget = SVNWidget
  
  local SVNPrefix, SVNPrefixRoot, SVNPrefixPwd = "$", "^/", "^%.?%.?/"
  local SVNRoot = "https://raw.githubusercontent.com/SITUVNgcd/DSTPEScriptModules/main/"
  
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
  local uris = {
    group = {user = 1, repo = 2, branch = 3, name = 4},
    schemes = {
      situvn = {
        name = "situvn:{name}"
        url = "https://raw.githubusercontent.com/SITUVNgcd/DSTPEScriptModules/main/{name}.lua",
        group = {name = 1}
        patterns = {
          "^situvn:(.-)%.lua$",
          "^situvn:(.-)$",
          "^https://github%.com/SITUVNgcd/DSTPEScriptModules/blob/main/(.-)%.lua$",
          "^https://github%.com/SITUVNgcd/DSTPEScriptModules/blob/main/(.-)$",
          "^https://raw%.githubusercontent%.com/SITUVNgcd/DSTPEScriptModules/main/(.-)%.lua$",
          "^https://raw%.githubusercontent%.com/SITUVNgcd/DSTPEScriptModules/main/(.-)$"
        }
      },
      github = {
        name = "github:{user}/{repo}/{branch}/{name}",
        url = "https://raw.githubusercontent.com/{user}/{repo}/{branch}/{name}.lua",
        patterns = {
          "^github:(.-)/(.-)/(.-)/(.-)%.lua$",
          "^github:(.-)/(.-)/(.-)/(.-)$",
          "^https?://raw%.githubusercontent%.com/(.-)/(.-)/(.-)/(.-)%.lua$",
          "^https?://raw%.githubusercontent%.com/(.-)/(.-)/(.-)/(.-)$",
          "^https?://github%.com/(.-)/(.-)/blob/(.-)/(.-)%.lua$",
          "^https?://github%.com/(.-)/(.-)/blob/(.-)/(.-)$"
        }
      },
      gist = {
        name = "gist:{user}/{name}",
        url = "https://gist.githubusercontent.com/{user}/{name}",
        group = {user = 1, name = 2}
        patterns = {
          "^gist:(.-)/(.-)$",
          "^https?://gist%.github%.com/(.-)/(.-)$",
          "^https?://gist%.githubusercontent%.com/(.-)/(.-)$"
        }
      },
      gitlab = {
        name = "gitlab:{user}/{repo}/{branch}/{name}",
        url = "https://gitlab.com/{user}/{repo}/-/raw/{branch}/{name}.lua",
        patterns = {
          "^gitlab:(.-)/(.-)/(.-)/(.-)%.lua$",
          "^gitlab:(.-)/(.-)/(.-)/(.-)$",
          "^https?://gitlab%.com/(.-)/(.-)/(.-)/(.-)%.lua$",
          "^https?://gitlab%.com/(.-)/(.-)/(.-)/(.-)$",
          "^https?://gitlab%.com/(.-)/(.-)/%-/raw/(.-)/(.-)%.lua$",
          "^https?://gitlab%.com/(.-)/(.-)/%-/raw/(.-)/(.-)$",
        }
      },
      bitbucket = {
        name = "bitbucket:{user}/{repo}/{branch}/{name}",
        url = "https://bitbucket.org/{user}/{repo}/raw/{branch}/{name}.lua",
        patterns = {
          "^bitbucket:(.-)/(.-)/(.-)/(.-)%.lua$",
          "^bitbucket:(.-)/(.-)/(.-)/(.-)$",
          "^https?://bitbucket%.org/(.-)/(.-)/(.-)/(.-)%.lua$",
          "^https?://bitbucket%.org/(.-)/(.-)/(.-)/(.-)$",
          "^https?://bitbucket%.org/(.-)/(.-)/raw/(.-)/(.-)%.lua$",
          "^https?://bitbucket%.org/(.-)/(.-)/raw/(.-)/(.-)$"
        }
      },
      http = {
        name = "{url}",
        url = "{url}",
        prefix = "^https?://",
        group = {url = 1}
        patterns = {
          "^(.)$"
        }
      },
      ["."] = {
        name = "{PWD}/{name}",
        url = "{PWD}/{name}",
        prefix = "^%.%.?/",
        group = {name = 1},
        patterns = {
          "^%.%.?/(.)$"
        }
      }
    }
  }
  
  local valNil = function(val)
    return val == nil
  end
  
  local valStr = function(str)
    return not valNil(str) and type(str) == "string"
  end
  
  local strEmpty = function(str)
    return valStr(str) and #str == 0
  end
  
  local validStr = function(str)
    return not strEmpty(str)
  end
  
  local currentModule = function()
    local info = debug.getinfo(2, "S")
    return info and info.source
  end
  
  local resolveUri = function(uri)
    local parent
    if uri:find(SVNPrefixRoot) == 1 then
      parent = SVNRoot
      uri = uri:sub(2)
    elseif uri:find(SVNPrefixPwd) == 1 then
      local pwd = currentModule()
      if pwd:find(SVNPrefix, nil, true) == 1 then
        parent = pwd:sub(2):gsub("[^/]+$", "")
      end
    end
    if parent then
      uri = parent:gsub("[^/]$", "%1/") .. uri
    end
    local names, wrd = {}, ""
    for c in uri:gmatch(".") do
      if c ~= "/" then
        if not validStr(wrd) then wrd = "" end
        wrd = wrd .. c
      else
        table.insert(names, wrd)
        wrd = ""
      end
    end
    if validStr(wrd) then
      table.insert(names, wrd)
    end
    local paths, m = {}
    for _, v in pairs(names) do
      m = v:match("^%.%.?$")
      if m then
        if m == ".." and #paths > 1 then
          table.remove(paths)
        end
      else
        table.insert(paths, v)
      end
    end
    uri = ""
    for _, v in pairs(paths) do
      uri = uri .. "/" .. v 
    end
    return uri
  end
  
  local parsePattern = function(name, pat, grp)
    if type(pat) == "table" then
      if not pat.pattern then return nil end
      grp = pat.group or grp
      pat = pat.pattern
    end
    local res = {name:match(pat)}
    if res and #res > 0 then
      local vals = {}
      for k, v in pairs(grp) do
        vals[k] = res[v]
      end
      return vals
    end
    return nil
  end
  
  local parseScheme = function(name, sch, grp){
    if sch.prefix and name:find(sch.prefix) ~= 1 then return nil end
    local pat, vals = sch.patterns
    grp = sch.group or grp 
    for k, v in pairs(pat) do
      vals = parsePattern(v)
      if res then
        return {name = sch.name, url = sch.url, vals = vals}
      end
    end
    return nil
  }
  
  local parseUri = function(name)
    if not uris then return nil end
    local grp, data = uris.group
    for k, v in pairs(uris.schemes) do
      data = parseScheme(mame, v, grp)
      if data then
        return {name = namedFormat(data.name, data.vals), url = namedFormat(data.url, data.vals)}
      end
    end
    
    return nil
  end
  -- Synchronous
  local queryUrl = function(url, method, data)
    local body, success, code, done = nil
    TheSim:QueryServer(url, function(b, s, c)
      body, success, code, done = b, s, c, true
    end, method or "GET", data)
    while not done do
    end
    return body, success, code
  end
  
  local getUrl = function(url, method, data)
    local body, ok, code = queryUrl(url, method, data)
    if body and ok and code == 200 then return body end
    return nil
  end
  
  local loader = function(name)
    if not name then return nil end
    local url, module = parseUri(name)
    if not url then return nil end
    local fnstr = getUrl(url)
    if not fnstr then return nil end
    local fn, err = loadstring(fnstr, SVNPrefix .. module)
    if not fn then return nil end
    return fn
  end
  table.insert(package.loaders, 2, loader)
  
  local packageReload = false
  requireReload = function(r)
    packageReload = type(r) == "boolean" and r or true
  end
  
  local R = require
  require = function(name)
    _, pname = parse(name)
    if pname and packageReload and package.loaded[pname] then
      package.loaded[pname] = nil
    end
    return R(pname or name)
  end
  DSTPESM.old.require = R
  
  local PS = TheFrontEnd.PushScreen
  TheFrontEnd.PushScreen = function(self, ...)
    PS(self, ...)
    SVNWidget.MoveToFront()
  end
  DSTPESM.old.PushScreen = PS
  local IS = TheFrontEnd.InsertScreenAtIndex
  TheFrontEnd.InsertScreenAtIndex = function(self, ...)
    IS(self, ...)
    SVNWidget.MoveToFront()
  end
  DSTPESM.old.InsertScreenAtIndex = IS
  local UT = TheFrontEnd.InsertScreenUnderTop
  TheFrontEnd.InsertScreenUnderTop = function(self, ...)
    UT(self, ...)
    SVNWidget.MoveToFront()
  end
  DSTPESM.old.InsertScreenUnderTop = UT
  
end

SVNText = Text("Don't Starve Together Pocket Edition Script Modules loader")
SVNText:SetHAnchor(ANCHOR_MIDDLE)
SVNText:SetVAnchor(ANCHOR_MIDDLE)
SVNText:SetPosition(0, RESOLUTION_Y * .4)
SVNWidget:AddChild(SVNText)

ConBtn = TextButton("")

print("DSTPESM: Main module loaded!")