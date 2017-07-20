-- Start TabchiBot
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


function sleep(n)
  os.execute("sleep" .. tonumber(n))
end

function pre_process(msg)
if msg.media then
  if msg.media.type:match("contact") and redis:get("bot:addcontacts") == "on" then
    add_contact(msg.media.phone, ""..(msg.media.first_name or "-").."", ""..(msg.media.last_name or "-").."", ok_cb, false)
	  local hash = ('bot:pm') 
    local pm = redis:get(hash)
 if redis:get("bot:addedmsg") == "on" then
    if not pm then 
	 return reply_msg(msg.id,'ادی گلم پیوی', ok_cb, false)
	 else
	  return reply_msg(msg.id,pm, ok_cb, false)
	  end
	end
  elseif msg.media.caption then
    if msg.media.caption:match("(https://telegram.me/joinchat/%S+)") and redis:get("bot:autojoin") == "on" then
      local link = {msg.media.caption:match("(https://telegram.me/joinchat/%S+)")} 
      if string.len(link[1]) == 51 then
        redis:sadd("selfbot:links",link[1])
        import_chat_link(parsed_url(link[1]),ok_cb,false)
      end
    end
	if msg.media.caption:match("(https://t.me/joinchat/%S+)") and redis:get("bot:autojoin") == "on" then
      local link = {msg.media.caption:match("(https://t.me/joinchat/%S+)")}
      if string.len(link[1]) == 44 then
        redis:sadd("selfbot:links",link[1])
        import_chat_link(parsed_url(link[1]),ok_cb,false)
      end
    end
	if msg.media.caption:match("(https://telegram.dog/joinchat/%S+)") and redis:get("bot:autojoin") == "on" then
      local link = {msg.media.caption:match("(https://telegram.dog/joinchat/%S+)")}
      if string.len(link[1]) == 52 then
        redis:sadd("selfbot:links",link[1])
        import_chat_link(parsed_url(link[1]),ok_cb,false)
      end
    end
  end
end
if msg.from.phone and redis:get("bot:addcontacts") == "on" then
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
  redis:del("selfbot:groups")
  redis:del("selfbot:users")
  redis:del("selfbot:supergroups")
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

function set_bot_photo(receiver, success, result)
	if success then
		local file = 'botBOT-ID.jpg'
		os.rename(result, file)
		set_profile_photo(file, ok_cb, false)
		send_msg(receiver, 'Photo changed!', ok_cb, false)
	else
		send_msg(receiver, 'Failed, please try again!', ok_cb, false)
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
    local text = "<b>─═हई Tebchi Stats ईह═─</b>\n<i>》Private User ➣</i> <code>"..users2.."</code>\n<i>》PrivateMessages Recived➣</i> <code>"..pvmsgs.."</code>\n➖➖➖➖➖➖➖➖\n<i>》Groups➣</i> <code>"..gps2.."</code>\n<i>》Groups Messages➣</i> <code>"..gpmsgs.."</code>\n➖➖➖➖➖➖➖➖\n<i>》SuperGroups➣</i> <code>"..sgps2.."</code>\n<i>》SuperGroup Messages➣</i> <code>"..sgpmsgs.."</code>\n➖➖➖➖➖➖➖➖\n<i>》Total Saved Links➣</i> <code>"..#links.."</code>\n<i>》Total Saved Contacts➣</i> <code>"..i.."</code>\n<i>PowerBy》</i> @LuaError"
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
if matches[1] == "autojoin" and is_sudo(msg) then
if matches[2] == "on" then
redis:set("bot:autojoin", "on")
return "جوین خودکار فعال شد"
end
if matches[2] == "off" then
redis:set("bot:autojoin", "off")
return "جوین خودکار غیرفعال شد"
end
end
if matches[1] == "addedmsg" and is_sudo(msg) then
if matches[2] == "on" then
redis:set("bot:addedmsg", "on")
return 'پیام اضافه شدن کانتکت فعال شد'
end
if matches[2] == "off" then
redis:set("bot:addedmsg", "off")
return'پیام اضافه شدن کانتکت غیرفعال شد'
end
end
if matches[1] == "addcontacts" and is_sudo(msg) then
if matches[2] == "on" then
redis:set("bot:addcontacts", "on")
return 'اضافه شدن کانتکت فعال شد'
end
if matches[2] == "off" then
redis:set("bot:addcontacts", "off")
return 'اضافه شدن کانتکت غیرفعال شد'
end
end
if matches[1]== "help" and is_sudo(msg) then
local text =[[
➣➣TabchiHelp By @LuaError
<code>---------------------------------</code>
<b>─═हई Brodcast Help ईह═─</b>
<code>》!pm [Id] [Text]</code>
<i>ارسال پیام به ایدی موردنظر</i>
<code>》!bcpv [text]</code>
<i>ارسال پیغام همگانی به پیوی</i>
<code>》!bcgp [text]</code>
<i>ارسال پیغام همگانی به گروه ها</i>
<code>》!bcsgp [text]</code>
<i>ارسال پیغام همگانی به سوپرگروها</i>
<code>》!bc [text]</code>
<i>ارسال پیغام همگانی</i>
<code>》!fwdpv {reply on msg}</code>
<i>ارسال به پیوی کاربران</i>
<code>》!fwdgp {reply on msg}</code>
<i>ارسال به گروه ها</i>
<code>》!fwdsgp {reply on msg}</code>
<i>ارسال به سوپرگروها</i>
<code>》!fwdall {reply on msg}</code>
<i>فوروارد همگانی </i>
<code>---------------------------------</code>
<b>─═हई User Help ईह═─</b>
<code>》!block [Id]</code>
<i>بلاک کردن فرد مورد نظر</i>
<code>》!unblock [id]</code>
<i>انبلاک کردن فرد مور نظر</i>
<code>---------------------------------</code>
<b>─═हई Contacts Help  ईह═─</b>
<code>》!addcontact [phone] [FirstName][LastName]</code>
<i>اضافه کردن یک کانتکت</i>
<code>》!delcontact [phone] [FirstName][LastName]</code>
<i>حذف کردن یک کانتکت</i>
<code>》!sendcontact [phone] [FirstName][LastName]</code>
<i>ارسال یک کانتکت</i>
<code>》!contactlist</code>
<i>دریافت لیست کانتکت ها</i>
<code>---------------------------------</code>
<b>─═हई  Settings Help ईह═─</b>
<code>》!autojoin [on][off]</code> 
<i>خاموش و روشن شدن جوین دادن تبچی</i>
<code>》!addedmsg [on][off]</code>
<i>خاموش وروشن کردن پیام اد کانتکت</i>
<code>》!addcontacts [on][off]</code>
<i>خاموش و روشن کردن اد شدن اکانت</i>
<code>》!settext [text]</code>
<i>تنظیم پیام ادشدن کانتکت</i>
<code>---------------------------------</code>
<b>─═हई Sudo Help ईह═─</b>
<code>》!reload</code>
<i>ریلود کردن ربات</i>
<code>》!addsudo [id]</code>
<i>اضافه کردن سودو</i>
<code>》!remsudo [id]</code>
<i>اضافه کردن سودو</i>
<code>》!serverinfo</code>
<i>نمایش وضعیت سورس</i>
<code>---------------------------------</code>
<b>─═हई Robot Advanced Help ईह═─</b>
<code>》!markread [on]/[off]</code>
<i>روشن و خاموش کردن تیک مارک رید</i>
<code>》!setphoto {on reply photo}</code>
<i>ست کردن پروفایل ربات</i>
<code>》!stats</code>
<i>دریافت آمار ربات</i>
<code>》!addmember</code>
<i>اضافه کردن کانتکت های ربات به گروه</i>
<code>》!echo [text]</code>
<i>برگرداندن نوشته</i>
<code>》!export links</code>
<i>دریافت لینک های ذخیره شده</i>
<code>》!addtoall [id]</code>
<i>اضافه کردن مخاطب به گروها</i>
<code>》!reset stats</code>
<i>ریست کردن امار ربات</i>
<code>》!leave </code>
<i>لفت دادن ربات ازگروه جاری</i>
<code>》!leave [id]</code>
<i>لفت دادن ربات ازگروه موردنظر</i>
<code>》!leaveall</code>
<i>لفت دادن ربات ازتمامی گروها</i>
<code>》!myinfo</code>
<i>دریافت اطلاعات</i>
<code>---------------------------------</code>
PowerBy 》@LuaError 
]]
return text
end
  if matches[1] == "setphoto" and msg.reply_id and is_sudo(msg) then
   load_photo(msg.reply_id, set_bot_photo, receiver)
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
  if redis:get("timetext:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
	redis:setex("timetext:"..msg.to.id,1800,true)
    send_large_msg("user#id"..matches[2],matches[3])
    return "پیام ارسال شد"
  end 
  if matches[1] == "block" and is_sudo(msg) then
    block_user("user#id"..matches[2],ok_cb,false)
    return "کاربر بلاک شد"
  end
  if matches[1] == "unblock" and is_sudo(msg) then
    unblock_user("user#id"..matches[2],ok_cb,false)
    return "کاربر انبلاک شد"
  end
  if matches[1] == "contactlist" then
    if not is_sudo(msg) then
      return
    end
    get_contact_list(get_contact_list_callback, {target = msg.from.id})
    return "لیست کانتکت ها به پرایوت شما ارسال شد"
   end
  if matches[1] == "addmember" and msg.to.type == "channel"  and is_sudo(msg) then
	if redis:get("timeaddmem:"..msg.to.id) then
    return "<i>این کار فقط هر 10 دقیقه یکبار ممکن میباشد</i>"
    end
	redis:setex("timeaddmem:"..msg.to.id,600,true)
    local users = redis:smembers("selfbot:users")
    get_contact_list(add_all_members, {msg = msg})
    for i=1, #users do
      channel_invite(get_receiver(msg),users[i],ok_cb,false)
    end
    return "تمام مخاطب ها وارد گروه شدند"
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
    return "کاربر "..matches[2].." از لیست کانتکت ها پاک شد"
  end
  if matches[1] == "addcontact" and is_sudo(msg) then
    phone = matches[2]
    first_name = matches[3]
    last_name = matches[4]
    add_contact(phone, first_name, last_name, ok_cb, false)
    return "کاربر با شماره تلفن  +"..matches[2].." به لیست کانتکت ها اضافه شد"
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
  if redis:get("timebc:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
	redis:setex("timebc:"..msg.to.id,1800,true)
    broad_cast(matches[2])
  end
  if matches[1] == "bcpv" and is_sudo(msg) then
  if redis:get("timebcpv:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
	 redis:setex("timebcpv:"..msg.to.id,1800,true)
    broad_castpv(matches[2])
  end
  if matches[1] == "bcgp" and is_sudo(msg) then
  if redis:get("timebcgp:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
	 redis:setex("timebcgp:"..msg.to.id,1800,true)
    broad_castgp(matches[2])
  end
  if matches[1] == "bcsgp" and is_sudo(msg) then
  if redis:get("timebcsgp:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
	 redis:setex("timebcsgp:"..msg.to.id,1800,true)
    broad_castsgp(matches[2])
  end
  if matches[1] == "fwdall" and msg.reply_id and is_sudo(msg) then
  if redis:get("timefwdall:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
  local id = msg.reply_id
  local gps = redis:smembers("selfbot:groups")
  local sgps = redis:smembers("selfbot:supergroups")
  local users = redis:smembers("selfbot:users")
  for i=1, #sgps do
    fwd_msg(sgps[i],id,ok_cb,false)
	sleep(0.01)
  end
  for i=1, #gps do
    fwd_msg(gps[i],id,ok_cb,false)
	sleep(0.01)
  end
  for i=1, #users do
    fwd_msg(users[i],id,ok_cb,false)
	sleep(0.01)
  end
   redis:setex("timefwdall:"..msg.to.id,1800,true)
  return "به همه سوپرگروه ها گروه ها و پیوی ها ارسال شد"
  end
  if matches[1]=="fwdpv" then
  if redis:get("timefwdpv:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
  local id = msg.reply_id
  local users = redis:smembers("selfbot:users")
  for i=1, #users do
    fwd_msg(users[i],id,ok_cb,false)
	sleep(0.01)
  end
   redis:setex("timefwdpv:"..msg.to.id,1800,true)
  return "به تمام پیوی ها ارسال شد"
  end
  if matches[1]=="fwdgp" then
  if redis:get("timefwdgp:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
  local id = msg.reply_id
  local gps = redis:smembers("selfbot:groups")
  for i=1, #gps do
    fwd_msg(gps[i],id,ok_cb,false)
	sleep(0.01)
  end
    redis:setex("timefwdgp:"..msg.to.id,1800,true)
  return "به همه گروه ها ارسال شد"
  end
  if matches[1]=="fwdsgp" then
  if redis:get("timefwdsgp:"..msg.to.id) then
    return "<i>این کار فقط هر نیم ساعت یک بار ممکن میباشد لطفا بعد از نیم ساعت دوباره امتحان کنید</i>"
    end
  local id = msg.reply_id
    local sgps = redis:smembers("selfbot:supergroups")
	for i=1, #sgps do
    fwd_msg(sgps[i],id,ok_cb,false)
	sleep(0.01)
  end
    redis:setex("timefwdsgp:"..msg.to.id,1800,true)
   return "به همه سوپر گروه ها ارسال شد"
  end
  if matches[1] == "lua" and is_sudo(msg) then
    return lua(matches[2])
  end
  if matches[1] == "echo" and is_sudo(msg) then
    return matches[2]
  end
  if msg.text:match("https://telegram.me/joinchat/%S+") and redis:get("bot:autojoin") == "on" then
    if string.len(matches[1]) == 51 and not redis:sismember("selfbot:links",matches[1]) then
      redis:sadd("selfbot:links",matches[1])
      import_chat_link(parsed_url(matches[1]),ok_cb,false)
    end
  end
  if  msg.text:match("https://t.me/joinchat/%S+") and redis:get("bot:autojoin") == "on" then
    if string.len(matches[1]) == 44 and not redis:sismember("selfbot:links",matches[1]) then
      redis:sadd("selfbot:links",matches[1])
      import_chat_link(parsed_url(matches[1]),ok_cb,false)
    end
  end
  if  msg.text:match("https://telegram.dog/joinchat/%S+") and  redis:get("bot:autojoin") == "on" then
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
  return "کاربر "..matches[2].."به لیست سودو ها اضافه شد"
  else
  return "خطا"
  end
  end
  
  if matches[1] == 'remsudo' then
if msg.from.id and msg.from.id == tonumber(sudomsg) then
 table.remove(_config.sudo_users, getindex( _config.sudo_users, tonumber(msg.to.id)))
    print(matches[2]..' remove to sudo users')
    save_config()
  reload_plugins(true)
  return "کاربر"..matches[2].."از لیست سودو ها خارج شد"
  else
  return "خطا"
  end
  end
if matches[1]== "serverinfo" and is_sudo(msg) then
local text = io.popen("sh ./data/cmd.sh"):read('*all')
  return text
end
  if matches[1]== "addtoall" and is_sudo(msg) then
  if redis:get("timeaddtoall:"..msg.to.id) then
    return "<i>این کار فقط هر روز یکبار ممکن میباشد بعد از یک روز دوباره امتحان کنید</i>"
    end
	redis:setex("timeaddtoall:"..msg.to.id,86400,true)
  local sgps = redis:smembers("selfbot:supergroups")
    for i=1, #sgps do
     channel_invite(sgps[i],matches[2],ok_cb,false)
    end
  return"کاربر "..matches[2].." به همه گروه های ربات اضافه شد\n SuperGroup Stats 》" ..#sgps.. "》"
  end
  if matches[1]=="reset stats" then
   if redis:get("timereset:"..msg.to.id) then
    return "<i>این کار فقط هر روز یکبار ممکن میباشد بعد از یک روز دوباره امتحان کنید</i>"
   end
	redis:setex("timereset:"..msg.to.id,86400,true)
  reset_stats()
  return"آمار ربات 0 شد"
  end
  if matches[1]== "leave" and is_sudo(msg) then
  local receiver = get_receiver(msg)
    leave_channel(receiver, ok_cb, false)
  end
  if matches[1]=="leave" and is_sudo(msg) then
  leave_channel(matches[2], ok_cb, false)
  send_large_msg(msg.to.id,"》Robot Left "..matches[2],ok_cb,false)
  end
  if matches[1]=="myinfo" and is_sudo(msg) then
  local text = "<i>》YourName➣</i> <code>"..msg.from.first_name.."</code>\n<i>》YourId➣</i> <code>"..msg.from.id.."</code>\n<i>》YourUsername➣</i> @"..msg.from.username.."\n<b>PowerBy</b>》@LuaError"
  return text
  end
  if matches[1]=="leaveall" and is_sudo(msg) then
   for i=1, #sgps do
  leave_channel(sgps[i], ok_cb, false)
  return 'ربات از همه سوپرگروها لفت داد'
  end
  send_large_msg(msg.to.id,"ربات لفت داد "..matches[2],ok_cb,false)	
  end
  if matches[1]=="settings"then
    local pm = redis:get('bot:pm') or "ادی"
	local addedmsg = redis:get('bot:addedmsg') or "off"
  local autojoin = redis:get('bot:autojoin')  or "off"
  local addcontact = redis:get('bot:addcontacts') or "off"
  local text = "<b>─═हई Tebchi Settings ईह═─ </b>\n<i>》Autojoin➣</i> <code>"..autojoin.."</code>\n<i>》Add Contacts➣</i> <code>"..addcontact.."</code>\n<i>》Bot Adding Pm➣</i> <code>"..addedmsg.."</code>\n<i>》BotPm ➣</i> <code>"..pm.."</code>\n<i>PowerBy </i>》 @LuaError"  
  return text
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
  "^[#!/](settings)$",
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
  "^[!/#](autojoin) (.*)$",
  "^[!/#](addedmsg) (.*)$",
  "^[!/#](addcontacts) (.*)$",  
  "(https://telegram.me/joinchat/%S+)",
  "(https://t.me/joinchat/%S+)",
  "(https://telegram.dog/joinchat/%S+)",
  "^[$](.*)$",
  "%[(photo)%]"
},
run = run,
pre_process = pre_process
}
--@LuaError
--@Tele_Sudo
