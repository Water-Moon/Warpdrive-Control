--launcher.lua
--用于启动软件包中的程序
--基于OpenOS制作
---------
do
  ---@diagnostic disable-next-line: undefined-global
      local addr, invoke = computer.getBootAddress(), component.invoke
      local function loadfile(file)
          local handle = assert(invoke(addr, "open", file))
          local buffer = ""
          repeat
          local data = invoke(addr, "read", handle, math.huge)
          buffer = buffer .. (data or "")
          until not data
          invoke(addr, "close", handle)
          return load(buffer, "=" .. file, "bt", _G)
      end
      loadfile("/lib/core/boot.lua")(loadfile)
  end
  
  local component = require("component")
  local gpu = component.gpu
  gpu.setResolution(gpu.maxResolution())
  gpu.setViewport(gpu.maxResolution())
  gpu.setBackground(0x000000)
  gpu.setForeground(0xffffff)
  gpu.fill(0, 0, 999, 999, " ")
  
  io.write("Loading warp control...")
  local filename = "/bin/warpdrive.lua"
  local buffer, script, reason
  buffer = io.lines(filename, "*a")()
  if buffer then
    buffer = buffer:gsub("^#![^\n]+", "") -- remove shebang if any
    script, reason = load(buffer, "="..filename)
  else
    reason = string.format("could not open %s for reading", filename)
  end
  
  if not script then
    io.stderr:write(tostring(reason) .. "\n")
    os.exit(false)
  end
  local status, reason = pcall(script)
  if not status then
    io.stderr:write(type(reason) == "table" and reason.reason or tostring(reason), "\n")
    os.exit(false)
  end
  
  
  io.write("returning to OpenOS")
  os.sleep(1)
  
  while true do
      local result, reason = xpcall(require("shell").getShell(), function(msg)
          return tostring(msg).."\n"..debug.traceback()
      end)
      if not result then
          io.stderr:write((reason ~= nil and tostring(reason) or "unknown error") .. "\n")
          io.write("Press any key to continue.\n")
          os.sleep(0.5)
          require("event").pull("key")
      end
  end