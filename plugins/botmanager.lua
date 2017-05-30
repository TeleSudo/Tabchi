do
local function saveplug(extra, success, result)
  local msg = extra.msg
  local name = extra.name
  local receiver = get_receiver(msg)
  if success then
    local file = 'plugins/'..name..'.lua'
    print('File saving to:', result)
    os.rename(result, file)
    print('File moved to:', file)
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end
local function savefile(extra, success, result)
  local msg = extra.msg
  local name = extra.name
  local receiver = get_receiver(msg)
  if success then
    local file = name
    print('File saving to:', result)
    os.rename(result, file)
    print('File moved to:', file)
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end
local function plugin_enabled( name )
  for k,v in pairs(_config.enabled_plugins) do
    if name == v then
      return k
    end
  end
  -- If not found
  return false
end

local function plugin_exists( name )
  for k,v in pairs(plugins_names()) do
    if name..'.lua' == v then
      return true
    end
  end
  return false
end

local function list_all_plugins(only_enabled)
  local text = ''
  local nsum = 0
  for k, v in pairs( plugins_names( )) do
    local status = 'D - '
    nsum = nsum+1
    nact = 0
    for k2, v2 in pairs(_config.enabled_plugins) do
      if v == v2..'.lua' then 
        status = 'E - '
      end
      nact = nact+1
    end
    if not only_enabled or status == 'E - ' then

      v = string.match (v, "(.*)%.lua")
      text = text..status..v..'\n'
    end
  end
  local text = text.."E : "..nact.." | I : "..nsum.." | D : "..nsum-nact
  return text
end

local function list_plugins(only_enabled)
  local text = ''
  local nsum = 0
  for k, v in pairs( plugins_names( )) do
    --  ?? enabled, disabled disabled
    local status = 'D - '
    nsum = nsum+1
    nact = 0
    -- Check if is enabled
    for k2, v2 in pairs(_config.enabled_plugins) do
      if v == v2..'.lua' then 
        status = 'E - ' 
      end
      nact = nact+1
    end
    if not only_enabled or status == '??' then

      v = string.match (v, "(.*)%.lua")
      text = text..status..v..'\n'
    end
  end
  local text = text.."E : "..nact.." | I : "..nsum.." | D : "..nsum-nact
  return text
end

local function reload_plugins( )
  plugins = {}
  load_plugins()
end


local function enable_plugin( plugin_name )
  print('checking if '..plugin_name..' exists')

  if plugin_enabled(plugin_name) then
    return 'Plugin '..plugin_name..' is enabled'
  end

  if plugin_exists(plugin_name) then

    table.insert(_config.enabled_plugins, plugin_name)
    print(plugin_name..' added to _config table')
    save_config()
    return reload_plugins( )
  else
    return 'Plugin '..plugin_name..' does not exists'
  end
end

local function run(msg, matches)
local receiver = get_receiver(msg)
local group = msg.to.id
if matches[1] == "addplug" and is_sudo(msg) then
	local name = matches[2]
	if #matches == 2 then
		if msg.reply_id then
			load_document(msg.reply_id, savefile, {msg=msg,name=name})
		end
	else
		local file = io.open("plugins/"..name..".lua", "w")
		local text = matches[3]
		file:write(text)
		file:flush()
		file:close()
	end
    return 'Plugin Saved'
end
if matches[1] == "save" and is_sudo(msg) then
	local name = matches[2]
	if #matches == 2 then
		if msg.reply_id then
			load_document(msg.reply_id, savefile, {msg=msg,name=name})
		end
	else
		local file = io.open(name, "w")
		local text = matches[3]
		file:write(text)
		file:flush()
		file:close()
	end
    return 'File Saved'
end
if matches[1]:lower() == 'send' and is_sudo(msg) then
send_document(get_receiver(msg), "plugins/"..matches[2]..".lua", ok_cb, false)
end
if matches[1]:lower() == 'send>' and is_sudo(msg) then
 local plg = io.popen("cat plugins/"..matches[2]..".lua" ):read('*all')
  return plg
end
if matches[1] == "dl" then
send_document(get_receiver(msg), matches[2], ok_cb, false)
end
if matches[1]:lower() == 'show' and is_sudo(msg) then
 local plg = io.popen("cat "..matches[2] ):read('*all')
  return plg
end
  if matches[1] == 'plist' and is_sudo(msg) then --after changed to moderator mode, set only sudo
    return list_all_plugins()
  end

  if matches[1] == '+' and is_sudo(msg) then --after changed to moderator mode, set only sudo
    local plugin_name = matches[2]
    print("enable: "..matches[2])
    enable_plugin(plugin_name)
    return "Enabled"
  end

  if matches[1] == '-' and is_sudo(msg) then
    if matches[2] == 'plugins' then
    	return 'This plugin can\'t be disabled'
    end
    print("disable: "..matches[2])
    disable_plugin(matches[2])
    return "Disabled"
  end

  if matches[1] == '*' and is_sudo(msg) then
    reload_plugins(true)
    return "Reloaded"
  end
end

return {

  patterns = {
    "^[!/#](plist)$",
    "^[!/#]pl (+) ([%w_%.%-]+)$",
    "^[!/#]pl (-) ([%w_%.%-]+)$",
    "^[!/#]pl (*)$",
	"^[!/#]([Aa]ddplug) (.*)$",
	"^[!/#]([Aa]ddplug) (.+) (.*)$",
	"^[!/#]([Ss]ave) (.*)$",
	"^[!/#]([Ss]ave) (.+) (.*)$",
	"^[!/#]([Ss]end) (.*)$",
	"^[!/#]([Ss]end>) (.*)$",
	"^[!/#]([Ss]how) (.*)$",
	},
  run = run,
}

end
