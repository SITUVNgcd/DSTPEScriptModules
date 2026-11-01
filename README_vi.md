# DSTPEScriptModules
Trình nạp mô-đun lệnh kịch bản cho Don't Starve Together Pocket Edition

<div align=center">

| [English](README.md) | **Tiếng Việt**
| --- | --- |

</div>

## Cách để nạp mô-đun
Sao chép đoạn lệnh kịch bản lua bên dưới, dán vào bảng điều khiển lệnh trong trò chơi và chạy nó.
```lua
local DSTPESM="https://raw.githubusercontent.com/SITUVNgcd/DSTPEScriptModules/main/main.lua"TheSim.QueryServer(DSTPESM,function(a,b,c)if b and a then ExecuteConsoleCommand(a)else print("DSTPESM: Unable to load main module")end end)
```