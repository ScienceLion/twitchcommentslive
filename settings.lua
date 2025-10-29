dofile("data/scripts/lib/mod_settings.lua")

local mod_id = "twitchcommentslive" -- This should match the name of your mod's folder.
mod_settings_version = 1     -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value.
mod_settings =
{
	{
		category_id = "main_group",
		ui_name = "Main Chat Settings",
		ui_description = "",
		settings = {
			{
				id = "server setting",
				ui_name = "Use server settings.txt for setting channel",
				not_setting = true
			},
			{
				id = "delay",
				ui_name = "Chat Lifetime",
				ui_description = "Lifetime of chat messages in-game (frames)",
				value_default = 180,
				value_min = 0,
				value_max = 600,
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "rate",
				ui_name = "Post Rate",
				ui_description = "Number of frames between chat messages appearing",
				value_default = 60,
				value_min = 1,
				value_max = 300,
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "zindex",
				ui_name = "Chat In Front",
				ui_description = "If On, text will be in front of terrain and player",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "wiggle",
				ui_name = "Wiggle",
				ui_description = "Adjust how much text wiggles.",
				value_default = 1,
				value_min = 0,
				value_max = 2,
				value_display_multiplier = 10,
				value_display_formatting = " $00%",
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "physic",
				ui_name = "Physical Conversion",
				ui_description = "If On, chat messages convert to physical form at end of lifetime",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME
			}
		}
	},
	{
		category_id = "phys_group",
		ui_name = "Physical Chat Settings",
		ui_description = "",
		settings = {
			{
				id = "mate",
				ui_name = "Conversion Material",
				ui_description = "Set of materials which convsersion selects from",
				value_default = "wood",
				values = { {"wood","Wood"}, {"random","Random"}, {"potions","Potions"}, {"powders","Powders"} },
				scope = MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback
			},
			{
				id = "reroll",
				ui_name = "Reroll Catastrophic",
				ui_description = "If On, rerolls, but does not remove, Monstrous Powder and Deathium",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "announce",
				ui_name = "Announce Material",
				ui_description = "Displays notification of randomly selected material",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "static",
				ui_name = "Static Seed",
				ui_description = "If On, same chat messages result in same material",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "damage",
				ui_name = "Damage Display",
				ui_description = "Turn this on if you want to display the damage you have taken",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				value_default = false
			}
		}
	},
	{
		category_id = "moderation_settings",
		ui_name = "Moderation",
		ui_description = "Moderation settings",
		foldable = true,
		_folded = true,
		settings = {
			{
				id = "ignoreList",
				ui_name = "Ignore List",
				ui_description = "Usernames to ignore (separated by comma)",
				value_default = "nightbot,streamelements,streamlabs,sery_bot",
				text_max_length = 250,
				allowed_characters = "abcdefghijklmnopqrstuvwxyz_0123456789,",
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "ti",
				ui_name = "Ignore Twitch Integration Votes",
				ui_description = "Turn this on if you want to Twitch Integration votes to not appear in game",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				value_default = true
			},
			{
				id = "charCap",
				ui_name = "Maximum Characters",
				ui_description = "Do not display if chat message is over this many characters",
				value_default = 500,
				value_min = 0,
				value_max = 500,
				value_display_multiplier = 1,
				value_display_formatting = " $0 characters",
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "emoteCap",
				ui_name = "Maximum Emotes",
				ui_description = "Do not display if chat message is over this many emotes",
				value_default = 100,
				value_min = 0,
				value_max = 100,
				value_display_multiplier = 1,
				value_display_formatting = " $0 emotes",
				scope = MOD_SETTING_SCOPE_RUNTIME
			}
		}
	}
}

-- This function is called to ensure the correct setting values are visible to the game. your mod's settings don't work if you don't have a function like this defined in settings.lua.
function ModSettingsUpdate(init_scope)
	local old_version = mod_settings_get_version(mod_id) -- This can be used to migrate some settings between mod versions.
	mod_settings_update(mod_id, mod_settings, init_scope)
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic for this function.
function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

-- This function is called to display the settings UI for this mod. your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui(gui, in_main_menu)
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
