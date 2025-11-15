--| Index | Unit | Defined as |
--| :--- | :--- | :--- |
--| 0 | Raw unit \(no unit\) | UNIT\_RAW |
--| 1 | Volts | UNIT\_VOLTS |
--| 2 | Amps | UNIT\_AMPS |
--| 3 | Milliamps | UNIT\_MILLIAMPS |
--| 4 | Knots | UNIT\_KTS |
--| 5 | Meters per Second | UNIT\_METERS\_PER\_SECOND |
--| 6 | Feet per Second | UNIT\_FEET\_PER\_SECOND |
--| 7 | Kilometers per Hour | UNIT\_KMH |
--| 8 | Miles per Hour | UNIT\_MPH |
--| 9 | Meters | UNIT\_METERS |
--| 10 | Feet | UNIT\_FEET |
--| 11 | Degrees Celsius | UNIT\_CELSIUS |
--| 12 | Degrees Fahrenheit | UNIT\_FAHRENHEIT |
--| 13 | Percent | UNIT\_PERCENT |
--| 14 | Milliamp Hour | UNIT\_MAH |
--| 15 | Watts | UNIT\_WATTS |
--| 16 | Milliwatts | UNIT\_MILLIWATTS |
--| 17 | dB | UNIT\_DB |
--| 18 | RPM | UNIT\_RPMS |
--| 19 | G | UNIT\_G |
--| 20 | Degrees | UNIT\_DEGREE |
--| 21 | Radians | UNIT\_RADIANS |
--| 22 | Milliliters | UNIT\_MILLILITERS |
--| 23 | Fluid Ounces | UNIT\_FLOZ |
--| 24 | Ml per minute | UNIT\_MILLILITERS\_PER\_MINUTE |
--| 35 | Hours | UNIT\_HOURS |
--| 36 | Minutes | UNIT\_MINUTES |
--| 37 | Seconds | UNIT\_SECONDS |
--| 38 | Virtual unit | UNIT\_CELLS |
--| 39 | Virtual unit | UNIT\_DATETIME |
--| 40 | Virtual unit | UNIT\_GPS |
--| 41 | Virtual unit | UNIT\_BITFIELD |
--| 42 | Virtual unit | UNIT\_TEXT |

local lat = 0
local lon = 0
local alt = 0
local speed = 0

local home = bitmap.open("/SCRIPTS/TOOLS/home.png")
local YGTECH_HUD_Path = "/SCRIPTS/TOOLS/YGTECH-HUD.txt"

local time = getTime()
local time_old = getTime()
local time_old2 = getTime()
local fps = 0
local fps_temp = 0
local ver = {}
local radio = {}
local maj
local minor
local rev
local osname ={}

local hx  
local hy
local lx  -- 临时变量
local ly
local qx
local qy
local q3x

local second = 0
local modelInfo -- 模型信息

local STATUS_BAR_COLOR = lcd.RGB(30,30,30)
local MAP_BG_COLOR = lcd.RGB(6, 93, 13)
local MAP_LINE_COLOR = lcd.RGB( 90 ,90,90)
local BAR_COLOR    =  lcd.RGB(30,30,30)
local HUD_SKY_COLOR = lcd.RGB(0, 136, 200) 
local HUD_GROUND_COLOR = lcd.RGB(160, 95, 14) 
local CUT_COLOR = lcd.RGB(60,60,60) -- 分隔线颜色
local SETUP_COLOR = lcd.RGB(50,50,50)
local FONT_COLOR = WHITE

local ID_5006_hz = 0
local ID_5006_temp = 0
local CRSF_FRAME_CUSTOM_TELEM = 0x80
local CRSF_FRAME_CUSTOM_TELEM_LEGACY = 0x7F
local CRSF_CUSTOM_TELEM_PASSTHROUGH = 0xF0
local CRSF_CUSTOM_TELEM_STATUS_TEXT = 0xF1
local CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY = 0xF2
local roll = 0
local pitch = 0
local yaw = 0
local screenshot_enable = 1

local param_edit = 0
local setup_x = 0
local setup_y = 0
local setup_y_temp = 0
local setup_y_max = -200
local touch_slide_flag = 0
local touch_x_old = 0
local touch_y_old = 0
local home_fixed = 0
local RC_linked = 0
local setup_status={0,0,0,0}

local write= {}
local read_num = 0

local function save_init()
	local seq = 0 
	for seq = 1 ,20 do
		write[seq*10+1]= 0
		write[seq*10+2]= 0
		write[seq*10+3]= 0
		write[seq*10+4]= 0
		write[seq*10+5]= 0
		write[seq*10+6]= 0
		write[seq*10+7]= 0
		write[seq*10+8]= 0
		write[seq*10+9]= 0
		write[seq*10+10]= 0
	end
end


local function save(seq,value)
	local i
	if seq > 20 then 
		return 0
	end
	seq = seq - 1
	local f = io.open(YGTECH_HUD_Path, "r")
	if f == nil then
		return 0
	end	
	local buf = {}	
	write = io.read(f, 200) -- 先读取所有数据长度
	buf = string.format("%10d", value)
	local write_buf = string.sub(write, 1, seq*10) .. buf .. string.sub(write, seq*10+11)
	local f = io.open(YGTECH_HUD_Path, "w")
	io.write(f, write_buf)
	io.close(f)
end

local function read(seq)
	if seq > 20 then 
		return 0
	end	
	seq = seq - 1
	local f = io.open(YGTECH_HUD_Path, "r")
	if f == nil then
		return 0
	end
	local buf = {}
	local read_buf = {}
	read_buf = io.read(f, 200)
	buf = string.sub(read_buf, seq*10+1, seq*10+10)  -- 读取第N到N+4共5个字符
	local result = tonumber(buf)
	io.close(f)
	return result
end

local ver_num = {}
local function VER()  -- 获取EdgeTX系统版本信息
	ver, radio, maj, minor, rev, osname = getVersion()
	local ver_num_i = 1
	for num in string.gmatch(ver,"%d+") do
		ver_num[ver_num_i] = num
		ver_num_i = ver_num_i + 1
	end
	return 0
end

local first = 0

local function load_param()
	first = read (5)
	if first ~= 2 then 
		first = 2
		save(5,first)
		save(1,0)
		save(2,0)
		save(3,0)
		save(4,0)
		save(10,HUD_SKY_COLOR)
		save(11,HUD_GROUND_COLOR)
		save(12,MAP_BG_COLOR)
		save(13,FONT_COLOR)
		save(14,BAR_COLOR)
		save(16,screenshot_enable)
	end
	setup_status[1]=read(1)
	if setup_status[1]~= 0 and setup_status[1] ~= 1 then setup_status[1] = 0 end
	setup_status[2]=read(2)
	if setup_status[2]~= 0 and setup_status[2] ~= 1 then setup_status[2] = 0 end
	setup_status[3]=read(3)
	if setup_status[3]~= 0 and setup_status[3] ~= 1 then setup_status[3] = 0 end
	setup_status[4]=read(4)
	if setup_status[4]~= 0 and setup_status[4] ~= 1 then setup_status[4] = 0 end
	HUD_SKY_COLOR = read(10)
	HUD_GROUND_COLOR = read(11)
	MAP_BG_COLOR = read(12)
	FONT_COLOR = read(13)
	BAR_COLOR = read(14)
	screenshot_enable=read(16)
end

-- Init 初始化
local function init()
	VER()
	hx = LCD_W / 2
	hy = LCD_H / 2 + 20
	lx = LCD_W
	ly = LCD_H
	qx = lx/4
	qy = (ly-40)/4+40
	q3x	 = hx + qx
	modelInfo = model.getInfo() -- read model's info table
	save_init()
	load_param()
end

local function len( t )
	if t<0 then t=-t end
	if(t>999999999)then 
		return 10
	elseif(t>99999999)then 
		return 9
	elseif(t>9999999)then 
		return 8
	elseif(t>999999)then 
		return 7
	elseif(t>99999)then 
		return 6
	elseif(t>9999)then 
		return 5
	elseif(t>999)then 
		return 4
	elseif(t>99)then 
		return 3
	elseif(t>9)then 
		return 2
	else 
		return 1
	end
end

local packetStats = {
  [0x5000] = {count = 0, avg = 0 , tot = 0},
  [0x5001] = {count = 0, avg = 0 , tot = 0},
  [0x5002] = {count = 0, avg = 0 , tot = 0},
  [0x5003] = {count = 0, avg = 0 , tot = 0},
  [0x5004] = {count = 0, avg = 0 , tot = 0},
  [0x5005] = {count = 0, avg = 0 , tot = 0},
  [0x5006] = {count = 0, avg = 0 , tot = 0},
  [0x5007] = {count = 0, avg = 0 , tot = 0},
  [0x5008] = {count = 0, avg = 0 , tot = 0},
  [0x5009] = {count = 0, avg = 0 , tot = 0},
  [0x500A] = {count = 0, avg = 0 , tot = 0},
  [0x500B] = {count = 0, avg = 0 , tot = 0},
  [0x500C] = {count = 0, avg = 0 , tot = 0},
  [0x500D] = {count = 0, avg = 0 , tot = 0},
  link_rate = 0
}

local function processTelemetry(data_id, value)
  if value ~= nil then
    if data_id == 0x5006 then -- ROLLPITCH
		ID_5006_temp = ID_5006_temp + 1		
		-- roll [0,1800] ==> [-180,180]
		roll = (math.min(bit32.extract(value,0,11),1800) - 900) * 0.2
		-- pitch [0,900] ==> [-90,90]
		pitch = (math.min(bit32.extract(value,11,10),900) - 450) * 0.2
		-- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
		local range = bit32.extract(VALUE,22,10) * (10^bit32.extract(value,21,1)) -- cm
--      pushMessage(string.format("roll:%d pitch:%d", roll, pitch))
    end
  end
  if packetStats[data_id] ~= nil then
    packetStats[data_id].tot = packetStats[data_id].tot + 1
    packetStats[data_id].count = packetStats[data_id].count + 1
  end
--  io.write(logfile, getTime(), ";0;", data_id, ";", value, "\r\n")
end

local function crossfirePop()
    local command, data = crossfireTelemetryPop()
    -- command is 0x80 CRSF_FRAMETYPE_ARDUPILOT
    if (command == CRSF_FRAME_CUSTOM_TELEM or command == CRSF_FRAME_CUSTOM_TELEM_LEGACY)  and data ~= nil then
      -- actual payload starts at data[2]
      if #data >= 7 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH then
        local app_id = bit32.lshift(data[3],8) + data[2]
        local value =  bit32.lshift(data[7],24) + bit32.lshift(data[6],16) + bit32.lshift(data[5],8) + data[4]
        return 0x00, 0x10, app_id, value
      elseif #data > 4 and data[1] == CRSF_CUSTOM_TELEM_STATUS_TEXT then
        return 0x00, 0x10, 0x5000, 0x00000000
      elseif #data >= 8 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY then
        -- passthrough array
        local app_id, value
        for i=0,math.min(data[2]-1, 9)
        do
          app_id = bit32.lshift(data[4+(6*i)],8) + data[3+(6*i)]
          value =  bit32.lshift(data[8+(6*i)],24) + bit32.lshift(data[7+(6*i)],16) + bit32.lshift(data[6+(6*i)],8) + data[5+(6*i)]
          --pushMessage(7,string.format("CRSF:%d - %04X:%08X",i, app_id, value))
          processTelemetry(app_id, value)
        end
      end
    end
    return nil, nil ,nil ,nil
end

local function XUI_bar_inv (x0,y0,dx,dy,r,color)
	local a
	local b
	local di
	local x
	local y
	x = dx - r
	y = dy - r
	a=0
	b=r 
	di = 3 - ( r * 2 )            
	while a<=b do	
		lcd.drawLine(x0+a+x,y0-dy,x0+a+x,y0-b-y,SOLID,color)
		lcd.drawLine(x0+a+x,y0+b+y,x0+a+x,y0+dy,SOLID,color)
		lcd.drawLine(x0+b+x,y0-dy,x0+b+x,y0-a-y,SOLID,color)
		lcd.drawLine(x0+b+x,y0+a+y,x0+b+x,y0+dy,SOLID,color)
		lcd.drawLine(x0-a-x,y0-dy,x0-a-x,y0-b-y,SOLID,color)
		lcd.drawLine(x0-a-x,y0+b+y,x0-a-x,y0+dy,SOLID,color)
		lcd.drawLine(x0-b-x,y0-dy,x0-b-x,y0-a-y,SOLID,color)
		lcd.drawLine(x0-b-x,y0+a+y,x0-b-x,y0+dy,SOLID,color)
		a=a+1
		if di < 0 then
			di = di+ 4 * a + 6   
		else		
			di=di+10+4*(a-b)
			b=b-1
		end						    
	end
end

local function XUI_bar( x0, y0, dx, dy, r, color)
	local a
	local b
	local di
	local x
	local y
	x = dx - r
	y = dy - r
	a=0
	b=r 
	di = 3 - ( r * 2 )            
	while a<=b do	
		lcd.drawLine(x0+a+x,y0-b-y,x0+a+x,y0+b+y,SOLID,color)
		lcd.drawLine(x0+b+x,y0-a-y,x0+b+x,y0+a+y,SOLID,color)
		lcd.drawLine(x0-a-x,y0-b-y,x0-a-x,y0+b+y,SOLID,color)
		lcd.drawLine(x0-b-x,y0-a-y,x0-b-x,y0+a+y,SOLID,color) 
		a=a+1
		if di < 0 then
			di = di+ 4 * a + 6   
		else		
			di=di+10+4*(a-b)
			b=b-1
		end						    
	end
	lcd.drawFilledRectangle(x0-x,y0-dy,x*2+1,dy*2+1, color)
end

local function XUI_bar0( x0, y0, dx, dy, r, color)
	local a
	local b
	local di
	local x
	local y
	x = dx - r
	y = dy - r
	a=0
	b=r 
	di = 3 - ( r * 2 )            
	while a<=b do	
		lcd.drawPoint(x0+a+x,y0-b-y,color)
 		lcd.drawPoint(x0+b+x,y0-a-y,color)       
		lcd.drawPoint(x0+b+x,y0+a+y,color)         
		lcd.drawPoint(x0+a+x,y0+b+y,color)
		lcd.drawPoint(x0-a-x,y0+b+y,color)  
 		lcd.drawPoint(x0-b-x,y0+a+y,color)           
		lcd.drawPoint(x0-a-x,y0-b-y,color)     
		lcd.drawPoint(x0-b-x,y0-a-y,color)		
		a=a+1
		if di < 0 then
			di = di+ 4 * a + 6   
		else		
			di=di+10+4*(a-b)
			b=b-1
		end						    
	end
	lcd.drawLine(x0-x,y0-dy,x0+x,y0-dy,SOLID,color)
	lcd.drawLine(x0-x,y0+dy,x0+x,y0+dy,SOLID,color)
	lcd.drawLine(x0-dx,y0-y,x0-dx,y0+y,SOLID,color)
	lcd.drawLine(x0+dx,y0-y,x0+dx,y0+y,SOLID,color)
end

local function channel(cx,cy,dx,dy,r,dir,value,color1,color2)
	local pos
	local num = -(1500-value)*100/512 
	XUI_bar0(cx,cy,dx,dy,r,color1)	
	value = 3000 - value
	if value >= 1490 and value <= 1510 then
		if dir == 1 then
			XUI_bar0(cx,cy,r-2,dy-2,r-2,color2)
		else 
			XUI_bar0(cx,cy,dx-2,r-2,r-2,color2)
		end				
	else 
		if value < 1490 then
			if dir == 1 then  -- 水平
				pos = cx-r + 2 - (dx -r )* (1500-value) / 512
				XUI_bar((cx+r-2+pos)/2,cy,(cx+r-2-pos)/2,dy-2,r-2,color2)	-- 左半边  		 cx-dx    cx    cx+dx	
			elseif dir == 0  then -- 垂直                           --               988     1500    2012
				pos = cy-r + 2 - (dy -r )* (1500-value) / 512
				XUI_bar(cx,(cy+r-2+pos)/2,dx-2,(cy+r-2-pos)/2,r-2,color2)	-- 上半边  		 cx-dx    cx    cx+dx								
			end
			
		elseif value >1510 then
			if dir == 1 then  -- 水平
				pos = cx+r-2 + (dx -r )* (value-1500) / 512
				XUI_bar((cx-r+2+pos)/2,cy,(pos-cx+r-2)/2,dy-2,r-2,color2)
			elseif dir == 0 then -- 垂直
				pos = cy+r-2 + (dy -r )* (value-1500) / 512
				XUI_bar(cx,(cy-r+2+pos)/2,dx-2,(pos-cy+r-2)/2,r-2,color2)								
			end	
		end
	end
	if num>-1 and num < 10 then
		lcd.drawNumber(cx-3, cy+dy+1, num, SMLSIZE + color1 )
	elseif num>-1 and num < 100 then
		lcd.drawNumber(cx-6, cy+dy+1, num, SMLSIZE + color1 )
	elseif num == 100 then
		lcd.drawNumber(cx-9, cy+dy+1, num, SMLSIZE + color1 )			
	elseif num > -10 then
		lcd.drawNumber(cx-8, cy+dy+1, num, SMLSIZE + color1 )
	elseif num > -100 then
		lcd.drawNumber(cx-11, cy+dy+1, num, SMLSIZE + color1 )		
	elseif num == -100 then
		lcd.drawNumber(cx-14, cy+dy+1, num, SMLSIZE + color1 )		
	end
end

local hud_mode = 0
local srcoll_index={1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000}
local home_x = 0
local home_y = 0
local x_center = 0
local y_center = 0

-- 计算x1,y1围绕x_center,y_center旋转yaw角度
local function point_roll(x1,y1,roll)
	local x=0
	local y=0
	local x0=x_center
	local y0=y_center
	roll=roll +180
	x=x0+math.cos(math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))	+roll*math.pi/180)*math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))
	if y1>y0 then
		y=y0+math.sin(math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180)*math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))	
	else 
		y=y0+math.sin(math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180)*math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))		
	end
	return x,y
end

-- 绘制飞机位置
local function draw_plane( yaw )
	local lon1 = lon
	local lon2 = home_x
	local lat1 = lat
	local lat2 = home_y
	local dx = 0
	local dy = 0
	local x_point = {0,0,0}
	local y_point = {0,0,0}
	local posx = 0
	local posy = 0
	local scroll = 0
	local map_dis = 0
	local i = 0
	dx = 111000 * ( lon1 - lon2 ) * math.cos ( ( lat1 + lat2 ) * math.pi / 360 )
	dy = 111000 * ( lat1 -lat2 )
	if math.abs(dx) > math.abs(dy) then	
		local temp
		i= 1
		while i < 20 do	
			temp = dx / srcoll_index [ i ] * 60 / 100
			if math.abs ( temp ) <= ( hx - 20 )   then break end
			i = i + 1
		end	
		scroll = i
		posx = temp + hx 
		temp = dy / srcoll_index [ scroll ] * 60 / 100
		posy = hy - temp	
	else
		local temp
		i = 1
		while i < 20 do	
			temp = dy * 60 / srcoll_index [ i ] / 100
			if math.abs ( temp ) <= ( hy - 20 ) then break end
			i = i + 1
		end
		scroll = i
		posy = hy - temp
		temp = dx * 60 / srcoll_index [ scroll ] / 100
		posx = temp + hx
	end	
	map_dis = srcoll_index [ scroll ] * 100
	--lcd.drawNumber(460, 300, scroll, BOLD + RED )
	if map_dis<10000 then
		lcd.drawNumber(hx-60-len(map_dis)*4,hy-6,map_dis, SMLSIZE + lcd.RGB(120,120,120))
		lcd.drawNumber(hx-120-len(map_dis*2)*4,hy-6,map_dis*2, SMLSIZE + lcd.RGB(120,120,120))
		lcd.drawNumber(hx-180-len(map_dis*3)*4,hy-6,map_dis*3, SMLSIZE + lcd.RGB(120,120,120))	
		lcd.drawNumber(hx+60-len(map_dis)*4,hy-6,map_dis, SMLSIZE + lcd.RGB(120,120,120))
		lcd.drawNumber(hx+120-len(map_dis*2)*4,hy-6,map_dis*2, SMLSIZE + lcd.RGB(120,120,120))
		lcd.drawNumber(hx+180-len(map_dis*3)*4,hy-6,map_dis*3, SMLSIZE + lcd.RGB(120,120,120))		
		lcd.drawNumber(hx-len(map_dis)*4,hy-6-60,map_dis, SMLSIZE + lcd.RGB(120,120,120))
		lcd.drawNumber(hx-len(map_dis*2)*4,hy-6-120,map_dis*2, SMLSIZE + lcd.RGB(120,120,120))
		lcd.drawNumber(hx-len(map_dis)*4,hy-6+60,map_dis, SMLSIZE + lcd.RGB(120,120,120))
	end
	x_center = posx
	y_center = posy	
	x_point[1],y_point[1] = point_roll(posx,posy-5,math.tointeger(yaw+180))
	x_point[2],y_point[2] = point_roll(posx,posy+12,math.tointeger(yaw))
	x_point[3],y_point[3] = point_roll(posx-10,posy-12,math.tointeger(yaw+180))	
	lcd.drawFilledTriangle(x_point[1],y_point[1],x_point[2],y_point[2] ,x_point[3],y_point[3] ,BAR_COLOR)
	x_point[1],y_point[1] = point_roll(posx,posy-5,math.tointeger(yaw+180))
	x_point[2],y_point[2] = point_roll(posx,posy+12,math.tointeger(yaw))
	x_point[3],y_point[3] = point_roll(posx+10,posy-12,math.tointeger(yaw+180))	
	lcd.drawFilledTriangle(x_point[1],y_point[1],x_point[2],y_point[2] ,x_point[3],y_point[3] ,BAR_COLOR)
end

local exitscript = 0  -- 退出脚本标志 0不退出 1退出
local hud_size = 2   -- hud作为右下角窗口的大小
local old_pitch = 0  
local old_rool = 0
local hud_distance = 0

-- 绘制飞机位置
local function draw_plane2( yaw )
	local lon1 = lon
	local lon2 = home_x
	local lat1 = lat
	local lat2 = home_y
	local dx = 0
	local dy = 0
	local x_point = {0,0,0}
	local y_point = {0,0,0}
	local posx = 0
	local posy = 0
	local scroll = 0
	local map_dis = 0
	local i = 0
	local cx = (hud_size+1)*15
	local cy = ly - (hud_size+1)*15
	local hf = (hud_size+1)*15
	local df = (hud_size+1)*30
	dx = 111000 * ( lon1 - lon2 ) * math.cos ( ( lat1 + lat2 ) * math.pi / 360 )
	dy = 111000 * ( lat1 -lat2 )
	if math.abs(dx) > math.abs(dy) then	
		local temp
		i= 1
		while i < 20 do	
			temp = dx / srcoll_index [ i ] *  hf / 100
			if math.abs ( temp ) <= ( hf -(hud_size+1)*2 )   then break end
			i = i + 1
		end	
		scroll = i
		posx = temp + cx 
		temp = dy / srcoll_index [ scroll ] *  hf / 100
		posy = cy - temp	
	else
		local temp
		i = 1
		while i < 20 do	
			temp = dy *  hf / srcoll_index [ i ] / 100
			if math.abs ( temp ) <= ( hf - (hud_size+1)*2 ) then break end
			i = i + 1
		end
		scroll = i
		posy = cy - temp
		temp = dx *hf / srcoll_index [ scroll ] / 100
		posx = temp + cx
	end	
	map_dis = srcoll_index [ scroll ] * 100
	x_center = posx
	y_center = posy	
	-- 1  2  3    60  90  120
	lcd.drawBitmap(home, cx- 50 * (hud_size+1)*7/100 , cy- 43 * (hud_size+1)*7 /100, (hud_size+1)*7 ) -- 显示图片,参数:文件名,x坐标,y坐标,放大倍率:100为原始大小
	x_point[1],y_point[1] = point_roll(posx,posy-5*(hud_size+1)/4,math.tointeger(yaw+180))
	x_point[2],y_point[2] = point_roll(posx,posy+12*(hud_size+1)/4,math.tointeger(yaw))
	x_point[3],y_point[3] = point_roll(posx-10*(hud_size+1)/4,posy-12*(hud_size+1)/4,math.tointeger(yaw+180))	
	lcd.drawFilledTriangle(x_point[1],y_point[1],x_point[2],y_point[2] ,x_point[3],y_point[3] ,BAR_COLOR)
	x_point[1],y_point[1] = point_roll(posx,posy-5*(hud_size+1)/4,math.tointeger(yaw+180))
	x_point[2],y_point[2] = point_roll(posx,posy+12*(hud_size+1)/4,math.tointeger(yaw))
	x_point[3],y_point[3] = point_roll(posx+10*(hud_size+1)/4,posy-12*(hud_size+1)/4,math.tointeger(yaw+180))	
	lcd.drawFilledTriangle(x_point[1],y_point[1],x_point[2],y_point[2] ,x_point[3],y_point[3] ,BAR_COLOR)
end

-- 绘制飞机位置
local function draw_plane3( yaw )
	local lon1 = lon
	local lon2 = home_x
	local lat1 = lat
	local lat2 = home_y
	local dx = 0
	local dy = 0
	local x_point = {0,0,0}
	local y_point = {0,0,0}
	local posx = 0
	local posy = 0
	local scroll = 0
	local map_dis = 0
	local i = 0
	local cx = hx + qx
	local cy = qy
	local hf = qx
	local df = qy
	local size  =  3
	dx = 111000 * ( lon1 - lon2 ) * math.cos ( ( lat1 + lat2 ) * math.pi / 360 )
	dy = 111000 * ( lat1 -lat2 )
	if math.abs(dx) > math.abs(dy) then	
		local temp
		i= 1
		while i < 20 do	
			temp = dx / srcoll_index [ i ] *  50 / 100
			if math.abs ( temp ) <= ( hf -(size+1)*2 )   then break end
			i = i + 1
		end	
		scroll = i
		posx = temp + cx 
		temp = dy / srcoll_index [ scroll ] *  50 / 100
		posy = cy - temp	
	else
		local temp
		i = 1
		while i < 20 do	
			temp = dy *  50 / srcoll_index [ i ] / 100
			if math.abs ( temp ) <= ( hf - (size+1)*2 ) then break end
			i = i + 1
		end
		scroll = i
		posy = cy - temp
		temp = dx *50 / srcoll_index [ scroll ] / 100
		posx = temp + cx
	end	
	map_dis = srcoll_index [ scroll ] * 100
	x_center = posx
	y_center = posy	
	-- 1  2  3    60  90  120
	lcd.drawBitmap(home, cx- 50 * (size+1)*7/100 , cy- 43 * (size+1)*7 /100, (size+1)*7 ) -- 显示图片,参数:文件名,x坐标,y坐标,放大倍率:100为原始大小
	if map_dis<10000 then
		lcd.drawNumber(q3x-50-len(map_dis)*4,qy-8,map_dis, SMLSIZE + lcd.RGB(120,120,120))
		lcd.drawNumber(q3x+50-len(map_dis)*4,qy-8,map_dis, SMLSIZE + lcd.RGB(120,120,120))
	end	
	x_point[1],y_point[1] = point_roll(posx,posy-5*(size+1)/4,math.tointeger(yaw+180))
	x_point[2],y_point[2] = point_roll(posx,posy+12*(size+1)/4,math.tointeger(yaw))
	x_point[3],y_point[3] = point_roll(posx-10*(size+1)/4,posy-12*(size+1)/4,math.tointeger(yaw+180))	
	lcd.drawFilledTriangle(x_point[1],y_point[1],x_point[2],y_point[2] ,x_point[3],y_point[3] ,BAR_COLOR)
	x_point[1],y_point[1] = point_roll(posx,posy-5*(size+1)/4,math.tointeger(yaw+180))
	x_point[2],y_point[2] = point_roll(posx,posy+12*(size+1)/4,math.tointeger(yaw))
	x_point[3],y_point[3] = point_roll(posx+10*(size+1)/4,posy-12*(size+1)/4,math.tointeger(yaw+180))	
	lcd.drawFilledTriangle(x_point[1],y_point[1],x_point[2],y_point[2] ,x_point[3],y_point[3] ,BAR_COLOR)
end

local function get_distance(lon1,lat1,lon2,lat2)
	local d_lat
	local d_lon
	local d
	local a
	local c
	lon1=lon1*math.pi/180
	lon2=lon2*math.pi/180
	lat1=lat1*math.pi/180
	lat2=lat2*math.pi/180
	d_lon=lon1-lon2
	d_lat=lat1-lat2
	a=math.sin(d_lat/2)*math.sin(d_lat/2)+math.cos(lat1)*math.cos(lat2)*math.sin(d_lon/2)*math.sin(d_lon/2)
	c=2*math.atan2(math.sqrt(a),math.sqrt(1-a))
	d=c*6371
	return d
end

local b_rate = 1.8

local function XUI_line_roll2( x1, y1, x2, y2, roll, c)
	local x=0
	local y=0
	local xx=0
	local yy=0
	local x0=hx
	local y0=hy
	local temp_y=y1
	local a
	local d
	if hud_mode == 1 then
		x0 = hx
		y0 = hy
	elseif hud_mode == 2 then 
		x0 = qx
		y0 = qy
	end
	roll= roll + 180
	roll = - roll
	if(y1>y0) then
		x1=2*x0-x1
		y1=2*y0-y1
		a=math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180
		d=math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))
		x=x0-math.cos(a)*d
		y=y0-math.sin(a)*d	
	else 
		a=math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180
		d=math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))
		x=x0+math.cos(a)*d
		y=y0+math.sin(a)*d	
	end
	if(y2>y0) then
		x2=2*x0-x2	
		y2=2*y0-y2
		a=math.acos((x2-x0)/(math.sqrt((x2-x0)*(x2-x0)+(y2-y0)*(y2-y0))))+roll*math.pi/180
		d=math.sqrt((x2-x0)*(x2-x0)+(y2-y0)*(y2-y0))
		xx=x0-math.cos(a)*d
		yy=y0-math.sin(a)*d		
	else 
		a=math.acos((x2-x0)/(math.sqrt((x2-x0)*(x2-x0)+(y2-y0)*(y2-y0))))+roll*math.pi/180
		d=math.sqrt((x2-x0)*(x2-x0)+(y2-y0)*(y2-y0))
		xx=x0+math.cos(a)*d
		yy=y0+math.sin(a)*d	
	end
	x0=x0-math.cos(math.pi/2+roll*math.pi/180)*(temp_y-y0)
	y0=y0-math.sin(math.pi/2+roll*math.pi/180)*(temp_y-y0)	
	x=2*x0-x	
	y=2*y0-y	
	xx=2*x0-xx
	yy=2*y0-yy
	lcd.drawLine(x,y,xx,yy,SOLID,c)
end

local function XUI_num_roll( x1, y1, num, roll,  color1, color2)       	
	local x=0
	local y=0
	local x0=hx
	local y0=hy
	local a
	local d
	roll= roll+180
	roll = - roll
	if(y1>y0) then	
		x1=2*x0-x1
		y1=2*y0-y1	
		a=math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180
		d=math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0));
		x=x0-math.cos(a)*d
		y=y0-math.sin(a)*d	
	else 
		a=math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180
		d=math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))
		x=x0+math.cos(a)*d
		y=y0+math.sin(a)*d
	end
	lcd.drawNumber(x-len(num)*3, y-8, num, color2 )
end

local function XUI_num_roll2( x1, y1, num, roll,  color1, color2)       	
	local x=0
	local y=0
	local x0=hx
	local y0=hy
	local a
	local d
	if hud_mode == 1 then
		x0 = hx
		y0 = hy
	elseif hud_mode == 2 then 
		x0 = qx
		y0 = qy
	end
	roll= roll+180
	roll = - roll
	if(y1>y0) then	
		x1=2*x0-x1
		y1=2*y0-y1	
		a=math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180
		d=math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0));
		x=x0-math.cos(a)*d
		y=y0-math.sin(a)*d	
	else 
		a=math.acos((x1-x0)/(math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))))+roll*math.pi/180
		d=math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))
		x=x0+math.cos(a)*d
		y=y0+math.sin(a)*d
	end
	lcd.drawNumber(x-len(num)*3, y-8, num, c2 )
end

local function XUI_pitch(pitch,roll,c1,c2)
	local angle = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	local i=0
	for i=1,  19  do
		angle[i]=-90+(i-1)*10+pitch
		if  angle[i]>=-35 and angle[i]<=35 then		
			if i== 10 then					
				XUI_line_roll2(hx-100,hy+angle[i]*b_rate,hx-30,hy+angle[i]*b_rate,roll,c1)
				XUI_line_roll2(hx+30,hy+angle[i]*b_rate,hx+100,hy+angle[i]*b_rate,roll,c1)		
				XUI_num_roll(hx-110,hy+angle[i]*b_rate,0,roll,c1,c2)
				XUI_num_roll(hx+115,hy+angle[i]*b_rate,0,roll,c1,c2)
			else 		
				XUI_line_roll2(hx-60,hy+angle[i]*b_rate,hx-30,hy+angle[i]*b_rate,roll,c1)
				XUI_line_roll2(hx+30,hy+angle[i]*b_rate,hx+60,hy+angle[i]*b_rate,roll,c1)	
				if math.fmod(i,2)==0 then
					XUI_num_roll(hx-75,hy+angle[i]*b_rate,(10-i)*10,roll,c1,c2)
					XUI_num_roll(hx+80,hy+angle[i]*b_rate,(10-i)*10,roll,c1,c2)
				end
			end
		end
	end
end

local function XUI_pitch2(pitch,roll,c1,c2)
	local angle = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	local i=0
	for i=1,  19  do
		angle[i]=-90+(i-1)*10+pitch
		if  angle[i]>=-25 and angle[i]<=25 then		
			if i== 10 then					
				XUI_line_roll2(qx-45,qy+angle[i]*b_rate,qx-15,qy+angle[i]*b_rate,roll,c1)
				XUI_line_roll2(qx+15,qy+angle[i]*b_rate,qx+45,qy+angle[i]*b_rate,roll,c1)		
				XUI_num_roll2(qx-50,qy+angle[i]*b_rate,0,roll,c2,c2)
				XUI_num_roll2(qx+55,qy+angle[i]*b_rate,0,roll,c2,c2)
			else 		
				XUI_line_roll2(qx-30,qy+angle[i]*b_rate,qx-15,qy+angle[i]*b_rate,roll,c1)
				XUI_line_roll2(qx+15,qy+angle[i]*b_rate,qx+30,qy+angle[i]*b_rate,roll,c1)	
				if math.fmod(i,2)==0 then
					XUI_num_roll2(qx-45,qy+angle[i]*b_rate,(10-i)*10,roll,c2,c2)
					XUI_num_roll2(qx+50,qy+angle[i]*b_rate,(10-i)*10,roll,c2,c2)
				end
			end
		end
	end
end

local function XUI_alt(altitude, c1, c2)
	local i=0
	local step = 8
	local alt = altitude 
	local b=0
	local y=0
	local temp=0
	b=alt%10
	for i = 0 , 15 do	
		local y2
		y=-b+10*i+hy-48
		y=(y-hy)*4+hy-8
		y=ly-y
		y2=y-step*2
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(lx-70,y2,lx-60,y2,SOLID,c1)
		end
		y2=y-step
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(lx-70,y2,lx-60,y2,SOLID,c1)
		end
		y2=y+step
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(lx-70,y2,lx-60,y2,SOLID,c1)
		end
		y2=y+step*2
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(lx-70,y2,lx-60,y2,SOLID,c1)
		end		
		if y>=(hy-80)and y<=(hy+60) then				
			lcd.drawLine(lx-70,y,lx-50,y,SOLID,c1)		
			temp = alt-b+10*i -40
			if(temp<0) then
				temp=-temp
				lcd.drawText(lx-48, y-9 ,"-" , c1 )
				lcd.drawNumber(lx-40,y-8, temp, c1 )
			else 
				lcd.drawNumber(lx-48,y-8, temp, c1 )
			end
		end		
	end		
	lcd.drawFilledRectangle( lx-52,hy-15,60,30, c2 )
	if(math.abs(alt)<100)then	
		lcd.drawText(lx-30-len(alt)*4, hy-9, string.format("%.1f", alt ), FONT_COLOR )
	else 
		lcd.drawText(lx-27-len(alt)*4, hy-9, string.format("%d", alt ), FONT_COLOR )
	end
end

local function XUI_alt2(altitude, c1, c2)
	local i=0
	local step = 7.5
	local alt = altitude 
	local b=0
	local y=0
	local temp=0
	b=alt%10
	for i = 0 , 15 do	
		local y2
		y=-b+10*i+qy-48
		y=(y-qy)*3+qy-25
		y=ly-y
		y2=y-step*2
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(hx-50,y2,hx-43,y2,SOLID,c1)
		end
		y2=y-step
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(hx-50,y2,hx-43,y2,SOLID,c1)
		end
		y2=y+step
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(hx-50,y2,hx-43,y2,SOLID,c1)
		end
		y2=y+step*2
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(hx-50,y2,hx-43,y2,SOLID,c1)
		end		
		if y>=(qy-50)and y<=(qy+50) then				
			lcd.drawLine(hx-50,y,hx-35,y,SOLID,c1)		
			temp = alt-b+10*i -90
			if(temp<0) then 
				temp=-temp
				lcd.drawText(hx-32, y-9 ,"-" , c1 )
				lcd.drawNumber(hx-28,y-8, temp, c1 )
			else 
				lcd.drawNumber(hx-21-len(temp)*4,y-8, temp, c1 )
			end
		end		
	end		
	lcd.drawFilledRectangle( hx-40,qy-12,40,24, c2 )
	if alt >= 1000 then 
		lcd.drawText(hx-21-len(alt)*4, qy-8, string.format("%d", alt ), FONT_COLOR )
	elseif alt >= 100 then
		lcd.drawText(hx-21-len(alt)*4, qy-8, string.format("%d", alt ), FONT_COLOR )
	elseif alt >= 0 then
		lcd.drawText(hx-27-len(alt)*4, qy-8, string.format("%.1f", alt ), FONT_COLOR )
	elseif alt >= -100 then
		lcd.drawText(hx-28-len(alt)*4, qy-8, string.format("%.1f", alt ), FONT_COLOR )	
	else 
		lcd.drawText(hx-24-len(alt)*4, qy-8, string.format("%d", alt ), FONT_COLOR )
	end	
end

local function XUI_speed(spd, c1, c2)
	local i=0
	local step = 8
	local b=0
	local y=0
	local temp=0
	b=spd%10
	for i = 0 , 15 do	
		local y2
		y=-b+10*i+hy-48
		y=(y-hy)*4+hy-8
		y=ly-y
		y2=y-step*2
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(60,y2,70,y2,SOLID,c1)
		end
		y2=y-step
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(60,y2,70,y2,SOLID,c1)
		end
		y2=y+step
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(60,y2,70,y2,SOLID,c1)
		end
		y2=y+step*2
		if(y2>=(hy-80)and y2<=(hy+60))then
			lcd.drawLine(60,y2,70,y2,SOLID,c1)
		end		
		if y>=(hy-80)and y<=(hy+60) then				
			lcd.drawLine(50,y,70,y,SOLID,c1)		
			temp = spd-b+10*i -40
			if(temp<0) then
				temp=-temp
				lcd.drawText(40, y-9 ,"-" , c1 )
			else 
				if temp < 10 then
					lcd.drawNumber(36,y-8, temp, c1 )
				elseif temp < 100 then
					lcd.drawNumber(28,y-8, temp, c1 )
				else 
					lcd.drawNumber(20,y-8, temp, c1 )
				end
			end
		end		
	end		
	lcd.drawFilledRectangle( 0,hy-15,52,30, c2 )
	if(math.abs(spd)<100)then	
		lcd.drawText(20-len(spd)*4, hy-9, string.format("%.1f", spd ), FONT_COLOR )
	else 
		lcd.drawText(23-len(spd)*4, hy-9, string.format("%d", spd ), FONT_COLOR )
	end
end

local function XUI_speed2(spd, c1, c2)
	local i=0
	local step = 7.5
	local b=0
	local y=0
	local temp=0
	b=spd%10
	for i = 0 , 15 do	
		local y2
		y=-b+10*i+qy-48
		y=(y-qy)*3+qy+35
		y=ly-y
		y2=y-step*2
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(43,y2,50,y2,SOLID,c1)
		end
		y2=y-step
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(43,y2,50,y2,SOLID,c1)
		end
		y2=y+step
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(43,y2,50,y2,SOLID,c1)
		end
		y2=y+step*2
		if(y2>=(qy-50)and y2<=(qy+50))then
			lcd.drawLine(43,y2,50,y2,SOLID,c1)
		end		
		if y>=(qy-50)and y<=(qy+50) then				
			lcd.drawLine(35,y,50,y,SOLID,c1)		
			temp = spd-b+10*i -40-30
			if(temp<0) then
				temp=-temp
				lcd.drawText(14, y-9 ,"-" , c1 )
			else 
				if temp < 10 then
					lcd.drawNumber(9,y-8, temp, c1 )
				elseif temp < 100 then
					lcd.drawNumber(6,y-8, temp, c1 )
				else 
					lcd.drawNumber(3,y-8, temp, c1 )
				end
			end
		end	
	end		
	lcd.drawFilledRectangle( 0,qy-12,40,24, c2 )
	if(math.abs(spd)<100)then	
		lcd.drawText(13-len(spd)*4, qy-9, string.format("%.1f", spd ), FONT_COLOR )
	else 
		lcd.drawText(18-len(spd)*4, qy-9, string.format("%d", spd ), FONT_COLOR )
	end
end

local function XUI_yaw(yaw,c1,c2)
	local b=0
	local i=0
	local x=0
	local temp = 0
	b=yaw%30
	for i=-2,12 do
		local x2
		local xoffset=200
		x=-b+30*i+hx-120	
		x=(x-hx)*2+hx
		x2=x-24 
		xoffset=140
		if(x2>=(hx-xoffset)and x2<=(hx+xoffset)) then
			lcd.drawLine(x2,62,x2,70,SOLID,c1)	
		end
		x2=x-12
		if(x2>=(hx-xoffset)and x2<=(hx+xoffset)) then
			lcd.drawLine(x2,62,x2,70,SOLID,c1)	
		end
		x2=x+12
		if(x2>=(hx-xoffset)and x2<=(hx+xoffset)) then
			lcd.drawLine(x2,62,x2,70,SOLID,c1)	
		end
		x2=x+24
		if(x2>=(hx-xoffset)and x2<=(hx+xoffset)) then
			lcd.drawLine(x2,62,x2,70,SOLID,c1)	
		end		
		if(x>=(hx-xoffset)and x<=(hx+xoffset)) then	
			lcd.drawLine(x,55,x,70,SOLID,c1)	
			temp=yaw-b-90+30*i-30
			if(temp<0) then
				temp= temp +360
			elseif(temp>=360) then
				temp=temp - 360
			end		
			if (temp==0)  then
				lcd.drawText(x-4, 40 ,"N" , c1 )
				--XUI_char(x-4,6,'N',16,1,c1,0)
			elseif(temp==90)  then
				lcd.drawText(x-4, 40 ,"E" , c1 )
				--XUI_char(x-4,6,'E',16,1,c1,0)
			elseif(temp==180) then
				lcd.drawText(x-4, 40 ,"S" , c1 )
				--XUI_char(x-4,6,'S',16,1,c1,0)
			elseif(temp==270) then
				lcd.drawText(x-4, 40 ,"W" , c1 )
				--XUI_char(x-4,6,'W',16,1,c1,0)
			else 
				lcd.drawNumber(x-len(temp)*4,40, temp, c1 )			
			end
		end	
	end
	lcd.drawFilledRectangle( hx-20,40,40,20, c2 )
	temp = yaw
	if(temp<0) then
		temp= temp +360
	elseif(temp>=360) then
		temp=temp - 360
	end
	lcd.drawNumber(hx-len(temp)*4,41,temp, c1 )
end

local function XUI_yaw2(yaw,c1,c2)
	local b=0
	local i=0
	local x=0
	local temp = 0
	local q3x = hx + qx
	b=yaw%30
	for i=-2,12 do
		local x2
		local xoffset=60
		x=-b+30*i+qx-120	
		x=(x-qx)+qx
		if(x>=(qx-xoffset)and x<=(qx+xoffset)) then	
			lcd.drawLine(x+15,44,x+15,52,SOLID,c1)	
			lcd.drawLine(x-15,44,x-15,52,SOLID,c1)	
			temp=yaw-b-90+30*i-30
			if(temp<0) then
				temp= temp +360
			elseif(temp>=360) then
				temp=temp - 360
			end		
			if (temp==0)  then
				lcd.drawText(x-4, 40 ,"N" , c2 )
			elseif(temp==90)  then
				lcd.drawText(x-4, 40 ,"E" , c2 )
			elseif(temp==180) then
				lcd.drawText(x-4, 40 ,"S" , c2 )
			elseif(temp==270) then
				lcd.drawText(x-4, 40 ,"W" , c2 )
			else 
				lcd.drawNumber(x-len(temp)*4,40, temp, c2)			
			end
		end	
	end
	lcd.drawFilledRectangle( qx-20,40,40,20, c2 )
	temp = yaw
	if(temp<0) then
		temp= temp +360
	elseif(temp>=360) then
		temp=temp - 360
	end
	lcd.drawNumber(qx-len(temp)*4,41,temp, c1 )
end

local message_temp = "Welcome"
local message_time = 0

local function draw_sw(x,y,sta)
	XUI_bar0(x,y,20,10,10,FONT_COLOR)
	if sta == 1 then
		lcd.drawFilledCircle(x+10, y,8,GREEN)
	elseif sta == 0 then	 
		lcd.drawFilledCircle(x-10, y,8,RED)
	elseif sta == 11 then	
		lcd.drawFilledCircle(x+10, y,8,lcd.RGB(100,100,100))
	elseif sta == 10 then	
		lcd.drawFilledCircle(x-10, y,8,lcd.RGB(100,100,100))
	end
end

local function message(message)
	if message ~= nil then 
		message_temp = message
		message_time = 10	
	end
end

local function message_refresh()
	if message_time > 0 then
		local len = #message_temp
		XUI_bar(hx,hy,len*4+30,20,6,FONT_COLOR)
		XUI_bar0(hx,hy,len*4+30,20,6,BLACK)
		if message_temp ~= nil then
			lcd.drawText(hx-len*4, hy-8 , message_temp , BLACK )		
		end
	end
end

local function get_touch (posx,posy,x0,y0,x1,y1)
	if posx >= x0 and posx <= x1 and posy >=y0 and posy <=y1 then 
		return 1
	else 
		return 0
	end
end

local event_num = {0,0,0,0,0}
local event_i = 1
local event_old = 0

-- Main
local function run ( event, touchState )
	if tonumber(ver_num[1]) == 2 and tonumber(ver_num[2]) <= 10  then
		lcd.clear(WHITE)
		lcd.drawText(hx-80, hy-28,"EDGETX Ver : " .. ver,  RED  )
		lcd.drawText(hx-150, hy-8,"EDGETX Ver is old , Please update 2.11 or 3.0",  RED  )
		return 0
	end

	if hud_mode == 1 then	
		lcd.drawFilledRectangle( 0,40,lx, ly, MAP_BG_COLOR )
		lcd.drawLine(0,hy,lx,hy,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(0,hy-60,lx,hy-60,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(0,hy-120,lx,hy-120,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(0,hy+60,lx,hy+60,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(0,hy+120,lx,hy+120,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx,0,hx,ly,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx-60,0,hx-60,ly,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx-120,0,hx-120,ly,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx-180,0,hx-180,ly,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx+60,0,hx+60,ly,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx+120,0,hx+120,ly,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx+180,0,hx+180,ly,DOTTED,MAP_LINE_COLOR)		
		if hud_size == 1 then
			lcd.drawFilledRectangle( 0,LCD_H-60,60, 60, HUD_SKY_COLOR )
			lcd.drawHudRectangle(pitch,roll,0,60,LCD_H-60, LCD_H, HUD_GROUND_COLOR  )
			XUI_bar_inv(30,LCD_H-30, 30, 30,10,MAP_BG_COLOR)
		elseif hud_size == 2 then
			lcd.drawFilledRectangle( 0,LCD_H-90,90, 90, HUD_SKY_COLOR )
			lcd.drawHudRectangle(pitch,roll,0,90,LCD_H-90, LCD_H, HUD_GROUND_COLOR  )
			XUI_bar_inv(45,LCD_H-45, 45, 45,15,MAP_BG_COLOR)
		elseif hud_size == 3 then
			lcd.drawFilledRectangle( 0,LCD_H-120,120, 120, HUD_SKY_COLOR )
			lcd.drawHudRectangle(pitch,roll,0,120,LCD_H-120, LCD_H, HUD_GROUND_COLOR  )
			XUI_bar_inv(60,LCD_H-60, 60, 60,20,MAP_BG_COLOR)				
		end
		lcd.drawLine(6,315,20,315,SOLID,FONT_COLOR)
		lcd.drawLine(5,315,20,315,SOLID,FONT_COLOR)
		lcd.drawLine(4,316,20,316,SOLID,FONT_COLOR)			
		lcd.drawLine(6,300,6,314,SOLID,FONT_COLOR)
		lcd.drawLine(5,300,5,315,SOLID,FONT_COLOR)
		lcd.drawLine(4,300,4,316,SOLID,FONT_COLOR)
		lcd.drawLine((hud_size+1)*3,ly-(hud_size+1)*15,(hud_size+1)*10,ly-(hud_size+1)*15,SOLID,FONT_COLOR)
		lcd.drawLine((hud_size+1)*20,ly-(hud_size+1)*15,(hud_size+1)*28,ly-(hud_size+1)*15,SOLID,FONT_COLOR)			
		lcd.drawCircle((hud_size+1)*15,ly-(hud_size+1)*15,hud_size*2,FONT_COLOR)	
		lcd.drawLine((hud_size+1)*12,ly-(hud_size+1)*15,(hud_size+1)*15-hud_size*2,ly-(hud_size+1)*15,SOLID,FONT_COLOR)
		lcd.drawLine((hud_size+1)*18,ly-(hud_size+1)*15,(hud_size+1)*15+hud_size*2,ly-(hud_size+1)*15,SOLID,FONT_COLOR)
		lcd.drawLine((hud_size+1)*15,ly-(hud_size+1)*15-hud_size*2,(hud_size+1)*15,ly-(hud_size+1)*18,SOLID,FONT_COLOR)
		lcd.drawBitmap(home, hx-15, hy-14, 30)
		draw_plane(yaw)

	elseif hud_mode == 0 then
		lcd.drawFilledRectangle( 0,40,lx, ly-40, HUD_SKY_COLOR )
		lcd.drawHudRectangle(pitch,roll,0,lx,40, ly, HUD_GROUND_COLOR  )
		lcd.drawCircle(hx,hy,5,FONT_COLOR)
		lcd.drawLine(hx-15,hy,hx-5,hy,SOLID,FONT_COLOR)
		lcd.drawLine(hx+15,hy,hx+5,hy,SOLID,FONT_COLOR)
		lcd.drawLine(hx,hy-5,hx,hy-12,SOLID,FONT_COLOR)
		XUI_pitch(pitch,roll,BAR_COLOR,FONT_COLOR)
		lcd.drawText(lx-50, 70,"ALT", BAR_COLOR  )
		XUI_alt(alt,FONT_COLOR,BAR_COLOR)
		lcd.drawText(10, 70,"SPEED",  BAR_COLOR  )
		XUI_speed(speed,FONT_COLOR,BAR_COLOR)
		XUI_yaw(yaw,FONT_COLOR,BAR_COLOR)
		XUI_bar(((hud_size+1)*15),ly-((hud_size+1)*15),((hud_size+1)*15),((hud_size+1)*15),((hud_size+1)*15)/3,MAP_BG_COLOR)			
		draw_plane2(yaw)
		lcd.drawLine(6,315,20,315,SOLID,FONT_COLOR)
		lcd.drawLine(5,315,20,315,SOLID,FONT_COLOR)
		lcd.drawLine(4,316,20,316,SOLID,FONT_COLOR)			
		lcd.drawLine(6,300,6,314,SOLID,FONT_COLOR)
		lcd.drawLine(5,300,5,315,SOLID,FONT_COLOR)
		lcd.drawLine(4,300,4,316,SOLID,FONT_COLOR)

	elseif hud_mode == 2 then
		lcd.drawFilledRectangle( hx,40,hx, hy-40, MAP_BG_COLOR )
		lcd.drawFilledRectangle( 0,40,hx, hy-40, HUD_SKY_COLOR )
		lcd.drawHudRectangle(pitch,roll,0,hx,40, hy, HUD_GROUND_COLOR  )
		lcd.drawFilledRectangle( 0,hy,lx, hy, BAR_COLOR )
		XUI_bar(((0+1)*15),ly-((0+1)*15),((0+1)*15),((0+1)*15),((0+1)*15)/3,BAR_COLOR)
		lcd.drawCircle(qx,qy,4,FONT_COLOR)
		lcd.drawLine(qx-10,qy,qx-4,qy,SOLID,FONT_COLOR)
		lcd.drawLine(qx+10,qy,qx+4,qy,SOLID,FONT_COLOR)
		lcd.drawLine(qx,qy-4,qx,qy-10,SOLID,FONT_COLOR)
		XUI_pitch2(pitch,roll,FONT_COLOR,BAR_COLOR)
		lcd.drawText(hx-30, 45,"ALT",  BAR_COLOR )
		XUI_alt2(alt,FONT_COLOR,BAR_COLOR)
		lcd.drawText(2, 45,"SPD",  BAR_COLOR )
		XUI_speed2(speed,FONT_COLOR,BAR_COLOR)
		XUI_yaw2(yaw,FONT_COLOR,BAR_COLOR)		
		lcd.drawLine(hx,qy,lx,qy,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx,qy-50,lx,qy-50,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(hx,qy+50,lx,qy+50,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(q3x,40,q3x,hy,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(q3x-50,40,q3x-50,hy,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(q3x-100,40,q3x-100,hy,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(q3x+50,40,q3x+50,hy,DOTTED,MAP_LINE_COLOR)
		lcd.drawLine(q3x+100,40,q3x+100,hy,DOTTED,MAP_LINE_COLOR)		
		draw_plane3(yaw)
		lcd.drawText(hx, qy-8,"W", BOLD + FONT_COLOR )		
		lcd.drawText(q3x-4, 40,"N", BOLD + FONT_COLOR )
		lcd.drawText(lx-12, qy-8,"E", BOLD + FONT_COLOR )
		lcd.drawText(q3x-4, hy-16,"S", BOLD + FONT_COLOR )
	end

	lcd.drawFilledRectangle( 0,0, 480, 40, BAR_COLOR)	
	lcd.drawText(hx-(#modelInfo.name)*10, 4, modelInfo.name,MIDSIZE+BOLD + FONT_COLOR) -- display model's name
	if getValue('TQly') > 10 then
		if RC_linked == 0 then
			RC_linked = 1
			message("RC_linked")
			playTone(1500, 100, 0)
		end
	end	
	if RC_linked == 1 then 
		lcd.drawText(50, 3,"TX: " .. getValue('TQly').. "", SMLSIZE + FONT_COLOR  )
		lcd.drawText(50, 20,"RX: " .. getValue('RQly').. "", SMLSIZE + FONT_COLOR  )
		lcd.drawText(110, 3,"RT: " .. getValue('RFMD').. "", SMLSIZE + FONT_COLOR  )
		lcd.drawText(110, 20,"TP: " .. getValue('TPWR').. "mW", SMLSIZE + FONT_COLOR  )		
	else
		lcd.drawText(50, 3,"TX: " .. getValue('TQly').. "", SMLSIZE + RED  )
		lcd.drawText(50, 20,"RX: " .. getValue('RQly').. "", SMLSIZE + RED  )
		lcd.drawText(110, 3,"RT: " .. getValue('RFMD').. "", SMLSIZE + RED  )
		lcd.drawText(110, 20,"TP: " .. getValue('TPWR').. "mW", SMLSIZE + RED  )			
	end
	lcd.drawText(320 , 3, "FPS: " .. tostring(fps) .. "Hz",SMLSIZE + FONT_COLOR )--SMLSIZE + FONT_COLOR
	lcd.drawText(320, 20,"BAT: " .. getValue('tx-voltage').. "V", SMLSIZE + FONT_COLOR )
	local date = getDateTime()
	lcd.drawText(400, 3,tostring(date.mon) .. "-" .. tostring(date.day) , SMLSIZE + FONT_COLOR )
	lcd.drawText(400, 20,tostring(date.hour) .. ":" .. tostring(date.min) , SMLSIZE + FONT_COLOR )	
	lcd.drawLine(12,20,24,10,SOLID,FONT_COLOR)
	lcd.drawLine(13,20,25,10,SOLID,FONT_COLOR)
	lcd.drawLine(14,20,26,10,SOLID,FONT_COLOR)
	lcd.drawLine(12,20,24,30,SOLID,FONT_COLOR)
	lcd.drawLine(13,20,25,30,SOLID,FONT_COLOR)
	lcd.drawLine(14,20,26,30,SOLID,FONT_COLOR)
	lcd.drawLine(40,10,40,30,SOLID,CUT_COLOR)
	lcd.drawLine(41,10,41,30,SOLID,CUT_COLOR)
	lcd.drawFilledCircle(450, 20,2,FONT_COLOR)
	lcd.drawFilledCircle(460, 20,2,FONT_COLOR)
	lcd.drawFilledCircle(470, 20,2,FONT_COLOR)
	lcd.drawLine(lx-40,10,lx-40,30,SOLID,CUT_COLOR)
	lcd.drawLine(lx-41,10,lx-41,30,SOLID,CUT_COLOR)

	if hud_mode == 0 or hud_mode == 1 then 	
		lcd.drawText(120, ly-20,"RxBt: " .. tostring(getValue('RxBt')) .. "v", SMLSIZE + FONT_COLOR )
		lcd.drawText(120, ly-40,"Curr: " .. tostring(getValue('Curr')) .. "A", SMLSIZE + FONT_COLOR )
		lcd.drawText(120, ly-60,"Bat%: " .. tostring(getValue('Bat%')) .. "%", SMLSIZE + FONT_COLOR )
		lcd.drawText(195, ly-20,"Alt: " .. tostring(getValue('Alt')) .. "m", SMLSIZE + FONT_COLOR )
		lcd.drawText(195, ly-40,"Hdop: " .. tostring(getValue('Hdg')) .. "", SMLSIZE + FONT_COLOR )
		if home_fixed == 1 then
			lcd.drawText(195, ly-60,"GPS: " .. getValue('Sats').. "",SMLSIZE + FONT_COLOR )	
		else 
			lcd.drawText(195, ly-60,"GPS: " .. getValue('Sats').. "",SMLSIZE + RED )	
		end
		lcd.drawText(280, ly-60,"FM: " .. getValue('FM').. "",SMLSIZE + FONT_COLOR )
		lcd.drawText(280, ly-20,"VSpd: " .. tostring(getValue('VSpd')) .. "m/s", SMLSIZE + FONT_COLOR )
		lcd.drawText(280, ly-40,"GSpd: " .. tostring(getValue('GSpd')) .. "km/h", SMLSIZE + FONT_COLOR )
		lcd.drawText(380 , ly-20, "LON: " .. tostring(lon).. "E", SMLSIZE + FONT_COLOR )--SMLSIZE + FONT_COLOR
		lcd.drawText(380 , ly-40, "LAT: " .. tostring(lat) .. "N",  SMLSIZE + FONT_COLOR )--SMLSIZE + FONT_COLOR				
		hud_distance=get_distance(lon,lat,home_x,home_y)*1000;
		if hud_distance < 10000 then
			lcd.drawText(380, ly-60,"Dist: " .. string.format("%.1f", hud_distance ) .. "m", SMLSIZE + FONT_COLOR )
		elseif hud_distance < 100000000 then
			lcd.drawText(380, ly-60,"Dist: " .. string.format("%d", hud_distance /1000) .. "km", SMLSIZE + FONT_COLOR )
		else	
			lcd.drawText(380, ly-60,"Dist:NoGPS",  SMLSIZE + FONT_COLOR )
		end

	elseif hud_mode == 2 then
		lcd.drawLine(qx,hy,qx,ly,SOLID,CUT_COLOR)
		lcd.drawLine(hx,hy,hx,ly,SOLID,CUT_COLOR)
		lcd.drawLine(q3x,hy,q3x,ly,SOLID,CUT_COLOR)
		lcd.drawLine(0,hy+(hy-40)/3,lx,hy+(hy-40)/3,SOLID,CUT_COLOR)
		lcd.drawLine(0,hy+(hy-40)*2/3,lx,hy+(hy-40)*2/3,SOLID,CUT_COLOR)
		if ly > 300 then	
			lcd.drawText(10, hy+3,"Rx battery", SMLSIZE+ FONT_COLOR )
			lcd.drawText(40, hy+15, tostring(getValue('RxBt')) .. "v",  MIDSIZE+ FONT_COLOR + SHADOWED )
			lcd.drawText(10, hy+51,"Curr" ,   SMLSIZE+ FONT_COLOR )
			lcd.drawText(40, hy+63,tostring(getValue('Curr')) .. "A",    MIDSIZE+ FONT_COLOR + SHADOWED )
			lcd.drawText(10,hy+99,"Bat%",  SMLSIZE+  FONT_COLOR )
			lcd.drawText(40,hy+111,tostring(getValue('Bat%')) .. "%",   MIDSIZE+  FONT_COLOR + SHADOWED )		
			lcd.drawText(130, hy+3,"Altitude" , SMLSIZE + FONT_COLOR )
			lcd.drawText(170-len(getValue('Alt'))*8, hy+15, string.format("%d",getValue('Alt')) .. "m",  MIDSIZE + FONT_COLOR + SHADOWED )
			lcd.drawText(130, hy+51,"Hdp:", SMLSIZE + FONT_COLOR )
			lcd.drawText(185-len(getValue('Hdg')*100)*8, hy+63, tostring(getValue('Hdg')) .. "",  MIDSIZE + FONT_COLOR + SHADOWED )
			if home_fixed == 1 then
				lcd.drawText(130, hy+99,"GPS Stats",SMLSIZE + FONT_COLOR )	
				lcd.drawText(175, hy+111,getValue('Sats').. "", MIDSIZE + FONT_COLOR+ SHADOWED  )	
			else 
				lcd.drawText(130, hy+99,"GPS Stats",SMLSIZE + FONT_COLOR )	
				if getValue('Sats') == 0 then	
					lcd.drawText(140, hy+111,"No GPS", MIDSIZE + RED + SHADOWED )	
				else
					lcd.drawText(175, hy+111,getValue('Sats').. "", MIDSIZE + RED+ SHADOWED  )	
				end
			end

			lcd.drawText(250, hy+3,"FMod",SMLSIZE + FONT_COLOR )
			lcd.drawText(270, hy+15,getValue('FM').. "", MIDSIZE + FONT_COLOR + SHADOWED )
			lcd.drawText(250, hy+51,"VSpd" , SMLSIZE + FONT_COLOR )
			lcd.drawText(260, hy+63,tostring(getValue('VSpd')) .. "m/s",  MIDSIZE + FONT_COLOR+ SHADOWED  )
			lcd.drawText(250, hy+99,"GSpd", SMLSIZE + FONT_COLOR )		
			lcd.drawText(260, hy+111,tostring(getValue('GSpd')) .. "kmh",   MIDSIZE + FONT_COLOR + SHADOWED )		
			lcd.drawText(370 , hy+3, "Longtiude", SMLSIZE + FONT_COLOR )--SMLSIZE + FONT_COLOR
			lcd.drawText(370 , hy+15, string.format("%.4f", lon),  MIDSIZE + FONT_COLOR + SHADOWED )--SMLSIZE + FONT_COLOR
			lcd.drawText(370 , hy+51, "Latitude", SMLSIZE + FONT_COLOR )--SMLSIZE + FONT_COLOR	
			lcd.drawText(370 , hy+63,  string.format("%.5f", lat),   MIDSIZE + FONT_COLOR + SHADOWED )--SMLSIZE + FONT_COLOR				
			hud_distance=get_distance(lon,lat,home_x,home_y)*1000;
			lcd.drawText(370, hy+99,"Distance", SMLSIZE + FONT_COLOR  )
			if hud_distance < 1000 then
				lcd.drawText(420-len(hud_distance)*8, hy+111,string.format("%.1f", hud_distance ) .. "m",  MIDSIZE + FONT_COLOR + SHADOWED )
			elseif hud_distance < 10000000 then
				lcd.drawText(415-len(hud_distance/1000)*8, hy+111,string.format("%d", hud_distance /1000) .. "km",  MIDSIZE + FONT_COLOR+ SHADOWED  )
			else	
				lcd.drawText(380, hy+111,"No GPS",  MIDSIZE + RED + SHADOWED )
			end
		else
			lcd.drawText(10, hy+3,"Rx battery", SMLSIZE+ FONT_COLOR )
			lcd.drawText(40, hy+15, tostring(getValue('RxBt')) .. "v",  MIDSIZE+ FONT_COLOR + SHADOWED )
			lcd.drawText(10, hy+41,"Curr" ,   SMLSIZE+ FONT_COLOR )
			lcd.drawText(40, hy+53,tostring(getValue('Curr')) .. "A",    MIDSIZE+ FONT_COLOR + SHADOWED )
			lcd.drawText(10,hy+79,"Bat%",  SMLSIZE+  FONT_COLOR )
			lcd.drawText(40,hy+91,tostring(getValue('Bat%')) .. "%",   MIDSIZE+  FONT_COLOR + SHADOWED )		
			lcd.drawText(130, hy+3,"Altitude" , SMLSIZE + FONT_COLOR )
			lcd.drawText(170-len(getValue('Alt'))*8, hy+15, string.format("%d",getValue('Alt')) .. "m",  MIDSIZE + FONT_COLOR + SHADOWED )
			lcd.drawText(130, hy+41,"Hdp:", SMLSIZE + FONT_COLOR )
			lcd.drawText(185-len(getValue('Hdg')*100)*8, hy+53, tostring(getValue('Hdg')) .. "",  MIDSIZE + FONT_COLOR + SHADOWED )
			if home_fixed == 1 then
				lcd.drawText(130, hy+79,"GPS Stats",SMLSIZE + FONT_COLOR )	
				lcd.drawText(175, hy+91,getValue('Sats').. "", MIDSIZE + FONT_COLOR+ SHADOWED  )	
			else 
				lcd.drawText(130, hy+79,"GPS Stats",SMLSIZE + FONT_COLOR )	
				if getValue('Sats') == 0 then	
					lcd.drawText(140, hy+91,"No GPS", MIDSIZE + RED + SHADOWED )	
				else
					lcd.drawText(175, hy+91,getValue('Sats').. "", MIDSIZE + RED+ SHADOWED  )	
				end
			end
			lcd.drawText(250, hy+3,"FMod",SMLSIZE + FONT_COLOR )
			lcd.drawText(270, hy+15,getValue('FM').. "", MIDSIZE + FONT_COLOR + SHADOWED )
			lcd.drawText(250, hy+41,"VSpd" , SMLSIZE + FONT_COLOR )
			lcd.drawText(260, hy+53,tostring(getValue('VSpd')) .. "m/s",  MIDSIZE + FONT_COLOR+ SHADOWED  )
			lcd.drawText(250, hy+79,"GSpd", SMLSIZE + FONT_COLOR )		
			lcd.drawText(260, hy+91,tostring(getValue('GSpd')) .. "kmh",   MIDSIZE + FONT_COLOR + SHADOWED )		
			lcd.drawText(370 , hy+3, "Longtiude", SMLSIZE + FONT_COLOR )--SMLSIZE + FONT_COLOR
			lcd.drawText(370 , hy+15, string.format("%.4f", lon),  MIDSIZE + FONT_COLOR + SHADOWED )--SMLSIZE + FONT_COLOR
			lcd.drawText(370 , hy+41, "Latitude", SMLSIZE + FONT_COLOR )--SMLSIZE + FONT_COLOR	
			lcd.drawText(370 , hy+53,  string.format("%.5f", lat),   MIDSIZE + FONT_COLOR + SHADOWED )--SMLSIZE + FONT_COLOR				
			hud_distance=get_distance(lon,lat,home_x,home_y)*1000;
			lcd.drawText(370, hy+79,"Distance", SMLSIZE + FONT_COLOR  )
			if hud_distance < 1000 then
				lcd.drawText(420-len(hud_distance)*8, hy+91,string.format("%.1f", hud_distance ) .. "m",  MIDSIZE + FONT_COLOR + SHADOWED )
			elseif hud_distance < 10000000 then
				lcd.drawText(415-len(hud_distance/1000)*8, hy+91,string.format("%d", hud_distance /1000) .. "km",  MIDSIZE + FONT_COLOR+ SHADOWED  )
			else	
				lcd.drawText(380, hy+91,"No GPS",  MIDSIZE + RED + SHADOWED )
			end			
		end
	end

	if screenshot_enable == 1 then
		XUI_bar(lx-18,54,15,12,6,BAR_COLOR)
		XUI_bar0(lx-18,54,15,12,6,FONT_COLOR)
		XUI_bar0(lx-18,54,9,6,2,FONT_COLOR)	
	end

	if param_edit == 1 then	
		XUI_bar(lx*3/4,LCD_H/2,lx/4,LCD_H/2,10,SETUP_COLOR)
		lcd.drawText(hx+20, setup_y +60-8,"SETUP1" , BOLD + FONT_COLOR )
		draw_sw(440,setup_y +60,setup_status[1] )
		lcd.drawText(hx+20, setup_y +85-8,"SETUP2" , BOLD + FONT_COLOR )
		draw_sw(440,setup_y +85,setup_status[2])
		lcd.drawText(hx+20, setup_y +110-8,"SETUP3" , BOLD + FONT_COLOR )
		draw_sw(440,setup_y +110,setup_status[3])
		lcd.drawText(hx+20, setup_y +135-8,"SETUP4" , BOLD + FONT_COLOR )
		draw_sw(440,setup_y +135,setup_status[4])
		lcd.drawText(lx*3/4-100, ly-50,"Mem: " .. string.format("%.1f",getAvailableMemory()/8/1024) .. "KB",  GREEN )
		lcd.drawText(lx*3/4+20, ly-50,radio,  GREEN )
		lcd.drawText(lx*3/4+65, ly-50,ver,  GREEN )
		lcd.drawFilledRectangle( hx+10,0,hx-20, 40, SETUP_COLOR )
		lcd.drawFilledRectangle( hx+10,ly-30,hx-20,ly, SETUP_COLOR )
		lcd.drawText(lx*3/4-32, 8,"SETUP" , MIDSIZE+ FONT_COLOR )
		lcd.drawText(lx*3/4-100, ly-23 ,"YGTECH-HUD" , RED )
		lcd.drawLine(lx-15,15,lx-25,25,SOLID,FONT_COLOR)
		lcd.drawLine(lx-14,15,lx-24,25,SOLID,FONT_COLOR)	
		lcd.drawLine(lx-25,15,lx-15,25,SOLID,FONT_COLOR)
		lcd.drawLine(lx-24,15,lx-14,25,SOLID,FONT_COLOR)
		lcd.drawLine(hx+16,20,hx+24,26,SOLID,FONT_COLOR)
		lcd.drawLine(hx+16,20,hx+24,14,SOLID,FONT_COLOR)
		lcd.drawLine(hx+15,20,hx+23,26,SOLID,FONT_COLOR)
		lcd.drawLine(hx+15,20,hx+23,14,SOLID,FONT_COLOR)		
		lcd.drawLine(hx+10,40,lx-10,40,SOLID,CUT_COLOR)
		lcd.drawLine(hx+10,ly-30,lx-10,ly-30,SOLID,CUT_COLOR)		
	end
	message_refresh()

	local success, sensor_id, frame_id, data_id, value = pcall(crossfirePop)
    if success and frame_id == 0x10 then
      processTelemetry(data_id, value)
	else
		local temp = getValue('Ptch')
		if old_pitch ~=  temp then
			pitch = temp*180/3.1415926
			old_pitch = temp
		end
		temp = getValue('Roll')
		if old_roll ~= temp then
			roll = temp*180/3.1415926
			old_roll = temp			
		end
    end
	local gpsData = getValue("GPS")
	if type(gpsData) == "table" and gpsData.lat ~= nil and gpsData.lon ~= nil then
		lat = gpsData.lat
		lon = gpsData.lon
	end	
	yaw=getValue('Yaw')*180/3.1415926
	speed = getValue('VSpd')
	alt = getValue('Alt')

	if getValue('Sats') >= 6 then
		if home_fixed == 0 then
			message("Home Fixed")
			playTone(1500, 100, 0)
			home_fixed = 1
			home_x = lon
			home_y = lat			
		end
	elseif home_fixed == 1 then
		home_fixed = 0
	end

	if param_edit == 0 then
		if event == EVT_TOUCH_FIRST then
			if touchState.x and touchState.x < 40 and touchState.y and touchState.y < 40 then
				exitscript = 1
			elseif touchState.x>(lx-40) and touchState.x < lx and touchState.y and touchState.y < 40 then
				param_edit = 1
				setup_x = lx
			elseif hud_mode == 0 or hud_mode  == 1 then
				if touchState.x and touchState.x < 40 and touchState.y > 280 and touchState.y < 320 then
					if hud_size > 1 then
						hud_size = hud_size -1
					else
						hud_size = 3
					end
				elseif touchState.x and touchState.x < ((hud_size+1)*30) and touchState.y > (ly-((hud_size+1)*30)) and touchState.y < ly then
					if hud_mode == 0 then 
						hud_mode = 1
					elseif hud_mode == 1 then 
						hud_mode = 2
					elseif hud_mode == 2 then 
						hud_mode = 0						
					end
				end
			end
			if hud_mode == 0 then
				if touchState.x > (hx-40) and touchState.x < (hx+40) and touchState.y > (hy-40)and touchState.y  < (hy+40) then		 
					if getValue('Sats') >= 6 then
						message("Home refreshed")
						playTone(1500, 100, 0)
						home_fixed = 1
						home_x = lon
						home_y = lat	
					else
						message("GPS sats < 6")
					end				
				end
			end			
			if hud_mode == 2 then
				if touchState.x and touchState.x < 40 and touchState.y > 280 and touchState.y < 320 then
					hud_mode = 0
				end					
				if touchState.x > (q3x-30) and touchState.x < (q3x+30) and touchState.y > (qy-30)and touchState.y  < (qy+30) then		 
					if getValue('Sats') >= 6 then
						message("Home refreshed")
						playTone(1500, 100, 0)
						home_fixed = 1
						home_x = lon
						home_y = lat	
					else
						message("GPS sats < 6")
					end				
				end
			end

			if get_touch(touchState.x,touchState.y,lx-18-15,54-12,lx-18+15,54+12) == 1 and screenshot_enable == 1 then 
				screenshot()
				message("Screenshot success")
			end
		end	

	else 
		if event == EVT_TOUCH_FIRST then
			if touchState.x>(lx-40) and touchState.x < lx and touchState.y and touchState.y < 40 then
				param_edit = 0
			elseif touchState.x < (hx-20) then
				param_edit = 0
			end
			touch_x_old = touchState.x
			touch_y_old = touchState.y
			setup_y_temp = setup_y
			touch_slide_flag = 0
		end
		if event == EVT_TOUCH_SLIDE then
			local temp =  touchState.y - touch_y_old
			touch_slide_flag = 1
			setup_y = setup_y_temp + temp	
			if setup_y > 20 then
				setup_y = 20
			end
			if setup_y < (setup_y_max-20) then
				setup_y = setup_y_max-20
			end			
		end
		if event == EVT_TOUCH_BREAK then
			if setup_y > 0 then
				setup_y = 0
			end		
			if setup_y < setup_y_max then
				setup_y = setup_y_max
			end		
			if touch_slide_flag == 0 then 
				if get_touch(touch_x_old,touch_y_old,420,setup_y +60-12,460,setup_y +60+12) == 1 then
					setup_status[1] = 1- setup_status[1] 	
					save (1,setup_status[1])
				end
				if get_touch(touch_x_old,touch_y_old,420,setup_y +85-12,460,setup_y +85+12) == 1 then
					setup_status[2] = 1- setup_status[2] 	
					save (2,setup_status[2])
				end
				if get_touch(touch_x_old,touch_y_old,420,setup_y +110-12,460,setup_y +110+12) == 1 then
					setup_status[3] = 1- setup_status[3] 	
					save (3,setup_status[3])
				end
				if get_touch(touch_x_old,touch_y_old,420,setup_y +135-12,460,setup_y +135+12) == 1 then
					setup_status[4] = 1- setup_status[4] 	
					save (4,setup_status[4])
				end
			end
		end
	end
	if param_edit == 0 then
		if event == 1540 or event == 1539 then
			if hud_mode == 0 then 
				hud_mode = 1
			elseif hud_mode == 1 then 
				hud_mode = 2
			elseif hud_mode == 2 then 
				hud_mode = 0						
			end
			playTone(1500, 100, 0)
		end

		if event == EVT_ENTER_BREAK then
			param_edit = 1
			playTone(1500, 100, 0)
		end

		if event == 524 then
			playTone(1500, 100, 0)
			if hud_size > 1 then
				hud_size = hud_size -1
			else
				hud_size = 3
			end
		end

		if event == 1036 then
			playTone(1500, 100, 0)
			screenshot()
			message("Screenshot success")
		end

		if event == 2050 then
			playTone(1500, 100, 0)
			if getValue('Sats') >= 6 then
				message("Home refreshed")
				playTone(1500, 100, 0)
				home_fixed = 1
				home_x = lon
				home_y = lat	
			else
				message("GPS sats < 6")
			end		
		end

		if event == EVT_EXIT_BREAK then
			exitscript = 1
		end	
	else 	
		if event == EVT_EXIT_BREAK then
			playTone(1500, 100, 0)
			if param_edit == 1 then
				param_edit = 0		
			end
		end	
	end

	if event_old ~= event and event ~= 0then
		event_old = event
		
		event_num[event_i] = event
		if event_i < 5 then
			event_i = event_i + 1
		else
			event_i = 1
		end		
	end

	time = getTime()
	fps_temp = fps_temp + 1
	if ( time - time_old ) > 100 then
		second = second + 1
		time_old = time
		fps = fps_temp
		fps_temp = 0
		ID_5006_hz = ID_5006_temp
		ID_5006_temp = 0
	end

	if ( time - time_old2 ) > 10 then
		time_old2 = time
		message_time = message_time - 1
	end

	return exitscript
end

return { init=init, run=run }