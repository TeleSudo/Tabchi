local sudomsg = 282958812 -- put your id here
local function reload_plugins( )
  plugins = {}
  load_plugins()
end

function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

local function parsed_url(link)
  local parsed_link = URL.parse(link)
  local parsed_path = URL.parse_path(parsed_link.path)
  return parsed_path[2]
end


function pre_process(msg)
if msg.media then
  if msg.media.type:match("contact") then
    add_contact(msg.media.phone, ""..(msg.media.first_name or "-").."", ""..(msg.media.last_name or "-").."", ok_cb, false)
	  local hash = ('bot:pm') 
    local pm = redis:get(hash) 
    if not pm then 
	 return reply_msg(msg.id,'ادی گلم پیوی', ok_cb, false)
	 else
	  return reply_msg(msg.id,pm, ok_cb, false)
	  end
  elseif msg.media.caption then
    if msg.media.caption:match("(https://telegram.me/joinchat/%S+)") then
      local link = {msg.media.caption:match("(https://telegram.me/joinchat/%S+)")} 
      if string.len(link[1]) == 51 then
        redis:sadd("selfbot:links",link[1])
        import_chat_link(parsed_url(link[1]),ok_cb,false)
      end
    end
	if msg.media.caption:match("(https://t.me/joinchat/%S+)") then
      local link = {msg.media.caption:match("(https://t.me/joinchat/%S+)")}
      if string.len(link[1]) == 44 then
        redis:sadd("selfbot:links",link[1])
        import_chat_link(parsed_url(link[1]),ok_cb,false)
      end
    end
	if msg.media.caption:match("(https://telegram.dog/joinchat/%S+)") then
      local link = {msg.media.caption:match("(https://telegram.dog/joinchat/%S+)")}
      if string.len(link[1]) == 52 then
        redis:sadd("selfbot:links",link[1])
        import_chat_link(parsed_url(link[1]),ok_cb,false)
      end
    end
  end
end
if msg.from.phone then
  add_contact(msg.from.phone, ""..(msg.from.first_name or "-").."", ""..(msg.from.last_name or "-").."", ok_cb, false)
end
return msg
end
function lua(str)
  local output = loadstring(str)()
  if output == nil then
    output = ''
  elseif type(output) == 'table' then
    output = 'Done! Table returned.'
  else
    output = ""..tostring(output)
  end
  return output
end

function add_all_members(extra, success, result)
  local msg = extra.msg
  if msg.to.type == "channel" then
    for k,v in pairs(result) do
      if v.id then
	    channel_invite(get_receiver(msg),"user#id"..v.id,ok_cb,false)
	  end
	end
  end
end

function export_links(msg)
  local text = "Group Links :\n"
  for i=1,#links do
    if string.len(links[i]) ~= 51 then
      redis:srem("selfbot:links",links[i])
    else
      text = text..links[i].."\n"
    end
  end
  local file = io.open("group_links.txt","w")
  file:write(text)
  file:flush()
  file:close()
  send_document(get_receiver(msg),"group_links.txt",ok_cb,false)
end

local function getindex(t,id) 
for i,v in pairs(t) do 
if v == id then 
return i 
end 
end 
return nil 
end 

function reset_stats()
  redis:set("pv:msgs",0)
  redis:set("gp:msgs",0)
  redis:set("supergp:msgs",0)
  redis:del("selfbot:groups",0)
  redis:del("selfbot:users",0)
  redis:del("selfbot:supergroups",0)
end

function broad_cast(text)
local gps = redis:smembers("selfbot:groups")
local sgps = redis:smembers("selfbot:supergroups")
local users = redis:smembers("selfbot:users")
  for i=1, #gps do
    send_large_msg(gps[i],text,ok_cb,false)
  end
  for i=1, #sgps do
    send_large_msg(sgps[i],text,ok_cb,false)
  end
  for i=1, #users do
    send_large_msg(users[i],text,ok_cb,false)
  end
end

function broad_castpv(text)
local users = redis:smembers("selfbot:users")
for i=1, #users do
    send_large_msg(users[i],text,ok_cb,false)
  end
end

function broad_castgp(text)
local gps = redis:smembers("selfbot:groups")
for i=1, #gps do
    send_large_msg(gps[i],text,ok_cb,false)
  end
end
function broad_castsgp(text)
local sgps = redis:smembers("selfbot:supergroups")
 for i=1, #sgps do
    send_large_msg(sgps[i],text,ok_cb,false)
  end
end

function run_bash(str)
  local cmd = io.popen(str)
  local result = cmd:read('*all')
  cmd:close()
  return result
end

function set_bot_photo(msg, success, result)
  local receiver = get_receiver(msg)
  if success then
    local file = 'data/photos/bot.jpg'
    print('File downloaded to:', result)
    os.rename(result, file)
    print('File moved to:', file)
    set_profile_photo(file, ok_cb, false)
    send_large_msg(receiver, 'Photo changed!', ok_cb, false)
    redis:del("bot:photo")
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end
function get_contact_list_callback (cb_extra, success, result)
  local text = " "
  for k,v in pairs(result) do
    if v.print_name and v.id and v.phone then
      text = text..string.gsub(v.print_name ,  "_" , " ").." ["..v.id.."] = "..v.phone.."\n"
    end
  end
  local file = io.open("contact_list.txt", "w")
  file:write(text)
  file:flush()
  file:close()
  send_document("user#id"..cb_extra.target,"contact_list.txt", ok_cb, false)--.txt format
  local file = io.open("contact_list.json", "w")
  file:write(json:encode_pretty(result))
  file:flush()
  file:close()
  send_document("user#id"..cb_extra.target,"contact_list.json", ok_cb, false)--json format
end

function stats(cb_extra, success, result)
  local i = 0
  for k,v in pairs(result) do
    i = i+1
  end
   local text = "🍃Private User🍃\n♦️"..users2.."♦️\n💭Private Messages Recived💭:\n♦️"..pvmsgs.."♦️\n\n💠Groups💠:\n♦️"..gps2.."♦️\n🔰Groups Messages🔰:\n♦️"..gpmsgs.."♦️\n\n🌐SuperGroups🌐:\n♦️"..sgps2.."♦️\n✳️SuperGroup Messages✳️ :\n♦️"..sgpmsgs.."♦️\n\n💢Total Saved Links💢:\n ♦️"..#links.."♦️\n⚜️Total Saved Contacts⚜️:\n ♦️"..i.."♦️"
  send_large_msg(get_receiver(cb_extra.msg),text, ok_cb, false)
end

function run(msg,matches)
if matches[1] == "settext" then 
if not is_sudo(msg) then 
return 'شما سودو نیستید' 
end 
local pm = matches[2] 
redis:set('bot:pm',pm) 
return 'متن پاسخ گویی ثبت شد' 
end 

if matches[1] == "pm" and is_sudo(msg) then
local hash = ('bot:pm') 
    local pm = redis:get(hash) 
    if not pm then 
    return ' ثبت نشده' 
    else 
	   return 'پیغام کنونی:\n\n'..pm
    end
end
if matches[1]== "help" and is_sudo(msg) then
local text =[[
🍃TTabchiHelp By @LuaError🍃
---------------------------------
♦️Brodcast Option🍃
🔶!pm [Id] [Text]
ارسال پیام به ایدی موردنظر
🔷!bcpv [text]
ارسال پیغام همگانی به پیوی
🔶!bcgp [text]
ارسال پیغام همگانی به گروه ها
🔷!bcsgp [text]
ارسال پیغام همگانی به سوپرگروها
🔶!bc [text]
ارسال پیغام همگانی
🔷!fwdpv {reply on msg}
ارسال به پیوی کاربران
🔶!fwdgp {reply on msg}
ارسال به گروه ها
🔷!fwdsgp {reply on msg}
ارسال به سوپرگروها
🔶!fwdall {reply on msg}
فوروارد همگانی 
---------------------------------
♦️User Option:
🔷!block [Id]
بلاک کردن فرد مورد نظر
🔶!unblock [id]
انبلاک کردن فرد مور نظر
---------------------------------
♦️Contacts Option 🍃
🔷!addcontact [phone] [FirstName][LastName]
اضافه کردن یک کانتکت
🔶!delcontact [phone] [FirstName][LastName]
حذف کردن یک کانتکت
🔷!sendcontact [phone] [FirstName][LastName]
ارسال یک کانتکت
🔶!contactlist
دریافت لیست کانتکت ها
---------------------------------
♦️Robot Advanced Option 🍃
🔷!markread [on]/[off]
روشن و خاموش کردن تیک مارک رید
🔶!setphoto {on reply photo}
ست کردن پروفایل ربات
🔷!stats
دریافت آمار ربات
🔶!addmember
اضافه کردن کانتکت های ربات به گروه
🔷!echo [text]
برگرداندن نوشته
🔶!export links
دریافت لینک های ذخیره شده
🔷!settext [text]
تنظیم پیام ادشدن کانتکت
🔶!reload
ریلود کردن ربات
🔷!addsudo [id]
اضافه کردن سودو
🔶!remsudo [id]
اضافه کردن سودو
🔷!serverinfo
نمایش وضعیت سورس
🔶!addtoall [id]
اضافه کردن مخاطب به گروها
🔷!reset stats
ریست کردن امار ربات
🔶!leave 
لفت دادن ربات ازگروه جاری
🔷!leave [id]
لفت دادن ربات ازگروه موردنظر
🔶!myinfo
دریافت اطلاعات 
---------------------------------
🔷channel : @LuaError 🍃
]]
return text
end
  if matches[1] == "setphoto" and msg.reply_id and is_sudo(msg) then
    load_photo(msg.reply_id, set_bot_photo, msg)
    return 'Photo Changed'
  end
  if matches[1] == "markread" then
    if matches[2] == "on" and is_sudo(msg) then
      redis:set("bot:markread", "on")
      return "Mark read > on"
    end
    if matches[2] == "off" and is_sudo(msg) then
      redis:del("bot:markread")
      return "Mark read > off"
    end
    return
  end
  if matches[1] == "text" and is_sudo(msg) then
    send_large_msg("user#id"..matches[2],matches[3])
    return "Message has been sent"
  end 
  if matches[1] == "block" and is_sudo(msg) then
    block_user("user#id"..matches[2],ok_cb,false)
    return "User blocked"
  end
  if matches[1] == "unblock" and is_sudo(msg) then
    unblock_user("user#id"..matches[2],ok_cb,false)
    return "User unblocked"
  end
  if matches[1] == "contactlist" then
    if not is_sudo(msg) then
      return
    end
    get_contact_list(get_contact_list_callback, {target = msg.from.id})
    return "I've sent contact list with both json and text format to your private"
   end
  if matches[1] == "addmember" and msg.to.type == "channel" then
    if not is_sudo(msg) then-- Sudo only
      return "not sudo "
    end
    local users = redis:smembers("selfbot:users")
    get_contact_list(add_all_members, {msg = msg})
    for i=1, #users do
      channel_invite(get_receiver(msg),users[i],ok_cb,false)
    end
    return "All Contacts Invited To Group"
  end
  if matches[1] == "stats" then
    if not is_sudo(msg) then-- Sudo only
      return
    end
    get_contact_list(stats, {msg = msg})
  end
  if matches[1] == "delcontact" then
    if not is_sudo(msg) then-- Sudo only
      return
    end
    del_contact("user#id"..matches[2],ok_cb,false)
    return "User "..matches[2].." removed from contact list"
  end
  if matches[1] == "addcontact" and is_sudo(msg) then
    phone = matches[2]
    first_name = matches[3]
    last_name = matches[4]
    add_contact(phone, first_name, last_name, ok_cb, false)
    return "User With Phone +"..matches[2].." has been added"
  end
  if matches[1] == "sendcontact" and is_sudo(msg)then
    phone = matches[2]
    first_name = matches[3]
    last_name = matches[4]
    send_contact(get_receiver(msg), phone, first_name, last_name, ok_cb, false)
  end
  if msg.text:match("^[$](.*)$") and is_sudo(msg) then
    return run_bash(matches[1])
  end
  if matches[1] == "export" and matches[2] == "links" and is_sudo(msg) then
    return export_links(msg)
  end
  if matches[1] == "bc" and is_sudo(msg) then
    broad_cast(matches[2])
  end
  if matches[1] == "bcpv" and is_sudo(msg) then
    broad_castpv(matches[2])
  end
  if matches[1] == "bcgp" and is_sudo(msg) then
    broad_castgp(matches[2])
  end
  if matches[1] == "bcsgp" and is_sudo(msg) then
    broad_castsgp(matches[2])
  end
  if matches[1] == "fwdall" and msg.reply_id and is_sudo(msg) then
  local id = msg.reply_id
  local gps = redis:smembers("selfbot:groups")
  local sgps = redis:smembers("selfbot:supergroups")
  local users = redis:smembers("selfbot:users")
  for i=1, #sgps do
    fwd_msg(sgps[i],id,ok_cb,false)
  end
  for i=1, #gps do
    fwd_msg(gps[i],id,ok_cb,false)
  end
  for i=1, #users do
    fwd_msg(users[i],id,ok_cb,false)
  end
  return "Sent"
  end
  if matches[1]=="fwdpv" then
  local id = msg.reply_id
  local users = redis:smembers("selfbot:users")
  for i=1, #users do
    fwd_msg(users[i],id,ok_cb,false)
  end
  return "Sent All Private"
  end
  if matches[1]=="fwdgp" then
  local id = msg.reply_id
  local gps = redis:smembers("selfbot:groups")
  for i=1, #gps do
    fwd_msg(gps[i],id,ok_cb,false)
  end
  return "Sent All Group"
  end
  if matches[1]=="fwdsgp" then
  local id = msg.reply_id
    local sgps = redis:smembers("selfbot:supergroups")
	for i=1, #sgps do
    fwd_msg(sgps[i],id,ok_cb,false)
  end
   return "Sent All SuperGroups"
  end
  if matches[1] == "lua" and is_sudo(msg) then
    return lua(matches[2])
  end
  if matches[1] == "echo" and is_sudo(msg) then
    return matches[2]
  end
  if msg.text:match("https://telegram.me/joinchat/%S+") then
    if string.len(matches[1]) == 51 and not redis:sismember("selfbot:links",matches[1]) then
      redis:sadd("selfbot:links",matches[1])
      import_chat_link(parsed_url(matches[1]),ok_cb,false)
    end
  end
  if  msg.text:match("https://t.me/joinchat/%S+") then
    if string.len(matches[1]) == 44 and not redis:sismember("selfbot:links",matches[1]) then
      redis:sadd("selfbot:links",matches[1])
      import_chat_link(parsed_url(matches[1]),ok_cb,false)
    end
  end
  if  msg.text:match("https://telegram.dog/joinchat/%S+") then
    if string.len(matches[1]) == 52 and not redis:sismember("selfbot:links",matches[1]) then
      redis:sadd("selfbot:links",matches[1])
      import_chat_link(parsed_url(matches[1]),ok_cb,false)
    end
  end
  if matches[1] == 'addsudo' then
if msg.from.id and msg.from.id == tonumber(sudomsg) then
table.insert(_config.sudo_users,tonumber(matches[2]))
    print(matches[2]..' added to sudo users')
    save_config()
  reload_plugins(true)
  return "User "..matches[2].." added to sudo users"
  else
  return "error"
  end
  end
  
  if matches[1] == 'remsudo' then
if msg.from.id and msg.from.id == tonumber(sudomsg) then
 table.remove(_config.sudo_users, getindex( _config.sudo_users, tonumber(msg.to.id)))
    print(matches[2]..' added to sudo users')
    save_config()
  reload_plugins(true)
  return "User "..matches[2].." remove from sudo users"
  else
  return "error"
  end
  end
if matches[1]== "serverinfo" and is_sudo(msg) then
local text = io.popen("sh ./data/cmd.sh"):read('*all')
  return text
end
  if matches[1]== "addtoall" and is_sudo(msg) then
  local sgps = redis:smembers("selfbot:supergroups")
    for i=1, #sgps do
     channel_invite(sgps[i],matches[2],ok_cb,false)
    end
  return"user ♦️"..matches[2].."♦️ Added To all SuperGroup\n SuperGroup Stats ♦️" ..#sgps.. "♦️"
  end
  if matches[1]=="reset stats" then
  reset_stats()
  return"Stats HasBeen Reset"
  end
  if matches[1]== "leave" and is_sudo(msg) then
  local receiver = get_receiver(msg)
    leave_channel(receiver, ok_cb, false)
  end
  if matches[1]=="leave" and is_sudo(msg) then
  leave_channel(matches[2], ok_cb, false)
  send_large_msg(msg.to.id,"Robot Left "..matches[2],ok_cb,false)
  end
  if matches[1]=="myinfo" and is_sudo(msg) then
  return "♦️YourName♦️"..msg.from.first_name.."\n♦️YourId♦️"..msg.from.id.."\n♦️Group Id♦️"..msg.to.id.."\n@LuaError"
  end
  if matches[1]=="leaveall" and is_sudo(msg) then
   for i=1, #sgps do
  leave_channel(sgps[i], ok_cb, false)
  end
  send_large_msg(msg.to.id,"Robot Left "..matches[2],ok_cb,false)	
  end
end
return {
patterns = {
  "^[#!/](pm) (%d+) (.*)$",
  "^[#!/](unblock) (%d+)$",
  "^[#!/](block) (%d+)$",
  "^[#!/](markread) (on)$",
  "^[#!/](markread) (off)$",
  "^[#!/](setphoto)$",
  "^[#!/](contactlist)$",
  "^[#!/](addmember)$",
  "^[#!/](stats)$",
  "^[#!/](delcontact) (%d+)$",
  "^[#!/](addcontact) (.*) (.*) (.*)$", 
  "^[#!/](sendcontact) (.*) (.*) (.*)$",
  "^[#!/](echo) (.*)$",
  "^[#!/](export) (links)$",
  "^[#!/](bc) (.*)$",
  "^[#!/](bcpv) (.*)$",
  "^[#!/](bcgp) (.*)$",
  "^[#!/](bcsgp) (.*)$",
  "^[#!/](fwdall)$",
  "^[#!/](fwdpv)$",
  "^[#!/](fwdgp)$",
  "^[#!/](fwdsgp)$",
  "^[!/#](lua) (.*)$",
  "^[!/#](settext) (.*)$",
  "^[!/#](text)$",
  "^[!/#](help)$",
  "^[!/#](addsudo) (.*)$",
  "^[!/#](remsudo) (.*)$",
  "^[!/#](serverinfo)$",
  "^[!/#](addtoall) (.*)$",
  "^[!/#](leave) (.*)$",  
  "^[!/#](leave)$",  
  "^[!/#](myinfo)$",  
  "^[!/#](reset stats)$",
  "^[!/#](leaveall)$",
  "(https://telegram.me/joinchat/%S+)",
  "(https://t.me/joinchat/%S+)",
  "(https://telegram.dog/joinchat/%S+)",
  "^[$](.*)$"
},
run = run,
pre_process = pre_process
}
--@LuaError
--@Tele_Sudo
