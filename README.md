# DSTPEScriptModules
Script modules loader for Don't Starve Together Pocket Edition

<div align="center">

| **English** | [Tiếng Việt](README_vi.md)
| --- | --- |

</div>

## How to load module
Copy lua script below, paste to ingame console and run it on **Local** mode, not ~~Remote--.
```lua
local DSTPESM="https://raw.githubusercontent.com/SITUVNgcd/DSTPEScriptModules/main/main.lua"TheSim.QueryServer(DSTPESM,function(a,b,c)if b and a then ExecuteConsoleCommand(a)else print("DSTPESM: Unable to load main module")end end)
```