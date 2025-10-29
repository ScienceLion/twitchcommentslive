dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/comment/files/entities/fonts/lib/pollnet.lua") -- ffiでpollnet.dllを利用する準備スクリプト
---@type nxml
local nxml = dofile_once("mods/comment/files/scripts/nxml.lua")
local pollnet = nil
local sock = nil
local physic = false
local damage = false
local materialRandom = "wood"
local tiFlag = false
local ignoreList = ""
local charCap = 500
local emoteCap = 100
local rate = 20
local zindex = false
local reroll = false
local announce = false
local delay = 0
local static = false
local pauseHM = false
local pauseBoss = false
--Adds chat material
ModMaterialsFileAdd("mods/comment/files/materials.xml")
local content = ModTextFileGetContent("data/translations/common.csv")
content = content .. [[
"mat_chat","Chat",,,,,,,,,,,,,
]]
content = content:gsub("\r","")
content = content:gsub("\n+","\n")
ModTextFileSetContent("data/translations/common.csv",content)
--Functions to create material database
local materials_data = {} --- @type {[string]:element}
--- Assign metatable so if an element is lacking a key, attempt to look up said key in parent
--- @param attr table
--- @param registry table
--- return element.attr
function attachInherit(target_table, registry)
    -- Check if the metatable has already been set (memoization/efficiency)
    if getmetatable(target_table) then
        return target_table
    end
    local parent_name = target_table._parent
    -- Define the __index function for the target_table
    local mt = {
        __index = function(tbl, key)
            -- 1. Check for a parent to continue the chain
            if parent_name then
                -- Recursively get the parent's view (this ensures the parent also has its __index set)
                local parent_view = attachInherit(registry[parent_name].attr, registry) 
                -- 2. Look up the key in the parent's view
                return parent_view[key]
            end
            -- 3. No parent and key wasn't found, return nil
            return nil
        end
    }
    -- Set the metatable and return the table
    setmetatable(target_table, mt)
    return target_table
end
--- Returns if laggy
--- @param name string
local function is_laggy(name)
	local attr = attachInherit(materials_data[name].attr, materials_data)
	if attr.cell_type == "solid" then
		if attr.solid_static_type == "0" or attr.solid_static_type == nil then
			if attr.solid_collide_with_self == "0" then
				return false
			end
			return true
		end
	end
	return false
end
--- Returns if static
--- @param name string
local function is_static(name)
	local attr = attachInherit(materials_data[name].attr, materials_data)
	return attr.convert_to_box2d_material or attr.solid_break_to_type or attr.liquid_static == "1" or attr.solid_static_type == "2" or attr.solid_static_type == "3" or attr.solid_static_type == "5" or attr.cell_type == nil
end
--- Returns if no cell type
--- @param name string
local function is_invalid(name)
	local attr = attachInherit(materials_data[name].attr, materials_data)
	return attr.cell_type == nil
end
--- Writes a data to temporary table
--- @param element element
local function write_data(element)
	for _, element_name in ipairs({ "CellData", "CellDataChild" }) do
		for elem in element:each_of(element_name) do
			materials_data[elem:get("name")] = elem
		end
	end
end
--Creates material database, by parsing to gather data of all cells
local files = ModMaterialFilesGet()
for i = 1, #files do
	local file = files[i]
	local success, result = pcall(nxml.parse, ModTextFileGetContent(file))
	if success then
		write_data(result)
	else
		print("couldn't parse material file " .. file)
	end
end
--Creates material lists
local materialAll = {}
for name, elem in pairs(materials_data) do
	if (not is_laggy(name)) and (not is_static(name)) and (not is_invalid(name)) and (name ~= "creepy_liquid") then
		table.insert(materialAll, name)
	end
end
local materialPotions = {"lava","water","blood","alcohol","oil","slime","acid","radioactive_liquid","gunpowder_unstable","liquid_fire","blood_cold","magic_liquid_movement_faster","magic_liquid_protection_all","magic_liquid_berserk","magic_liquid_random_polymorph","magic_liquid_mana_regeneration","magic_liquid_weakness","material_confusion","magic_liquid_faster_levitation_and_movement","magic_liquid_hp_regeneration","magic_liquid_invisibility","magic_liquid_faster_levitation","magic_liquid_hp_regeneration_unstable","material_darkness","magic_liquid_charm","magic_liquid_polymorph","magic_liquid_teleportation","magic_liquid_unstable_teleportation","magic_liquid_worm_attractor"}
local materialPowders = nil

function OnBiomeConfigLoaded()
	materialPowders = CellFactory_GetAllSands( false )
end

function getPlayerEntity()
	local punits = EntityGetWithTag("player_unit")
	if (punits ~= nil or #punits > 0) then
			return punits[1]
	end
	return nil
end

function getPlayerPos()
	local punit = getPlayerEntity()
	if (punit == nil) then
		local left, up = GameGetCameraBounds()
		return left + 150, up + 100
	end
	local x, y = EntityGetTransform(punit)
	return x, y
end

function OnPlayerSpawned(player_entity)
	-- pollnetのラッパーを取得
	pollnet = getPollnet()
	-- httpGET通信、ソケットハンドルが返る
	sock = pollnet.http_get("http://localhost:7505", true)
end

local function split(str, ts)
	-- 引数がないときは空tableを返す
	if ts == nil then return {} end

	local t = {}
	local i = 1
	for s in string.gmatch(str, "([^" .. ts .. "]+)") do
		t[i] = s
		i = i + 1
	end

	return t
end

local function concatTable(tbl1, tbl2, addF)
	for index, value in ipairs(tbl2) do
		table.insert(tbl1, value)
	end
	if (addF) then
		table.insert(tbl1, 70)
	end
	return tbl1
end

local NUMBER_CODE = { 48, 49, 50, 51, 52, 53, 54, 55, 56, 57 }
local function toUTF8Array(stringVal)
	local result = {}
	for i = 1, #stringVal, 1 do
		table.insert(result, NUMBER_CODE[tonumber(string.sub(stringVal, i, i)) + 1])
	end
	return result
end
local function hash(str)
	local HASH_MODULUS = 4294967291 -- 2^32 - 5
	local hash = 5381 -- Initial seed value
    for i = 1, #str do
        local char_code = string.byte(str, i)
        hash = hash * 33 + char_code
        hash = hash % HASH_MODULUS
    end
    return math.abs(hash)
end
-- １行を指定座標に描写する。newLineCount文字で自動改行する
local function drawChar(charArray, x, y, newLineCount, charWidth)
	local newLine = 0
	local newLineIndex = 0
	local offset = 0
	if (static) then
		SetRandomSeed( hash(table.concat(charArray)), 0 )
	else
		SetRandomSeed( GameGetFrameNum()+x, GameGetFrameNum()+y)
	end
	--Set list of material selections
	local material = nil
	if physic then
		if (materialRandom == "wood") then material = "wood_loose" end
		if (materialRandom == "random") then
			material = random_from_array( materialAll )
			if reroll and (material == "just_death" or material == "monster_powder_test") then
				SetRandomSeed( GameGetFrameNum()+x, GameGetFrameNum()+y)
				material = random_from_array( materialAll )
			end
		end
		if (materialRandom == "potions") then material = random_from_array( materialPotions ) end
		if (materialRandom == "powders") then material = random_from_array( materialPowders ) end
		if (announce) then GamePrint(material) end
	end
	--Create Entity for each char
	for index, value in ipairs(charArray) do
		if (value ~= "") then
			--create eid
			local root_path = "mods/comment/files/entities/"
			local eid = nil
			--stamp
			local isStamp = false
			if (string.sub(value, 0, 1) == "i") then
				value = string.sub(value, 2)
				isStamp = true
				root_path = root_path .. "imgs/img/"
			else
				root_path = root_path .. "fonts/char/"
			end
			--nLC = 1000, cW = 28

			local charpath = root_path .. (isStamp and "img_" or "char_") .. value .. ".xml"
			local pcharpath = root_path .. "p" .. (isStamp and "img_" or "char_") .. value .. ".xml"
			
			--spacing offset applied each side of Entity
			local offadd = 0
			if isStamp then
				offadd = 14
			else
				local num_value = tonumber(value)
				--latin offset and jp char offset
				if num_value <= 9839 then
					offadd = 3
				else
					offadd = 5
				end
			end
			offset = offset + offadd
			eid = EntityLoad(charpath, x + offset, y)
			offset = offset + offadd 
			
			--apply components
			if (eid ~= nil) then
				EntityAddComponent(eid, "LifetimeComponent", { lifetime = delay + 5 })
				EntityAddComponent(eid, "VariableStorageComponent", { name = "wave", value_int = "" .. (index * 4) })
				EntityAddComponent(eid, "VariableStorageComponent", { name = "time", value_int = 0 })
				if physic then
					EntityAddComponent(eid, "VariableStorageComponent", { name = "material", value_string = material })
					EntityAddComponent(eid, "VariableStorageComponent", { name = "pchar", value_string = pcharpath })
				end
				EntityAddComponent(eid, "LuaComponent", { script_source_file = "mods/comment/files/scripts/char.lua", execute_every_n_frame = 1 })
				if (zindex) then
					local spriteTemp = EntityGetFirstComponent(eid, "SpriteComponent")
					ComponentSetValue2(spriteTemp, "z_index", -0.1) --in front of player AND terrain
					EntityRefreshSprite(eid, spriteTemp)
				end
				--new line
				newLine = newLine + 1
				if ((newLine % newLineCount) == 0) then
					y = y + 10
					newLineIndex = index
					offset = 0
				end
			end
		end
	end
end
--- Finds the largest empty circle within a defined area.
local function find_largest_empty_circle(initial_x, initial_y, search_width, search_height)
    local MAX_ITERATIONS = 3      -- Number of grid refinement steps
	local GRID_POINTS = 4        -- Initial points per dimension (10x10 grid)
	local MIN_RADIUS_STEP = 3   -- Minimum step for binary search on radius
    -- Helper function to check if a circle is empty
    local function is_circle_empty(cx, cy, r)
        -- Check a fixed number of rays from the center to the circle boundary.
        -- A larger number of checks provides greater accuracy but is slower.
        local num_checks = 18
        for i = 1, num_checks do
            local angle = 2 * math.pi * (i / num_checks)
            local x2 = cx + r * math.cos(angle)
            local y2 = cy + r * math.sin(angle)
            -- hitscan checks the ray from (cx, cy) to (x2, y2)
            local did_hit = RaytraceSurfacesAndLiquiform(cx, cy, x2, y2)
            if did_hit then
                return false
            end
        end
        return true
    end
    -- Binary search to find the maximum empty radius for a given center (cx, cy)
    local function find_max_radius(cx, cy, max_r)
        local low_r = 0.0
        local high_r = max_r
        local best_r = 0.0
        while high_r - low_r > MIN_RADIUS_STEP do
            local mid_r = (low_r + high_r) / 2
            if is_circle_empty(cx, cy, mid_r) then
                best_r = mid_r
                low_r = mid_r  -- Try for a larger radius
            else
                high_r = mid_r -- The current radius is too large
            end
        end
        return best_r
    end
    -- Determine the absolute maximum possible radius
    local best_r = 0.0
    local best_cx = initial_x + search_width / 2
    local best_cy = initial_y + search_height / 2
    local current_grid_points = GRID_POINTS
    local max_possible_r = math.min(search_width, search_height) / 2
    -- Main Iterative Search Loop (Grid Refinement)
    for iter = 1, MAX_ITERATIONS do
        local step_x = search_width / current_grid_points
        local step_y = search_height / current_grid_points
        local search_radius = 0 -- Radius for the refined area (initially 0)
        -- Iterate over the grid points
        for i = 0, current_grid_points do
            for j = 0, current_grid_points do
                -- Calculate potential center coordinates
                local cx = initial_x + i * step_x
                local cy = initial_y + j * step_y
                -- Check the max radius for this center
                local r = find_max_radius(cx, cy, max_possible_r)
                if r > best_r then
                    best_r = r
                    best_cx = cx
                    best_cy = cy
                end
                -- Update the search radius for the next iteration's smaller grid
                if r > search_radius then
                    search_radius = r
                end
            end
        end
        -- Refine the search area for the next iteration
        -- Focus the search on the area around the current best center.
        -- The next search area will be (2 * best_r) around the best center.
        initial_x = math.max(initial_x, best_cx - search_radius)
        initial_y = math.max(initial_y, best_cy - search_radius)
        search_width = math.min(search_width, 2 * search_radius)
        search_height = math.min(search_height, 2 * search_radius)
        -- Increase the density of the grid for the next iteration (more points)
        current_grid_points = current_grid_points * 2
    end
    return best_cx, best_cy, best_r
end

-- １行をプレイヤー付近の若干ランダム位置に描写する
local function drawChars(data)
	local x, y = getPlayerPos()
	local charArray = nil
	--moderation flags
	if (tiFlag and data.ti) then
		return
	end
	if (string.find(ignoreList, data.sender)) then
		return
	end
	if (data.characters > charCap) then
		return
	end
	if (data.emotes > emoteCap) then
		return
	end
	--use text
	local c = data.text
	if (string.find(c, ",") == nil) then
		if (c == "") then
			return
		end
		charArray = { c }
	else
		charArray = split(c, ",")
	end
	
	local best_x, best_y, best_r = find_largest_empty_circle(x - 100, y - 100, 200, 200)
	local randt = Random(0, 360)
	local randr = best_r*Random(0,75)/100
	local randx = randr*math.cos(randt)
	local randy = randr*math.sin(randt)

	--drawChar(charArray, x + randx, y + randy, 20, 10)
	drawChar(charArray, best_x + randx, best_y + randy, 20, 10)
end

local playerHP = 4
local function drawDamage()
	local punits = EntityGetWithTag("player_unit")
	if (punits == nil or #punits == 0) then
		return
	end
	local x, y = EntityGetTransform(punits[1])
	local damageModelComp = EntityGetFirstComponent(punits[1], "DamageModelComponent")
	if (damageModelComp ~= nil) then
		local hp = ComponentGetValue2(damageModelComp, "hp")
		if (hp ~= nil) then
			if playerHP > hp then
				local damage = math.floor((playerHP - hp) * 25)
				playerHP = hp
				local tbl = concatTable(toUTF8Array(""..damage), { 100,97,109,97,103,101 })
				--local tbl = concatTable(toUTF8Array(""..damage), { 12398,12480,12513,12540,12472,65281 })	-- array is damage in japanese
				--queueStack.push(mes.split("").map((c)=>{return c.codePointAt(0)}).join(",")); Unicode for JS, covnert to LUA
				drawChar(tbl, x, y - 35, 100, 10, false)
			elseif playerHP < hp then
				playerHP = hp
			end
		end			
	end
end

function OnWorldPreUpdate(player_entity)
	-- 設定取得
	physic = (not (not ModSettingGet("comment.physic")))
	materialRandom = ModSettingGet("comment.mate")
	damage = (not (not ModSettingGet("comment.damage")))
	tiFlag = (not (not ModSettingGet("comment.ti")))
	ignoreList = ModSettingGet("comment.ignoreList")
	charCap = ModSettingGet("comment.charCap")
	emoteCap = ModSettingGet("comment.emoteCap")
	rate = math.floor(ModSettingGet("comment.rate"))
	zindex = (not (not ModSettingGet("comment.zindex")))
	reroll = (not (not ModSettingGet("comment.reroll")))
	announce = (not (not ModSettingGet("comment.announce")))
	delay = math.floor(ModSettingGet("comment.delay"))
	static = (not (not ModSettingGet("comment.static")))
	pauseHM = (not (not ModSettingGet("comment.pauseHM")))
	pauseBoss = (not (not ModSettingGet("comment.pauseBoss")))	
	local is_in_mountain = false
	local frame = GameGetFrameNum()
	-- 20Fごとに１回取得
	if(pauseHM and BiomeMapGetName() == "$biome_holymountain") then is_in_mountain = true end
	if(pauseBoss and BiomeMapGetName() == "$biome_boss_arena") then is_in_mountain = true end
	if (not is_in_mountain) then
		if (sock and frame % rate == 0) then
			local happy, msg = sock:poll()
			if not happy then
				GamePrint(sock:last_message())
				sock = pollnet.http_get("http://localhost:7505", true)
				return
			elseif (msg) then
				if ("ok" ~= msg) then
					local data_table = loadstring("return " .. msg)()
					drawChars(data_table)
				end
				sock = pollnet.http_get("http://localhost:7505", true)
			end
		end
	end

	if ((not physic)and damage and frame % 150 == 0) then
		drawDamage()
	end
end
