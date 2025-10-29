--dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/twitchcommentslive/files/scripts/utilities.lua")
local nxml = dofile_once("mods/twitchcommentslive/files/scripts/nxml.lua")
local pngencoder = dofile_once("mods/twitchcommentslive/files/scripts/pngencoder.lua")
local gif = dofile_once("mods/twitchcommentslive/files/scripts/gif.lua")
local ircparser = dofile_once("mods/twitchcommentslive/lib/ircparser.lua")

ModLuaFileAppend( "data/scripts/streaming_integration/event_utilities.lua", "mods/twitchcommentslive/files/scripts/append/append_event_utilities.lua")

function OnWorldPreUpdate(player_entity)
	local frame = GameGetFrameNum()
	local rate = 180
	--dequeue from global
	if (frame % rate == 0) then
		local messages = GlobalsGetValue("messages")
		if messages ~= "" then
			local first, last, raw = string.find(messages, "(string%b())") --ISSUE: if message has ) before any (, message will stop there 
			if last == #messages then
				messages = ""
			else
				messages = string.sub(messages, last + 2)
			end
			GlobalsSetValue("messages", messages)
			local lines = ircparser.split(raw, '\r\n')
			for _, line in pairs(lines) do
				local data = ircparser.websocketMessage(line)
				--drawChars
				print(dump(data))
			end
		end
	end
end
--QUEUE, DOWNLOAD FUNCTIONS, GIF FUNCTIONS, XML FUNCTIONS, TIMING DEQUEUE

--[[
	DOWNLOAD, GIF, XML in append if I can, ahead of time, async
]]

	
--[[
ADDITIONAL MESSAGE HANDLING EXAMPLES

local lines = ircparser.split(raw, '\r\n')
for _, line in pairs(lines) do
	local data = ircparser.websocketMessage(line)

	print(dump(data))
	--print(line)
	if(string.match(line, "PRIVMSG") and string.sub(line, 1, 11) == "@badge-info")then
		if(line == nil or line == "" or line == "	" or line == " ")then
			return
		end
		if(data ~= nil)then
			local broadcaster = false
			local mod = false
			local subscriber = false
			local turbo = false

			--print(table.dump(data))

			if(string.match(data["tags"]["badges"], "broadcaster"))then
				broadcaster = true
			end

			if(tonumber(data["tags"]["mod"]) == 1)then
				mod = true
			end
			if(tonumber(data["tags"]["subscriber"]) == 1)then
				subscriber = true
			end
			if(tonumber(data["tags"]["turbo"]) == 1)then
				turbo = true
			end

			local userdata = {
				username = data["tags"]["display-name"],
				user_id = data["tags"]["user-id"],
				message_id = data["tags"]["id"],
				broadcaster = broadcaster,
				mod = mod,
				subscriber = subscriber,
				turbo = turbo,
				bits = tonumber(data["tags"]["bits"] or 0) or 0,
				color = data["tags"]["color"],
				custom_reward = data["tags"]["custom-reward-id"],
				message = message
			}

			--local message = data["params"][2]
			
			OnMessage(userdata, message)
			if(userdata.bits > 0)then
				OnBits(userdata, message)
			end
		end
	elseif(string.match(line, "USERNOTICE") and string.sub(line, 1, 11) == "@badge-info")then
		if(line == nil or line == "" or line == "	" or line == " ")then
			return
		end
		--print(raw)
		
		if(data ~= nil)then
			if(data["tags"]["msg-id"] == "resub" or data["tags"]["msg-id"] == "sub")then
				local broadcaster = false
				local mod = false
				local subscriber = false

				if(string.match(data["tags"]["badges"], "broadcaster"))then
					broadcaster = true
				end

				if(tonumber(data["tags"]["mod"]) == 1)then
					mod = true
				end
				if(tonumber(data["tags"]["subscriber"]) == 1)then
					subscriber = true
				end

				local message = data["params"][2]

				if(data["tags"]["msg-param-cumulative-months"] ~= nil)then
					data["tags"]["msg-param-cumulative-months"]	= 1
				end

				if(data["tags"]["msg-param-streak-months"] ~= nil)then
					data["tags"]["msg-param-streak-months"]	= 1
				end

				local sub_data = {
					username = data["tags"]["display-name"],
					user_id = data["tags"]["user-id"],
					broadcaster = broadcaster,
					mod = mod,
					subscriber = subscriber,
					msg_id = data["tags"]["msg-id"],
					color = data["tags"]["color"],
					total_months = tonumber(data["tags"]["msg-param-cumulative-months"]),
					streak = tonumber(data["tags"]["msg-param-streak-months"]),
					message = message
				}

				if(message == nil)then
					message = ""
				end


				OnSub(sub_data, message)
			end
		end
	end
end
]]