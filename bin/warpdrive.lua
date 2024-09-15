---@diagnostic disable: need-check-nil, unused-local
local component = require("component")
local computer = require("computer")

local window = require("window")
local label = require("widgetLabel")
local btn = require("widgetButton")
local pbar = require("widgetProgressBar")
local img = require("widgetImage")
local em = require("windowEventHandler")
local tbox = require("widgetTextBox")
local filesystem = require("filesystem")
local serialization = require("serialization")

local core = nil

local siriName = "moss"

local AR_X_OFFSET = 70;
local AR_Y_OFFSET = 5;
local AR_Y_SPACING = 2.5;

local function bindCore()
   core = component.warpdriveShipCore
end

local function sleepFor(time)
	local lastTime = computer.uptime()
	while(computer.uptime() - lastTime < time) do
	   computer.pullSignal(0.1)
	end
end



local gpu = component.gpu
local Screen = component.proxy(component.list("screen")())
local siri = nil
local siriout = nil
local chatbox_mode = false
local AR = nil
if(component.list("warpdriveVirtualAssistant")()) then
   siri = component.proxy(component.list("warpdriveVirtualAssistant")())
end
if(component.list("warpdriveSpeaker")()) then
   siriout = component.proxy(component.list("warpdriveSpeaker")())
elseif(component.list("chat_box")()) then
	siriout = component.proxy(component.list("chat_box")())
	chatbox_mode = true
end

if(component.list("glasses")()) then
	AR = component.proxy(component.list("glasses")())
end

local function ARAddText(content, line, red, green, blue, alpha)
	if(not AR) then return nil end;
	local widget = AR.addText2D();
	widget.setText(content);
	widget.addColor(red, green, blue, alpha);
	widget.addAutoTranslation(AR_X_OFFSET, AR_Y_OFFSET + (line * AR_Y_SPACING));
	return widget;
end

local function ARSetText(content, widget, red, green, blue, alpha)
	if(not AR) then return nil end;
	widget.setText(content);
	widget.addColor(red, green, blue, alpha);
	return widget;
end

local function ARRemoveText(widget)
	if(not AR) then return end;
	if(widget) then
		widget.removeWidget()
	end
end

local running = true

local w1 = window:new(nil, gpu, 0x000000, 0xffffff, print)
local em1 = em:new(nil, w1)

local result, err = pcall(bindCore)
local Controller_Mode = false
local function bindController()
	core = component.warpdriveShipController
	Controller_Mode = true
end

if(AR) then
	AR.removeAll();
	AR.startLinking();
	print("正在初始化AR信息面板...")
	sleepFor(3);
end
local AR_Initializing_Text = ARAddText("正在初始化", -2, 0, 1, 0, 0.75);

if(not result) then
	result, err = pcall(bindController)
	if(not result) then
		error("没找到飞船核心，无法运行")
	end
   local lbl_remote_mode = 	label:new(nil, "远程控制模式", 2, 25, 20, 1, 0x000000, 0xffff00)
   w1:addWidget(lbl_remote_mode)
   computer.beep("..")
end
if(siri and siriout) then
   local lbl_siri_available = 	label:new(nil, "语音控制可用", 2, 24, 20, 1, 0x000000, 0x00ff00)
   w1:addWidget(lbl_siri_available)
   computer.beep("..")
end
if(AR) then
   local lbl_AR_available = 	label:new(nil, "AR界面可用", 2, 23, 20, 1, 0x000000, 0x00ff00)
   w1:addWidget(lbl_AR_available)
   AR.startLinking()
   computer.beep("..")
end

local ver = label:new(nil, "Simple Warp V1.7 By Water_Moon and n507", 35, 25, 40, 1, 0x000000, 0xffffff)
w1:addWidget(ver)


local function putTable(t, f) -- save table to file
   if type(t) == "table" then
      local file = filesystem.open(f, "w")
      file:write(serialization.serialize(t))
      file:close()
      return true
   else
      return false
   end
end

local function getTable(f) -- get table from file
if filesystem.exists(f) then
	local file = io.open(f, "r")
	if(file) then
		local fileSize = filesystem.size(f)
		local fileRead = file:read(fileSize)
		local fileContent = fileRead
		file:close()
		return serialization.unserialize(fileContent)
	else return false end
	else
		return false
	end
end

local savedData = getTable("/home/warpdrive_control_save.dat");
if (savedData) then
	if(savedData.siriName) then
		siriName = savedData.siriName
	else
		siriName = core.name();
	end
end

local function refresh_gpu()
	local AR_Refreshing_Text = ARAddText("正在刷新...", -1, 0, 1, 0, 0.75);
	Screen = component.proxy(component.list("screen")())

	while true do
		if not Screen then
			Screen = component.proxy(component.list("screen")())
			sleepFor(0.5)
		else
			gpu = component.proxy(component.list("gpu",true)())
			if(Controller_Mode) then
				core = component.proxy(component.list("warpdriveShipController",true)())
			else
				core = component.proxy(component.list("warpdriveShipCore", true)())
			end
			if(component.list("warpdriveVirtualAssistant")()) then
				siri = component.proxy(component.list("warpdriveVirtualAssistant")())
			end
			if(component.list("warpdriveSpeaker")()) then
				siriout = component.proxy(component.list("warpdriveSpeaker")())
			elseif(component.list("chat_box")()) then
				siriout = component.proxy(component.list("chat_box")())
				chatbox_mode = true
			end
			if(component.list("glasses")()) then
				AR = component.proxy(component.list("glasses")())
			end
			break
		end
	end

	ARRemoveText(AR_Refreshing_Text);

	if not gpu.getScreen() then
		gpu.bind(Screen.address)
		gpu.setViewport(80,25)
		gpu.setResolution(80,25)
		return true
	end
	return false
end

refresh_gpu()

gpu.setViewport(80,25)
gpu.setResolution(80,25)

local function warp()
	core.command("MANUAL", true)
end


local lbl_dimension = 	label:new(nil, "船体尺寸", 1, 1, 16, 1, 0x000000, 0xffffff)
local lbl_front = 		label:new(nil, "前：", 1, 3, 6, 1, 0x000000, 0xffffff)
local lbl_back = 		label:new(nil, "后：", 1, 4, 6, 1, 0x000000, 0xffffff)
local lbl_left = 		label:new(nil, "左：", 1, 5, 6, 1, 0x000000, 0xffffff)
local lbl_right = 		label:new(nil, "右：", 1, 6, 6, 1, 0x000000, 0xffffff)
local lbl_up = 			label:new(nil, "上：", 1, 7, 6, 1, 0x000000, 0xffffff)
local lbl_down = 		label:new(nil, "下：", 1, 8, 6, 1, 0x000000, 0xffffff)
local lbl_name = 		label:new(nil, "名称：", 1, 9, 6, 1, 0x000000, 0xffffff)

local lbl_mass =		label:new(nil, "船体质量", 1, 2, 20, 1, 0x000000, 0xffffff)

local status = label:new(nil, "..", 1, 10, 30, 5, 0x000000, 0xffffff)

w1:addWidget(lbl_dimension)
w1:addWidget(lbl_front)
w1:addWidget(lbl_back)
w1:addWidget(lbl_left)
w1:addWidget(lbl_right)
w1:addWidget(lbl_up)
w1:addWidget(lbl_down)
w1:addWidget(lbl_name)
w1:addWidget(status)
w1:addWidget(lbl_mass)


local tbox_front = 	tbox:new(nil, "", 7, 3, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_back = 	tbox:new(nil, "", 7, 4, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_left = 	tbox:new(nil, "", 7, 5, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_right = 	tbox:new(nil, "", 7, 6, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_up = 	tbox:new(nil, "", 7, 7, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_down = 	tbox:new(nil, "", 7, 8, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_name = 	tbox:new(nil, "", 7, 9, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)


w1:addWidget(tbox_front)
w1:addWidget(tbox_back)
w1:addWidget(tbox_left)
w1:addWidget(tbox_right)
w1:addWidget(tbox_up)
w1:addWidget(tbox_down)
w1:addWidget(tbox_name)

local function updateDimensionDisplay()
	local success = core.getAssemblyStatus()
	if(not success) then
		status:setText("舰船尺寸未设置！")
		return
	end

	local front, right, up = core.dim_positive()
	local back, left, down = core.dim_negative()

	tbox_front:setText(""..front)
	tbox_back:setText(""..back)
	tbox_left:setText(""..left)
	tbox_right:setText(""..right)
	tbox_up:setText(""..up)
	tbox_down:setText(""..down)
	tbox_name:setText(""..core.name())
end

local function refreshShipMass()
	local mass, vol = core.getShipSize()

	lbl_mass:setText("船体质量"..mass)
end

updateDimensionDisplay()
refreshShipMass()

local function updateShipDimension()
	local front = 	tonumber(tbox_front:getText())
	local back = 	tonumber(tbox_back:getText())
	local left = 	tonumber(tbox_left:getText())
	local right = 	tonumber(tbox_right:getText())
	local up = 		tonumber(tbox_up:getText())
	local down = 	tonumber(tbox_down:getText())

	if(not(front and back and left and right and up and down)) then
		status:setText("输入不为数字")
		computer.beep("..")
		return
	end

	core.dim_positive(front, right, up)
	core.dim_negative(back, left, down)
	core.name(tbox_name:getText())

	updateDimensionDisplay()
	computer.beep(800, 0.1)
	computer.beep(1200, 0.3)
	status:setText("尺寸设置成功")
end

local btnconfirm = btn:new(nil, "设置尺寸", updateShipDimension, 1, 16, 16, 3, 0xffffff, 0x000000)
w1:addWidget(btnconfirm)

local btnOnOff = btn:new(nil, "", nil, 1, 20, 16, 3, 0xffffff, 0x000000)

if(Controller_Mode) then
	btnOnOff:setText("(不可用)")
	btnOnOff:setColor(0xffffff, 0xaaaaaa)
else
	if(core.enable()) then
		btnOnOff:setText("关闭核心")
	else
		btnOnOff:setText("开启核心")
	end
end
w1:addWidget(btnOnOff)

local function shipOnOff()
	if(Controller_Mode) then
		btnOnOff:setText("(不可用)")
		btnOnOff:setColor(0xffffff, 0xaaaaaa)
		computer.beep("..")
		return
	end
	local enabled = core.enable()
	if(enabled) then
		core.enable(false)
		btnOnOff:setText("开启核心")
	else
		core.enable(true)
		btnOnOff:setText("关闭核心")
	end
	core.command("MANUAL", false)
end

btnOnOff:setCallback(shipOnOff)

local lbl_jump_rel = 	label:new(nil, "跃迁", 20, 1, 30, 1, 0x000000, 0xffffff)
local lbl_jump_fwd = 	label:new(nil, " 前(+)/后(-):", 20, 3, 15, 1, 0x000000, 0xffffff)
local lbl_jump_right = 	label:new(nil, " 右(+)/左(-):", 20, 4, 15, 1, 0x000000, 0xffffff)
local lbl_jump_up = 	label:new(nil, " 上(+)/下(-):", 20, 5, 15, 1, 0x000000, 0xffffff)
local lbl_rotation = 	label:new(nil, " 旋转，1=右 2=后 3=左", 20, 6, 30, 1, 0x000000, 0xffffff)

local tbox_jump_fwd = 		tbox:new(nil, "..前后..", 35, 3, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_jump_right = 	tbox:new(nil, "..左右..", 35, 4, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_jump_up = 		tbox:new(nil, "..上下..", 35, 5, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_jump_rotate = 		tbox:new(nil, "..旋转..", 35, 7, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)


local lbl_jump_abs = 	label:new(nil, "绝对坐标", 55, 1, 30, 1, 0x000000, 0xffffff)
local lbl_jump_x = 	label:new(nil, " x:", 55, 3, 5, 1, 0x000000, 0xffffff)
local lbl_jump_y = 	label:new(nil, " y:", 55, 4, 5, 1, 0x000000, 0xffffff)
local lbl_jump_z = 	label:new(nil, " z:", 55, 5, 5, 1, 0x000000, 0xffffff)
local tbox_jump_x = 		tbox:new(nil, "..x..", 60, 3, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_jump_y = 	tbox:new(nil, "..y..", 60, 4, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)
local tbox_jump_z = 		tbox:new(nil, "..z..", 60, 5, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)

if(savedData) then
	if(savedData.abs_x) then 		tbox_jump_x:		setText("" .. savedData.abs_x);			end
	if(savedData.abs_y) then 		tbox_jump_y:		setText("" .. savedData.abs_y);			end
	if(savedData.abs_z) then 		tbox_jump_z:		setText("" .. savedData.abs_z);			end
	if(savedData.rel_fwd) then 		tbox_jump_fwd:		setText("" .. savedData.rel_fwd);		end
	if(savedData.rel_right) then 	tbox_jump_right:	setText("" .. savedData.rel_right);		end
	if(savedData.rel_up) then 		tbox_jump_up:		setText("" .. savedData.rel_up);		end
	if(savedData.rotate) then 		tbox_jump_rotate:	setText("" .. savedData.rotate);		end
end

w1:addWidget(lbl_jump_rel)
w1:addWidget(lbl_jump_fwd)
w1:addWidget(lbl_jump_right)
w1:addWidget(lbl_jump_up)
w1:addWidget(lbl_rotation)
w1:addWidget(tbox_jump_fwd)
w1:addWidget(tbox_jump_right)
w1:addWidget(tbox_jump_up)
w1:addWidget(tbox_jump_rotate)

w1:addWidget(lbl_jump_abs)
w1:addWidget(lbl_jump_x)
w1:addWidget(lbl_jump_y)
w1:addWidget(lbl_jump_z)
w1:addWidget(tbox_jump_x)
w1:addWidget(tbox_jump_y)
w1:addWidget(tbox_jump_z)


local function updateJumpDisplay()
	local fwd, u, r = core.movement()
	local ro = core.rotationSteps()

	tbox_jump_fwd:setText(""..fwd)
	tbox_jump_right:setText(""..r)
	tbox_jump_up:setText(""..u)
	tbox_jump_rotate:setText(""..ro)
end


local function jumpSaveLoc()
	local fwd = 	tonumber(tbox_jump_fwd:getText())
	local right = 	tonumber(tbox_jump_right:getText())
	local up = 		tonumber(tbox_jump_up:getText())
	local ro = 		tonumber(tbox_jump_rotate:getText())

	if(not(fwd and right and up and ro)) then
		status:setText("跃迁坐标输入有误")
		computer.beep("..")
		return
	end


	if(not (ro == 0 or ro == 1 or ro == 2 or ro == 3)) then
		status:setText("旋转数字错误")
		computer.beep("..")
		return
	end
	core.movement(fwd, up, right)
	core.rotationSteps(ro)
	status:setText("设定成功")
	updateJumpDisplay()
	computer.beep(800, 0.1)
	computer.beep(1200, 0.3)
end

updateJumpDisplay()

local function jumpJump()
	warp()
	status:setText("正在启动跃迁")
end
local function hyperDrive()
	core.command("HYPERDRIVE", true)
	status:setText("启动超空间跃迁..")
end

local function quit()
	running = false
end

local function computeAbs()
	local dx, dy, dz = core.getOrientation()
	local curX, curY, curZ = core.getLocalPosition()
	local fwd, up, right = 0, 0, 0
	local x = 	tonumber(tbox_jump_x:getText())
	local y = 	tonumber(tbox_jump_y:getText())
	local z = 	tonumber(tbox_jump_z:getText())
	if(not(x and y and z)) then
		status:setText("跃迁坐标输入有误")
		computer.beep("..")
		return
	end
	if(dx == nil) then
		dx, dy, dz = 0, 0, 0
	end
	if(dx == 0) then
		right = -dz * (x - curX)
		fwd = dz * (z - curZ)
	else
		fwd = dx * (x - curX)
		right = dx * (z - curZ)
	end
	up = y - curY

	core.movement(fwd, up, right)
	status:setText("计算成功")
	updateJumpDisplay()
	computer.beep(800, 0.1)
	computer.beep(1200, 0.3)
end

local function absWriteCurrent()
	local curX, curY, curZ = core.getLocalPosition()
	tbox_jump_x:setText(curX)
	tbox_jump_y:setText(curY)
	tbox_jump_z:setText(curZ)
	status:setText("已填入当前坐标")
	computer.beep(800, 0.1)
	computer.beep(1200, 0.3)
end


local lblWpt = label:new(nil, "路径点", 55, 13, 20, 1, 0x000000, 0xffffff)
local lblWptName = label:new(nil, "输入ID:", 45, 15, 30, 1, 0x000000, 0xffffff)
local tboxWptID = tbox:new(nil, "..id..", 60, 16, 10, 1, 0xffffff, 0x000000, 0xffffff, 0x000000, 0x00ff00, 0x000000)

local overwriteConfirm = false
local overwriteName = ""
local lastLoadSuccess = false

local function loadCoord(name)
	lastLoadSuccess = false
	local wpts = getTable("/home/warp_waypoint.dat")
	local id = tboxWptID:getText()
	if((not id) or (id == "")) then
		status:setText("请输入ID")
		computer.beep("..")
		return
	end
	if(not wpts) then
		status:setText("未找到此航点")
		computer.beep("..")
		return
	end
	if(not wpts[id]) then
		status:setText("未找到此航点")
		computer.beep("..")
		return
	end
	local wptData = wpts[id]
	tbox_jump_x:setText(""..wptData[1])
	tbox_jump_y:setText(""..wptData[2])
	tbox_jump_z:setText(""..wptData[3])
	status:setText("读取航点成功")
	lastLoadSuccess = true
	computer.beep(800, 0.1)
	computer.beep(1200, 0.3)
end

local function loadCoordWrapper(name)
	local ok, err = pcall(loadCoord, name)
	if(not ok) then
		status:setText("读取航点出错")
		print(err)
	end
end

local function saveCoord(name)
	local x = tonumber(tbox_jump_x:getText())
	local y = tonumber(tbox_jump_y:getText())
	local z = tonumber(tbox_jump_z:getText())
	local wpts = getTable("/home/warp_waypoint.dat")
	if(not(x and y and z)) then
		status:setText("跃迁坐标输入有误")
		computer.beep("..")
		return
	end
	local id = tboxWptID:getText()
	if((not id) or (id == "")) then
		status:setText("请输入ID")
		computer.beep("..")
		return
	end
	if(not wpts) then wpts = {} end
	if(not(overwriteName == id)) then
		overwriteConfirm = false
	end
	if(wpts[id] and ((not overwriteConfirm)) or (overwriteConfirm and (not overwriteName == id))) then
		status:setText("已有ID,再点一次覆盖")
		computer.beep("..")
		overwriteConfirm = true
		overwriteName = id
		return
	end
	local wptData = {}
	wptData[1] = x
	wptData[2] = y
	wptData[3] = z
	wpts[id] = wptData
	putTable(wpts, "/home/warp_waypoint.dat")
	status:setText("保存航点成功")
	overwriteConfirm = false
	computer.beep(800, 0.1)
	computer.beep(1200, 0.3)
end

local function saveCoordWrapper(name)
	local ok, err = pcall(saveCoord, name)
	if(not ok) then
		status:setText("写入航点出错")
		print(err)
	end
end


local btnWptSave = btn:new(nil, "保存航点", saveCoordWrapper, 55, 18, 15, 1, 0xffffff, 0x000000)
local btnWptLoad = btn:new(nil, "读取航点", loadCoordWrapper, 55, 20, 15, 1, 0xffffff, 0x000000)
w1:addWidget(lblWpt)
w1:addWidget(lblWptName)
w1:addWidget(tboxWptID)
w1:addWidget(btnWptSave)
w1:addWidget(btnWptLoad)


local btnJumpConfirm = btn:new(nil, "保存", jumpSaveLoc, 37, 10, 13, 3, 0xffffff, 0x000000)
local btnJumpConfirmAbs = btn:new(nil, "计算为相对坐标", computeAbs, 55, 7, 22, 3, 0xffffff, 0x000000)
local btnAbsWriteCurrent = btn:new(nil, "填入当前坐标", absWriteCurrent, 55, 11, 22, 1, 0xffffff, 0x000000)
local btnJumpJump = btn:new(nil, "跃迁", jumpJump, 37, 15, 13, 3, 0xffffff, 0x000000)
local btnJumpHyper = btn:new(nil, "超空间", hyperDrive, 37, 19, 13, 3, 0xffffff, 0x000000)
local btnQuit = btn:new(nil, "退出", quit, 70, 22, 10, 3, 0xffffff, 0x000000)
w1:addWidget(btnJumpConfirm)
w1:addWidget(btnJumpConfirmAbs)
w1:addWidget(btnAbsWriteCurrent)
w1:addWidget(btnJumpJump)
w1:addWidget(btnJumpHyper)
w1:addWidget(btnQuit)

local function processEvent()
	em1:processEvent(computer.pullSignal(0.15))
end

local function draw()
	refreshShipMass()
	w1:draw()
end

local function trimstr(s)
	return s:match"^%s*(.*)":match"(.-)%s*$"
end 

local function splitstr(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, trimstr(string.gsub(str, ",", "")))
	end
	return t
end


local function removesubstr(s, substr)
	while (string.find(s, substr)) do
		local tmp1, tmp2 = string.find(s, substr);
		s = string.sub(s, 1, tmp1-1)
	end
	return trimstr(s)
end 

local function speakerSpeak(msg)
	if(siriout) then
		if(chatbox_mode) then
			siriout.setDistance(512)
			if(core.name() == siriName) then
				siriout.setName(siriName)
			else
				siriout.setName(core.name() .."/" .. siriName)
			end
			siriout.say(" "..msg)
		else
			if(core.name() == siriName) then
				siriout.name(siriName)
				siriout.speak("<" .. siriName .. "> " .. msg)
			else
				siriout.name(siriName)
				siriout.speak("<".. core.name() .."/" .. siriName .. "> " .. msg)
			end
		end
	end
end

local function relToAbsCoord(str, origCoord)
	if(str == "~") then return origCoord end
	if(string.find(str, "~")) then
		local tmp = string.gsub(str, "~", "")
		if(not tonumber(tmp)) then return false end
		return origCoord + tmp
	end
	return str
end

local function checkWarpReady()
	if(not core.enable()) then
		speakerSpeak("舰船核心已关闭，请先开启核心")
		return false
	end
	local success = core.getAssemblyStatus()
	if(not success) then
		speakerSpeak("需要首先设置舰船尺寸。")
		return false
	end
	return true
end

local function updateSiri()
	if(siri and siriout) then
		siri.name(siriName)
		local received, msg = siri.pullLastCommand()
		if(received) then

		computer.beep("..")

		-- 需要参数的功能 --
		local index, indexend = string.find(msg, "跃迁到")
		if index then
			if not checkWarpReady() then return end
			local result = splitstr(string.sub(msg, indexend + 1, string.len(msg)), "%s")
			if (#result < 3) then
				speakerSpeak("无法识别该指令")
				return
			end
			local curX, curY, curZ = core.getLocalPosition()
			computer.beep(".-")
			result[1] = relToAbsCoord(result[1], curX)
			result[2] = relToAbsCoord(result[2], curY)
			result[3] = relToAbsCoord(result[3], curZ)
			if not (result[1] and result[2] and result[3]) then
				speakerSpeak("需要输入数字（如果一个坐标不改变，可以输入~）")
				return
			end
			if not (tonumber(result[1]) and tonumber(result[2]) and tonumber(result[3])) then
				speakerSpeak("需要输入数字（如果一个坐标不改变，可以输入~）")
				return
			end
			speakerSpeak("正在跃迁到：x=" .. result[1] .. "，y=" .. result[2] .. "，z=" .. result[3])
			tbox_jump_x:setText(result[1])
			tbox_jump_y:setText(result[2])
			tbox_jump_z:setText(result[3])
			computeAbs()
			jumpJump()
			updateJumpDisplay()
			return
		end

		index, indexend = string.find(msg, "前往")
		if index then
			if not checkWarpReady() then return end
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			computer.beep(".-")
			tboxWptID:setText(result)
			loadCoordWrapper(result)
			if (not lastLoadSuccess) then
				speakerSpeak("没有关于\"" .. result .. "\"这个地点的记录。")
				return
			end
			speakerSpeak("正在跃迁到" .. result .. "，坐标：x=" .. tbox_jump_x:getText() .. "，y=" .. tbox_jump_y:getText() .. "，z=" .. tbox_jump_z:getText())
			computeAbs()
			jumpJump()
			updateJumpDisplay()
			return
		end

		if string.find(msg, "超空间") or string.find(msg, "前进四") then
			if not checkWarpReady() then return end
			speakerSpeak("准备超空间跃迁...")
			hyperDrive()
			return
		end

		index, indexend = string.find(msg, "前进")
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "跃迁"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			computer.beep(".-")
			speakerSpeak("正在向前跃迁" .. result .. "格")
			core.movement(result, 0, 0)
			updateJumpDisplay()
			computer.beep(".-")
			jumpJump()
			return
		end

		index, indexend = string.find(msg, "后退")
		if(not index) then index, indexend = string.find(msg, "倒退") end
		if(not index) then index, indexend = string.find(msg, "倒车") end
		if(not index) then index, indexend = string.find(msg, "倒船") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "跃迁"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			computer.beep(".-")
			speakerSpeak("正在向后跃迁" .. result .. "格")
			core.movement(0-result, 0, 0)
			updateJumpDisplay()
			computer.beep(".-")
			jumpJump()
			return
		end

		index, indexend = string.find(msg, "左移动")
		if(not index) then index, indexend = string.find(msg, "左移") end
		if(not index) then index, indexend = string.find(msg, "向左") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "跃迁"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			computer.beep(".-")
			speakerSpeak("正在向左跃迁" .. result .. "格")
			core.movement(0, 0, 0 - result)
			updateJumpDisplay()
			computer.beep(".-")
			jumpJump()
			return
		end

		index, indexend = string.find(msg, "右移动")
		if(not index) then index, indexend = string.find(msg, "右移") end
		if(not index) then index, indexend = string.find(msg, "向右") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "跃迁"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			computer.beep(".-")
			speakerSpeak("正在向右跃迁" .. result .. "格")
			core.movement(0, 0, result)
			updateJumpDisplay()
			computer.beep(".-")
			jumpJump()
			return
		end

		index, indexend = string.find(msg, "上升到")
		if(not index) then index, indexend = string.find(msg, "上升至") end
		if(not index) then index, indexend = string.find(msg, "爬升至") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "高度"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			local curX, curY, curZ = core.getLocalPosition()
			computer.beep(".-")
			if(curY > tonumber(result)) then
				speakerSpeak("目前已经高于这个高度了")
				return
			end
			speakerSpeak("正在跃迁到Y=" .. result)
			tbox_jump_x:setText(curX)
			tbox_jump_y:setText(result)
			tbox_jump_z:setText(curZ)
			computeAbs()
			jumpJump()
			updateJumpDisplay()
			return
		end

		index, indexend = string.find(msg, "上升")
		if(not index) then index, indexend = string.find(msg, "向上") end
		if(not index) then index, indexend = string.find(msg, "抬升") end
		if(not index) then index, indexend = string.find(msg, "起飞") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if(string.find(msg, "起飞")) then
				result = "256"
			end
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "跃迁"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			computer.beep(".-")
			speakerSpeak("正在向上跃迁" .. result .. "格")
			core.movement(0, result, 0)
			updateJumpDisplay()
			computer.beep(".-")
			jumpJump()
			return
		end


		index, indexend = string.find(msg, "下降到")
		if(not index) then index, indexend = string.find(msg, "下降至") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "高度"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			local curX, curY, curZ = core.getLocalPosition()
			computer.beep(".-")
			if(curY < tonumber(result)) then
				speakerSpeak("目前已经低于这个高度了")
				return
			end
			speakerSpeak("正在跃迁到Y=" .. result)
			tbox_jump_x:setText(curX)
			tbox_jump_y:setText(result)
			tbox_jump_z:setText(curZ)
			computeAbs()
			jumpJump()
			updateJumpDisplay()
			return
		end


		index, indexend = string.find(msg, "下降")
		if(not index) then index, indexend = string.find(msg, "向下") end
		if(not index) then index, indexend = string.find(msg, "降低") end
		if(not index) then index, indexend = string.find(msg, "降落") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if(string.find(msg, "降落")) then
				result = "256"
			end
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(removesubstr(removesubstr(result, "跃迁"), "格"), "米"), "个"),"方块")
			if not checkWarpReady() then return end
			if(not tonumber(result)) then
				speakerSpeak("请给出要移动的格数")
				return
			end
			computer.beep(".-")
			speakerSpeak("正在向下跃迁" .. result .. "格")
			core.movement(0, 0 - result, 0)
			updateJumpDisplay()
			computer.beep(".-")
			jumpJump()
			return
		end

		index, indexend = string.find(msg, "更名为")
		if(not index) then index, indexend = string.find(msg, "叫你") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			result = removesubstr(removesubstr(removesubstr(result, "?"), "？"), "吗")
			if(string.len(result) < 3) then
				speakerSpeak("这个名字太短了，至少需要三个字符长。")
				return
			end
			computer.beep(".-")
			siriName = result;
			speakerSpeak("好的，之后您可以用\"" .. result .. "\"作为消息前缀。")
			speakerSpeak("例如：".. result .. "，跃迁到 100 200 300")
			return
		end
		
		index, indexend = string.find(msg, "修改船名为")
		if(not index) then index, indexend = string.find(msg, "改舰船名为") end
		if(not index) then index, indexend = string.find(msg, "改船名为") end
		if(not index) then index, indexend = string.find(msg, "船名改成") end
		if(not index) then index, indexend = string.find(msg, "船名改为") end
		if index then
			local result = trimstr(string.sub(msg, indexend + 1, string.len(msg)))
			result = removesubstr(removesubstr(removesubstr(result, "?"), "？"), "吗")
			if not result then
				speakerSpeak("无法识别该指令")
				return
			end
			core.name(result);
			speakerSpeak("舰船名称已经改成了\"" .. result .. "\"")
			updateDimensionDisplay()
			return
		end
		
		index, indexend = string.find(msg, "跃迁")
		if (index) then
			if not checkWarpReady() then return end
			local result = splitstr(string.sub(msg, indexend + 1, string.len(msg)), "%s")
			if (#result < 3) then
				speakerSpeak("无法识别该指令")
				return
			end
			speakerSpeak("正在跃迁：向前" .. result[1] .. "，向上" .. result[2] .. "，向右" .. result[3])
			core.movement(result[1], result[2], result[3])
			updateJumpDisplay()
			computer.beep(".-")
			jumpJump()
			return
		end

		-- 其他实际功能（不需要参数） --
		if string.find(msg, "当前") or string.find(msg, "位置") or string.find(msg, "在哪") then
			computer.beep(".-")
			local curX, curY, curZ = core.getLocalPosition()
			speakerSpeak("当前位置：x=" .. curX .. "，y=" .. curY .. "，z=" .. curZ)
			absWriteCurrent()
			return
		end

		if string.find(msg, "关闭") then
			if(core.enable()) then
				speakerSpeak("已关闭舰船核心")
				shipOnOff()
			else
				speakerSpeak("舰船核心已处于关闭状态，无需重复关闭")
			end
			return
		end

		if string.find(msg, "航点") or string.find(msg, "航路点") then
			speakerSpeak("如果要前往航点，请说 前往 （航点名称）。 目前不支持从语音设置航点。")
			return
		end

		if string.find(msg, "开启") then
			if(not core.enable()) then
				speakerSpeak("已开启舰船核心")
				shipOnOff()
			else
				speakerSpeak("舰船核心已处于开启状态，无需重复关闭")
			end
			return
		end

		if string.find(msg, "终止") or string.find(msg, "停") or string.find(msg, "取消") then
			if not checkWarpReady() then return end
			speakerSpeak("正在尝试终止...")
			shipOnOff()
			sleepFor(1)
			shipOnOff()
			speakerSpeak("已终止跃迁。")
			return
		end

		-- 其他关键词 --

		if string.find(msg, "帮助") or string.find(msg, "help") or string.find(msg, "怎么用") then
			speakerSpeak("您可以使用下列指令：")
			speakerSpeak("跃迁到 (x) (y) (z) - 前往一个指定的 x y z 坐标")
			speakerSpeak("跃迁 (前后) (上下) (左右) - 跃迁指定格数")
			speakerSpeak("前往 (航点名称) - 前往一个设置好的航点")
			speakerSpeak("开启核心/关闭核心 - 开关飞船核心")
			speakerSpeak("终止跃迁-停止当前进行的跃迁；超空间 - 进入/退出超空间")
			speakerSpeak("要更改称呼 " .. siriName .. " 的方式，请说 更名为 (新名字)")
			speakerSpeak("要更改舰船的名称，请说 修改船名为 (新名字)")
			return
		end

		if string.find(msg, "救命") then
			speakerSpeak("很抱歉， " .. siriName .. " 无法为您提供物质上的帮助。您可以查询mcmod等资料，或（在多人游戏）向其他玩家寻求帮助。")
			return
		end

		if string.find(msg, "自毁") then
			speakerSpeak("出于安全考虑，没有这种功能。")
			return
		end

		if string.find(msg, "重启") then
			speakerSpeak(siriName .. " 没有权限这样做。您可以手动重启电脑。")
			return
		end
		if string.find(msg, "来") then
			speakerSpeak(siriName .. " 并没有办法获取您的位置。您可以使用小地图或F3屏幕查找自己的位置，然后让 " .. siriName .. " 跃迁到对应的坐标。")
			return
		end

		if string.find(msg, "你好") or string.find(msg, "您好") then
			speakerSpeak("您好，有什么需要帮助吗？")
			return
		end

		if string.find(msg, "晚上好") or string.find(msg, "早上好") or string.find(msg, "中午好") or string.find(msg, "晚安") then
			if core.isInSpace() or core.isInHyperspace() then
				speakerSpeak("很抱歉，但是在太空里没有早上和晚上。")
			else
				local tmp = 0
				if string.find(msg, "晚上") then
					tmp = tmp + 1
				end
				if string.find(msg, "早") then
					tmp = tmp + 2
				end
				if string.find(msg, "中") then
					tmp = tmp + 4
				end
				if string.find(msg, "晚安") then
					tmp = tmp + 8
				end

				if(tmp == 1) then
					speakerSpeak("晚上好。")
				elseif (tmp == 2) then
					speakerSpeak("早上好。")
				elseif (tmp == 4) then
					speakerSpeak("中午好。")
				elseif (tmp == 8) then
					speakerSpeak("晚安。")
				else
					speakerSpeak(siriName .. " 不太确定您想表达什么。")
				end
			end
			return
		end

		if string.find(msg, "天气") then
			if(component.list("warpdriveEnvironmentalSensor")()) then
				local sensor = component.proxy(component.list("warpdriveEnvironmentalSensor")())

				local weatherAvailable, weather, change = sensor.getWeather();
				local timeAvailable, _, hour, min, _ = sensor.getWorldTime();
				local atmosAvailable, breathable, _ = sensor.getAtmosphere();
				local humidAvailable, _, humidity = sensor.getHumidity();
				local tempAvailable, _, temperature = sensor.getTemperature();

				if(not weatherAvailable or core.isInSpace() or core.isInHyperspace()) then
					if(breathable) then
						speakerSpeak("这里没有天气这一说法。")
						return
					else
						speakerSpeak("真空中大概没有天气这种东西。建议出门时带上氧气瓶。")
						return
					end
				end
				if(weather == "CLEAR") then
					if(change < 60 and change > 0) then
						speakerSpeak("天气很晴朗，但根据 " .. siriName .. " 的传感器分析，一会可能会下雨。")
					else
						if(hour > 6 and hour < 18) then
							speakerSpeak("天气很晴朗，阳光比较强烈。")
						else
							speakerSpeak("天气很晴朗，应该可以清楚地看到今晚的月光。")
						end
					end

					if(temperature < 0.0) then
						if(hour > 6 and hour < 18) then
							speakerSpeak("虽然外面天寒地冻..不过趁着天晴，出去活动一会也无妨。")
						else
							speakerSpeak("这样的天气大概可以欣赏到月光下的雪景。")
						end
					elseif (temperature < 0.3) then
						if(hour > 6 and hour < 18) then
							speakerSpeak("现在大概外面很凉快。")
						else
							speakerSpeak("不过，这个时候要去外面可能会有点冷了。")
						end
					elseif (temperature < 0.85) then
						if(humidity > 0.75) then
							if(hour > 6 and hour < 18) then
								speakerSpeak("外面可能有点潮湿，但应该依然是比较舒适的天气。")
							else
								speakerSpeak("现在没有阳光，外面蒸腾的水汽大概有所减少，出门比较合适。")
							end
						else
							if(hour > 6 and hour < 18) then
								speakerSpeak("温度正好，应该很适合出门。")
							else
								speakerSpeak("天气很适合出门，但不知道外面会不会有很多敌对生物。")
							end
						end
					else
						if(humidity > 0.5) then
							if(hour > 6 and hour < 18) then
								speakerSpeak("外面应该会十分闷热，可能会令人十分难受。出门小心中暑。")
							else
								speakerSpeak("虽然现在是晚上，但外面依然十分闷热。")
							end
						elseif(humidity < 0.1) then
							if(hour > 6 and hour < 18) then
								speakerSpeak("现在外面应该很热，并且十分干燥。")
							else
								speakerSpeak("在如此干燥炎热的地方，昼夜温差或许会十分大。")
							end
						else
							if(hour > 6 and hour < 18) then
								speakerSpeak("现在外面大概很热。")
							else
								speakerSpeak("虽然是晚上，但外面应该依然充斥着温热的空气。")
							end
						end
					end
					return
				elseif (weather == "RAIN" or weather == "SNOW") then
					if(humidity <= 0) then
						speakerSpeak("现在是阴天，但是干燥的地方大概很难有雨水。")
						return
					else
						if(change < 60 and change > 0) then
							if(temperature < 0) then
								speakerSpeak("现在正在下雪，但根据 " .. siriName .. " 的传感器分析，天气可能很快会有改变。")
							else
								speakerSpeak("现在正在下雨，但根据 " .. siriName .. " 的传感器分析，天气可能很快会有改变。")
							end
						else
							if(temperature < 0) then
								speakerSpeak("现在正在下雪。")
							elseif(temperature < 0.3) then
								speakerSpeak("现在正在下雨，但是高处有可能会在下雪。")
							else
								speakerSpeak("现在正在下雨。")
							end
						end
					end
					if(humidity > 0.7) then
						if(temperature > 0.8) then
							speakerSpeak("又湿又热...然后还下雨了。现在出门大概会有很糟糕的体验。")
						else
							speakerSpeak("这种潮湿的地方，下雨大概是很正常的。")
						end
					end
					if(temperature > 0.2 and temperature < 0.4) then
						speakerSpeak("这里的气温不高。被淋湿了大概会很冷。")
					end
					if(hour < 6 or hour > 18) then
						if (temperature > 0.2) then
							speakerSpeak("雨天的夜晚可能很危险……")
						elseif(temperature < 0) then
							speakerSpeak("雪天的夜晚通常是寂静的，但敌对生物可能会打破这片静寂。")
						end
					end
				elseif (weather == "THUNDER") then
					if(humidity <= 0) then
						speakerSpeak("黑云压城城欲摧...但是在这么干燥的群系中大概不会下雨了。")
						return
					else
						if(change < 60 and change > 0) then
							if(temperature < 0) then
								speakerSpeak("现在正在下暴雪，但根据 " .. siriName .. " 的传感器分析，天气可能很快会有改变。")
							else
								speakerSpeak("现在正在下暴雨，但根据 " .. siriName .. " 的传感器分析，天气可能很快会有改变。")
							end
						else
							if(temperature < 0) then
								speakerSpeak("现在正在下暴雪。")
							elseif(temperature < 0.3) then
								speakerSpeak("现在正在下暴雨，但是高处有可能会在下雪。")
							else
								speakerSpeak("现在正在下暴雨。请当心雷击危害。")
							end
						end
					end
					if(humidity > 0.7) then
						if(temperature > 0.8) then
							speakerSpeak("闷热，加上暴雨，这大概是最难受的天气了。")
						else
							speakerSpeak("原本就潮湿的地方，下暴雨之后就更潮湿了。")
						end
					end
					if(temperature > 0.2 and temperature < 0.4) then
						speakerSpeak("这里的气温不高。被淋湿了大概会很冷。")
					end
					if(hour < 6 or hour > 18) then
						if (temperature > 0.2) then
							speakerSpeak("下暴雨的夜晚通常是漆黑一片的，只能听到窗外的雨声，只有不时划过天空的闪电照亮这片黑暗。")
						elseif(temperature < 0) then
							speakerSpeak("暴雪挡住了唯一的月光，这样的天气下或许出门不是个好主意。")
						end
					end
				end
			else
				speakerSpeak("把一个环境传感器连接到电脑上可以让 " .. siriName .. " 更好的知道天气是怎样的。")
			end
			return
		end

		speakerSpeak("无法识别该指令。有什么别的需要帮助的事情吗？")
		return
	end
end
end

-- 添加AR的显示条目
local AR_Position_Title = nil
local AR_Pos_X = nil;
local AR_Pos_Y = nil;
local AR_Pos_Z = nil;

local AR_Movement_Title = nil
local AR_Move_Fwd = nil
local AR_Move_Up = nil
local AR_Move_Right = nil

local AR_Result_Title = nil
local AR_Result_X = nil
local AR_Result_Y = nil
local AR_Result_Z = nil

local AR_Energy = nil;
local AR_Core_Enable = nil;

local AR_Connected = nil;

if(AR) then
	AR_Position_Title = ARAddText("===当前位置===", 3, 0, 1, 0, 0.75)
	sleepFor(0.05)
	local curX, curY, curZ = core.getLocalPosition()
	AR_Pos_X = ARAddText("X: " .. curX, 4, 0, 1, 0, 0.75)
	sleepFor(0.05)
	AR_Pos_Y = ARAddText("Y: " .. curY, 5, 0, 1, 0, 0.75)
	sleepFor(0.05)
	AR_Pos_Z = ARAddText("Z: " .. curZ, 6, 0, 1, 0, 0.75)
	sleepFor(0.1)

	local cur, max, unit = core.getEnergyStatus()
	AR_Energy = ARAddText("核心能量: " .. cur .. "/" .. max .. unit, 1, 0, 1, 0, 0.75)
	sleepFor(0.1)
	if(core.enable()) then
		AR_Core_Enable = ARAddText("核心已开启", 0, 0, 1, 0, 0.75)
	else
		AR_Core_Enable = ARAddText("核心已关闭", 0, 1, 0, 0, 0.75)
	end

	sleepFor(0.1)
	AR_Movement_Title = ARAddText("===相对跃迁位置===", 8, 0, 1, 0, 0.75)
	sleepFor(0.05)
	local fwd, u, r = core.movement()
	AR_Move_Fwd = ARAddText("前后: " .. fwd, 9, 0, 1, 0, 0.75)
	sleepFor(0.05)
	AR_Move_Up = ARAddText("上下: " .. u, 10, 0, 1, 0, 0.75)
	sleepFor(0.05)
	AR_Move_Right = ARAddText("左右: " .. r, 11, 0, 1, 0, 0.75)
	sleepFor(0.1)

	AR_Result_Title = ARAddText("===跃迁目标位置===", 13, 0, 1, 0, 0.75)
	local dx, dy, dz = core.getOrientation()
	if(dx == nil) then
		dx, dy, dz = 0, 0, 0
	end
	local tgtX, tgtY, tgtZ = 0, 0, 0
	if(dz == 1) then -- 朝向Z正方向 (前=+z，后=-Z，左=+x，右=-X)
		tgtZ = curZ + fwd
		tgtX = curX - r
	end
	if(dz == -1) then -- 朝向Z负方向 (前=-z，后=+Z，左=-x，右=+X)
		tgtZ = curZ - fwd
		tgtX = curX + r
	end
	if(dx == 1) then -- X正方向 (前=+x，后=-x，左=-z，右=+z)
		tgtX = curX + fwd
		tgtZ = curZ + r
	end
	if(dx == -1) then -- X负方向 (前=-x，后=-x，左=+z，右=-z)
		tgtX = curX - fwd
		tgtZ = curZ - r
	end
	tgtY = curY + u
	sleepFor(0.05)
	AR_Result_X = ARAddText("X: " .. tgtX, 14, 0, 1, 0, 0.75)
	sleepFor(0.05)
	AR_Result_Y = ARAddText("Y: " .. tgtY, 15, 0, 1, 0, 0.75)
	sleepFor(0.05)
	AR_Result_Z = ARAddText("Z: " .. tgtZ, 16, 0, 1, 0, 0.75)
	sleepFor(0.05)
	AR_Connected = ARAddText("已连接... |", 18, 0, 1, 0, 0.75)
end

local AR_Update_Step = 0
local lastARUpdate = computer.uptime();
local function updateAR()
	if not AR then return end
	if (AR_Position_Title == nil) or (AR_Pos_X == nil) or (AR_Pos_Y == nil)
	or (AR_Pos_Z == nil) or (AR_Movement_Title == nil) or (AR_Move_Fwd == nil)
	or (AR_Move_Up == nil) or (AR_Move_Right == nil) or (AR_Result_Title == nil)
	or (AR_Result_X == nil) or (AR_Result_Y == nil) or (AR_Result_Z == nil)
	or (AR_Energy == nil) or (AR_Core_Enable == nil) then return end
	if(computer.uptime() - lastARUpdate < 0.1) then return end
	lastARUpdate = computer.uptime()
	
	local curX, curY, curZ = core.getLocalPosition()
	local cur, max, unit = core.getEnergyStatus()
	local dx, dy, dz = core.getOrientation()
	local fwd, u, r = core.movement()
	if(dx == nil) then
		dx, dy, dz = 0, 0, 0
	end
	local tgtX, tgtY, tgtZ = 0, 0, 0
	if(dz == 1) then -- 朝向Z正方向 (前=+z，后=-Z，左=+x，右=-X)
		tgtZ = curZ + fwd
		tgtX = curX - r
	end
	if(dz == -1) then -- 朝向Z负方向 (前=-z，后=+Z，左=-x，右=+X)
		tgtZ = curZ - fwd
		tgtX = curX + r
	end
	if(dx == 1) then -- X正方向 (前=+x，后=-x，左=-z，右=+z)
		tgtX = curX + fwd
		tgtZ = curZ + r
	end
	if(dx == -1) then -- X负方向 (前=-x，后=-x，左=+z，右=-z)
		tgtX = curX - fwd
		tgtZ = curZ - r
	end

	tgtY = curY + u

	if(AR_Update_Step == 0) then
		AR_Connected.setText("已连接... |")

		AR_Position_Title = ARSetText("===当前位置===", AR_Position_Title, 0, 1, 0, 0.75)
		AR_Pos_X = ARSetText("X: " .. curX, AR_Pos_X, 0, 1, 0, 0.75)
		AR_Pos_Y = ARSetText("Y: " .. curY, AR_Pos_Y, 0, 1, 0, 0.75)
		AR_Pos_Z = ARSetText("Z: " .. curZ, AR_Pos_Z, 0, 1, 0, 0.75)

	end
	if(AR_Update_Step == 1) then
		AR_Connected.setText("已连接... /")


		AR_Movement_Title = ARSetText("===相对跃迁位置===", AR_Movement_Title, 0, 1, 0, 0.75)
		AR_Move_Fwd = ARSetText("前后: " .. fwd, AR_Move_Fwd, 0, 1, 0, 0.75)
		AR_Move_Up = ARSetText("上下: " .. u, AR_Move_Up, 0, 1, 0, 0.75)
		AR_Move_Right = ARSetText("左右: " .. r, AR_Move_Right, 0, 1, 0, 0.75)

	end
	if(AR_Update_Step == 2) then
		AR_Connected.setText("已连接... -")
	
		AR_Result_Title = ARSetText("===跃迁目标位置===", AR_Result_Title, 0, 1, 0, 0.75)
		AR_Result_X = ARSetText("X: " .. tgtX, AR_Result_X, 0, 1, 0, 0.75)
		AR_Result_Y = ARSetText("Y: " .. tgtY, AR_Result_Y, 0, 1, 0, 0.75)
		AR_Result_Z = ARSetText("Z: " .. tgtZ, AR_Result_Z, 0, 1, 0, 0.75)
	end
	if(AR_Update_Step == 3) then
		AR_Connected.setText("已连接... \\")
		
		AR_Energy = ARSetText("核心能量: " .. cur .. "/" .. max .. unit, AR_Energy, 0, 1, 0, 0.75)
		sleepFor(0.1)
		if(core.enable()) then
			AR_Core_Enable = ARSetText("核心已开启", AR_Core_Enable, 0, 1, 0, 0.75)
		else
			AR_Core_Enable = ARSetText("核心已关闭", AR_Core_Enable, 1, 0, 0, 0.75)
		end
	end
	AR_Update_Step = AR_Update_Step + 1
	if(AR_Update_Step == 4) then
		AR_Update_Step = 0
	end
end

if(siri and siriout) then
	siri.name(siriName)
	speakerSpeak("程序启动成功，可以使用语音指令（请使用\"".. siriName .. "\"作为消息前缀）")
	speakerSpeak("例如：".. siriName .. "，跃迁到 100 200 300")
	local success = core.getAssemblyStatus()
	if(not success) then
		speakerSpeak("提示：您可能需要首先设置舰船尺寸。请查看电脑屏幕。")
	end
end

ARRemoveText(AR_Initializing_Text);

while(running) do
	pcall(updateSiri)
	pcall(updateAR)
	if(refresh_gpu()) then
		w1:setNextDrawForced()
	end
	xpcall(processEvent, function(err) print(err) end)
	if(refresh_gpu()) then
		w1:setNextDrawForced()
	end
	xpcall(draw, function(err) print(err) end)
end

savedData = {}
savedData.siriName = siriName;
savedData.abs_x = 		tbox_jump_x:getText();
savedData.abs_y = 		tbox_jump_y:getText();
savedData.abs_z = 		tbox_jump_z:getText();
savedData.rel_fwd = 	tbox_jump_fwd:getText();
savedData.rel_right= 	tbox_jump_right:getText();
savedData.rel_up = 		tbox_jump_up:getText();
savedData.rotate = 		tbox_jump_rotate:getText();
putTable(savedData, "/home/warpdrive_control_save.dat")

if(AR) then
	AR.removeAll();
end

gpu.setResolution(gpu.maxResolution())
gpu.setViewport(gpu.maxResolution())
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
gpu.fill(0, 0, 999, 999, " ")