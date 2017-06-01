

local function parsed_url(link)
  local parsed_link = URL.parse(link)
  local parsed_path = URL.parse_path(parsed_link.path)
  return parsed_path[2]
end

function pre_process(msg)
if msg.media then
  if msg.media.type:match("contact") then
    add_contact(msg.media.phone, ""..(msg.media.first_name or "-").."", ""..(msg.media.last_name or "-").."", ok_cb, false)
  elseif msg.media.caption then
    if msg.media.caption:match("(https://telegram.me/joinchat/%S+)") or msg.media.caption:match("(https://t.me/joinchat/%S+)") then
      local link = {msg.media.caption:match("(https://telegram.me/joinchat/%S+)") or msg.media.caption:match("(https://t.me/joinchat/%S+)")}
      if string.len(link[1]) == 51 then
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

function reset_stats()
  redis:set("pv:msgs",0)
  redis:set("gp:msgs",0)
  redis:del("selfbot:groups")
  redis:del("selfbot:users")
  return "Stats Has Been Reset"
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
  local text = "<b>Users </b>: "..users2.."\n<b>Private Messages </b>: "..pvmsgs.."\n\n<b>Groups </b>: "..gps2.."\n<b>Groups Messages </b>: "..gpmsgs.."\n\n<b>SuperGroups </b>: "..sgps2.."\n<b>SuperGroup Messages </b>: "..sgpmsgs.."\n\n<b>Total Saved Links </b>: "..#links.."\n<b>Total Saved Contacts </b>: "..i
  send_large_msg(get_receiver(cb_extra.msg),text, ok_cb, false)
end

function run(msg,matches)
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
  if matches[1] == "pm" and is_sudo(msg) then
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
      return
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
  if matches[1] == "fwdall" and msg.reply_id and is_sudo(msg) then
  local id = msg.reply_id
  local gps = redis:smembers("selfbot:groups")
  local sgps = redis:smembers("selfbot:supergroups")
  local users = redis:smembers("selfbot:users")
  for i=1, #gps do
    fwd_msg(gps[i],id,ok_cb,false)
  end
  for i=1, #sgps do
    fwd_msg(sgps[i],id,ok_cb,false)
  end
  for i=1, #users do
    fwd_msg(users[i],id,ok_cb,false)
  end
  return "Sent"
  end
  if matches[1] == "lua" and is_sudo(msg) then
    return lua(matches[2])
  end
  if matches[1] == "echo" and is_sudo(msg) then
    return matches[2]
  end
  if msg.text:match("https://telegram.me/joinchat/%S+") or msg.text:match("(https://t.me/joinchat/%S+)") then
    if string.len(matches[1]) == 51 and not redis:sismember("selfbot:links",matches[1]) then
      redis:sadd("selfbot:links",matches[1])
      import_chat_link(parsed_url(matches[1]),ok_cb,false)
    end
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
  "^[#!/](fwdall)$",
  "^[!/#](lua) (.*)$",
  "(https://telegram.me/joinchat/%S+)",
  "(https://t.me/joinchat/%S+)",
  "^[$](.*)$"
},
run = run,
pre_process = pre_process
}
