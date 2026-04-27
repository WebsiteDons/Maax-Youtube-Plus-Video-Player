--[[
* name			: MaaX Youtube Browser Source
* type			: script
* version		: 1.2.0
* date			: 04/05/26
* author		: MaaX.Site
* url			: https://maax.site
* license		: GPL
* description	: This tool will add Youtube player to an existing browser source and also manage properties.
]]

obs = obslua

maax_current_settings = nil
maax_static_counter = 0
maax_version_ytvid = "1.2.0 | April 26 2026"

_asset = script_path().."maax_assets"
-- load texts file
dofile(_asset.."/text_strings.lua")

function script_description()
	return _txt.ytvid_desc
end

-- load helper functions
dofile(_asset.."/maax-youtube-helpers.lua")

------------------------------------------------------------
-- Defaults
------------------------------------------------------------
function script_defaults(settings)
	obs.obs_data_set_default_bool(settings, "show_all_scenes", false)
	obs.obs_data_set_default_string(settings, "selected_scene", "")
	obs.obs_data_set_default_string(settings, "target_source", "")

	obs.obs_data_set_default_string(settings, "maax_screen_size", "1920x1080")
	obs.obs_data_set_default_bool(settings, "reroute_audio", true)
	obs.obs_data_set_default_bool(settings, "shutdown", true)
	obs.obs_data_set_default_bool(settings, "refresh", true)
	obs.obs_data_set_default_bool(settings, "autoplay", true)
	obs.obs_data_set_default_string(settings, "youtube_ids", "")
	obs.obs_data_set_default_bool(settings, "enable_custom_url", false)
end

function script_load(settings)
	maax_current_settings = settings
	obs.obs_data_set_string(settings, "selected_scene", "")
	obs.obs_data_set_string(settings, "target_source", "")
	obs.obs_data_set_string(settings, "youtube_ids", "")
	obs.obs_data_set_string(settings, "maax_screen_size", "1920x1080")
	obs.obs_data_set_bool(settings, "show_all_scenes", false)
	obs.obs_data_set_bool(settings, "enable_custom_url", false)
end


------------------------------------------------------------
-- Properties UI
------------------------------------------------------------
function script_properties()
	local props = obs.obs_properties_create()
	
	-- SCENES SELECT
	textDesc(props, _txt.browser_list)
	
	local get_all_scenes = checkbox(props, "show_all_scenes", "Show all scenes")
    local scene_prop = selectField(props, "selected_scene", "Scene")
	
    obs.obs_property_set_modified_callback(get_all_scenes, maax.refresh_scene_list)
	maax.refresh_scene_list(props, nil, obs.obs_data_create())

	-- BROWSER SELECT
	local sl = selectField(props, "target_source", "Sources")

    -- callback to load browser sources of the selected scene
	-- and callback to load browser data
    obs.obs_property_set_modified_callback(scene_prop, update_source_list)
	obs.obs_property_set_modified_callback(sl, on_source_changed)
	-- / EOF source selector

	-- CONFIGS
	textDesc(props, "<h4>Source Configuration</h4>")
	
	-- SCREEN WIDTH AND HEIGHT
	local ss = selectField(props, "maax_screen_size", "Screen Size", 1)
	local sizes = {"1920x1080","1440x810","1280x720","960x540","640x360"}
	for _, ssize in ipairs(sizes) do
		obs.obs_property_list_add_string(ss, ssize,ssize)
	end

	checkbox(props, "reroute_audio", "Control audio via OBS")
	checkbox(props, "shutdown", "Shutdown When Hidden")
	checkbox(props, "refresh", "Refresh When Active")

	-- VIDEO ID ENTRY
	textDesc(props, _txt.ytid_field_desc)
	textArea(props,"youtube_ids")
	checkbox(props, "autoplay", "Autoplay")
	checkbox(props, "loop", "Loop Videos")
	checkbox(props, "shuffle", "Shuffle Videos")
	
	-- CUSTOM EXTERNAL URL FOR PLAYER EMBED
	local show_custom_url_field = checkbox(props, "enable_custom_url", "I have a custom Youtube player URL")
	obs.obs_property_set_modified_callback(show_custom_url_field, maax.on_change)
	obs.obs_property_set_visible(textDesc(props, _txt.ytv_iframe_url,"iframe_new_url_desc"), false)
	obs.obs_property_set_visible(textField(props, "iframe_new_url"), false)
	
	textDesc(props, "<b>Add new source or update selected source</b>")
	-- add new browser source callback
	button(props,"source_create_btn", maax.create_new_source, "🞧 Create New Source")
	
	-- Save update
	obs.obs_properties_add_button(props, "save_button", "🖬 Update Selected Source", function(props, prop)
		update_browser(maax_current_settings)
		obs.obs_data_set_bool(maax_current_settings, "show_all_scenes", false)
		return true
	end
	)

	return props
end


------------------------------------------------------------
-- When settings change
------------------------------------------------------------
function script_update(settings)
	maax_current_settings = settings
	local current = obs.obs_data_get_string(settings, "target_source")
	if current ~= last_source then
        --print("[PlaylistScript] Source changed to:", current)

        last_source = current

        if current ~= "" then
            local source = obs.obs_get_source_by_name(current)

            if source then
                local s = obs.obs_source_get_settings(source)
                local url = obs.obs_data_get_string(s, "url")

                obs.obs_data_release(s)
                obs.obs_source_release(source)
            end
        end
    end
end


