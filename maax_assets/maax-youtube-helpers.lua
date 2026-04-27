maax={}

-- text description element
-- this is purposed just to reduce visual clutter with long names
function textDesc(props, text, tid)
	maax_static_counter = maax_static_counter + 1
	tid = tid or "text_id" .. maax_static_counter
	
	return obs.obs_properties_add_text(props, tid, text, obs.OBS_TEXT_INFO)
end

function textArea(props, fid, lbl)
	lbl = lbl or ""
	return obs.obs_properties_add_text(props,fid,lbl,obs.OBS_TEXT_MULTILINE)
end

function textField(props, fid, lbl)
	lbl = lbl or ""
	return obs.obs_properties_add_text(props,fid,lbl,obs.OBS_TEXT_DEFAULT)
end

-- bool
function checkbox(props, fid, lbl)
	return obs.obs_properties_add_bool(props, fid, lbl)
end

-- select field
function selectField(props, sfid, slbl, editable, def)
	slbl = slbl or "" 
	def = def or ""
	if editable == 1 then
		return obs.obs_properties_add_list(props, sfid, slbl, obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	else
		if def ~= "" then
		return obs.obs_property_list_add_string(obs.obs_properties_add_list(props, sfid, slbl, obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING),def.defopt,def.val)
		else
		return obs.obs_properties_add_list(props, sfid, slbl, obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		end
	end
end

-- button
function button(props, btnid, action, btnlbl)
	btnlbl = btnlbl or "Send"
	return obs.obs_properties_add_button(props, btnid, btnlbl, function(p,prop)
		return action(p,prop)
	end
	)
end


------------------------------------------------
-- HELPER create browser source
------------------------------------------------
function maax.create_new_source(props, prop)
    if not maax_current_settings then return true end

    -- Directly retrieve the value from your property list field
    local scene_name = obs.obs_data_get_string(maax_current_settings, "selected_scene")

    if scene_name == "" then
        print("[PlaylistScript] No scene selected in the dropdown.")
        return true
    end

    -- Now proceed with your existing creation logic
    local url = build_url(maax_current_settings)
    local name = "YT Playlist " .. os.date("%H%M%S")

    -- 1. Create Browser Source Settings
    local settings = obs.obs_data_create()
	local screen_dimensions = obs.obs_data_get_string(maax_current_settings, "maax_screen_size")
	local w_str, h_str = string.match(screen_dimensions, "(%d+)x(%d+)")
    obs.obs_data_set_string(settings, "url", url)
    obs.obs_data_set_int(settings, "width", tonumber(w_str) or 1920)
    obs.obs_data_set_int(settings, "height", tonumber(h_str) or 1080)
    obs.obs_data_set_bool(settings, "reroute_audio", obs.obs_data_get_bool(maax_current_settings, "reroute_audio"))
    
    -- 2. Create the Source
    local source = obs.obs_source_create("browser_source", name, settings, nil)
    obs.obs_data_release(settings)

    if not source then
        print("[PlaylistScript] Failed to create source object.")
        return true
    end

    -- 3. Get the Scene and Add the Source
    local scene_source = obs.obs_get_source_by_name(scene_name)
    local scene = obs.obs_scene_from_source(scene_source)
    
    if scene then
        obs.obs_scene_add(scene, source)
        print("[PlaylistScript] Success: Created " .. name .. " in scene " .. scene_name)
        
        -- Set as the current target in the script settings
        obs.obs_data_set_string(maax_current_settings, "target_source", name)
    else
        print("[PlaylistScript] Error: Could not find scene object.")
    end

    -- 4. Clean up memory
    obs.obs_source_release(source)
    obs.obs_source_release(scene_source)
	
	-- update the source select list to show new source and set as selected
	local scene_prop = obs.obs_properties_get(props, "target_source")
    update_source_list(props, scene_prop, maax_current_settings)
    obs.obs_data_set_string(maax_current_settings, "target_source", name)

    -- 5. Force UI to refresh so the new source shows in the "Sources" dropdown
    return true 
end

-- GET VIDEO ID FROM YOUTUBE URL
function getvid(line)
	if not line or line == "" then return nil end

	line = line:gsub("%s+", "")

	-- Already a plain ID (YouTube IDs are 11 chars typically)
	if line:match("^[%w%-_]+$") and #line <= 15 then
	return line
	end

	-- youtube.com/watch?v=ID
	local id = line:match("[?&]v=([%w%-_]+)")
	if id then return id end

	-- youtu.be/ID
	id = line:match("youtu%.be/([%w%-_]+)")
	if id then return id end

	-- youtube.com/shorts/ID
	id = line:match("shorts/([%w%-_]+)")
	if id then return id end

	-- youtube.com/embed/ID
	id = line:match("embed/([%w%-_]+)")
	if id then return id end

	return nil
end


------------------------------------------------------------
-- Build URL
------------------------------------------------------------
function build_url(settings)
    local ids_raw = obs.obs_data_get_string(settings, "youtube_ids")
	local pfx = string.sub(ids_raw,1,2)
	local video_list = ""
	local src_check = (
	pfx == "PL" or 
	pfx == "RD" or 
	pfx == "UU" or 
	pfx == "OL" or 
	pfx == "LL" or 
	pfx == "SP" or 
	ids_raw:match("twitch.tv") or 
	ids_raw:match("vimeo.com") or
	ids_raw:match("rumble.com") or 
	ids_raw:match("dailymotion.com") or 
	ids_raw:match("odysee.com")
	)
	
	if src_check then
		video_list = ids_raw
	else
		local ids = {}
		for line in ids_raw:gmatch("[^\r\n]+") do
			local id = getvid(line)
			if id then
				table.insert(ids, id)
			else
				print("Invalid line skipped:", line)
			end
		end

		video_list = table.concat(ids, ",")
	end

    local loop = obs.obs_data_get_bool(settings, "loop") and "1" or "0"
    local autoplay = obs.obs_data_get_bool(settings, "autoplay") and "1" or "0"
	
	local exturl = "https://websitedons.net/stream"
	if obs.obs_data_get_string(settings, "iframe_new_url") ~= "" then
		exturl = obs.obs_data_get_string(settings, "iframe_new_url")
	end
	local shuffl = ""
	if( obs.obs_data_get_bool(settings, "shuffle") ) then
		shuffl = "&shuffle"
	end

    local url = exturl
        .. "?vid=" .. video_list
        .. "&loop=" .. loop
        .. "&autoplay=" .. autoplay
		.. shuffl
    return url
end

------------------------------------------------------------
-- GET SCENES
------------------------------------------------------------
-- a function to check for scenes with browser sources and 
-- list only those scenes in the scene select field
function scene_has_browser_source(scene_name)
    local scene_source = obs.obs_get_source_by_name(scene_name)
    if not scene_source then return false end
    
    local scene = obs.obs_scene_from_source(scene_source)
    if not scene then
        obs.obs_source_release(scene_source)
        return false
    end
    
    local items = obs.obs_scene_enum_items(scene)
    local has_browser = false
    
    if items then
        for _, item in ipairs(items) do
            local source = obs.obs_sceneitem_get_source(item)
            if source then
                if obs.obs_source_get_id(source) == "browser_source" then
                    has_browser = true
                    break
                end
            end
        end

        obs.sceneitem_list_release(items)
    end
    
    obs.obs_source_release(scene_source)
    
    return has_browser
end

-- get all scenes when checked in scrip_properties
function maax.refresh_scene_list(props, property, settings)
    local scene_prop = obs.obs_properties_get(props, "selected_scene")
    local show_all = obs.obs_data_get_bool(settings, "show_all_scenes")
    
    obs.obs_property_list_clear(scene_prop)
    obs.obs_property_list_add_string(scene_prop, "-- Select a scene --", "")

    local scenes = obs.obs_frontend_get_scenes()
    for _, scene_source in ipairs(scenes) do
        local name = obs.obs_source_get_name(scene_source)
        
        if show_all or scene_has_browser_source(name) then
            obs.obs_property_list_add_string(scene_prop, name, name)
        end
    end
    obs.source_list_release(scenes)
    return true
end

-- function to create array of browser sources found in selected scene event
function update_source_list(props, prop, settings)
    local scene_name = obs.obs_data_get_string(settings, "selected_scene")
    local source_list = obs.obs_properties_get(props, "target_source")
    
    obs.obs_property_list_clear(source_list)
    obs.obs_property_list_add_string(source_list, "Select a Source...", "")

    local scene_source = obs.obs_get_source_by_name(scene_name)
    local scene = obs.obs_scene_from_source(scene_source)
	local has_browser = false
    
    if scene then
        local items = obs.obs_scene_enum_items(scene)
        for _, item in ipairs(items) do
            local source = obs.obs_sceneitem_get_source(item)
            local id = obs.obs_source_get_unversioned_id(source)
            
            -- Filter only browser sources
            if id == "browser_source" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(source_list, name, name)
            end
        end
        obs.sceneitem_list_release(items)
    end
    
    obs.obs_source_release(scene_source)
    return true
end


------------------------------------------------------------
-- Get browser source list
------------------------------------------------------------
function get_browser_sources()
    local sources = obs.obs_enum_sources()
    local list = {}

    if sources ~= nil then
        for _, source in ipairs(sources) do
            local id = obs.obs_source_get_unversioned_id(source)
            if id == "browser_source" then
                local name = obs.obs_source_get_name(source)
                table.insert(list, name)
            end
        end
    end

    obs.source_list_release(sources)
    return list
end

-- get browser source values on select
function on_source_changed(props, property, settings)
	local source_name = obs.obs_data_get_string(settings, "target_source")
	if source_name == "" then return true end
	
	local source = obs.obs_get_source_by_name(source_name)
    
	if source ~= nil then
		-- Get settings and current URL
		local source_settings = obs.obs_source_get_settings(source)
		local current_url = obs.obs_data_get_string(source_settings, "url")

		-- Parse URL and update SCRIPT'S settings
		local existing_val = extract_param(current_url, "vid")
		obs.obs_data_set_string(settings, "youtube_ids", existing_val)
		
		if not string.find(current_url, "websitedons", 1, true) then
			obs.obs_data_set_bool(settings,"enable_custom_url", true)
			obs.obs_property_set_visible(obs.obs_properties_get(props, "iframe_new_url"), true)
			obs.obs_data_set_string(settings, "iframe_new_url", get_base_url(current_url))
		else
			obs.obs_data_set_bool(settings,"enable_custom_url", false)
			obs.obs_property_set_visible(obs.obs_properties_get(props, "iframe_new_url"), false)
			obs.obs_data_set_string(settings, "iframe_new_url", "")
		end

		obs.obs_data_release(source_settings)
		obs.obs_source_release(source)
	end
	
	return true
end

------------------------------------------------------------
-- Apply settings to selected browser source
------------------------------------------------------------
function update_browser(settings)
    local target_name = obs.obs_data_get_string(settings, "target_source")
    if target_name == "" then return end

    local source = obs.obs_get_source_by_name(target_name)
    if source == nil then return end

    local s = obs.obs_source_get_settings(source)

    obs.obs_data_set_string(s, "url", build_url(settings))
	
	local screen_dimensions = obs.obs_data_get_string(settings, "maax_screen_size")
	local w_str, h_str = string.match(screen_dimensions, "(%d+)x(%d+)")
    obs.obs_data_set_int(s, "width", tonumber(w_str) or 1920)
    obs.obs_data_set_int(s, "height", tonumber(h_str) or 1080)
	
    obs.obs_data_set_bool(s, "reroute_audio", obs.obs_data_get_bool(settings, "reroute_audio"))
    obs.obs_data_set_bool(s, "shutdown", obs.obs_data_get_bool(settings, "shutdown"))
	obs.obs_data_set_bool(s, "refresh", obs.obs_data_get_bool(settings, "refresh"))
    obs.obs_data_set_bool(s, "refreshnocache", obs.obs_data_get_bool(settings, "refresh"))

    obs.obs_source_update(source, s)

    obs.obs_data_release(s)
    obs.obs_source_release(source)
end

-- extract the video ID from browser source url data 
-- string and output each in newline within the youtube ID textarea
function extract_param(url, param)
	local pattern = "[?&]" .. param .. "=([^&]+)"
	local res = url:match(pattern)

	if res then
		return res:gsub(",", "\n")
	end
		return url
end

function get_base_url(url)
	if string.find(url, "websitedons", 1, true) then
		return ""
	end
	
	local sep = string.find(url, "%?")

	if sep then
		return string.sub(url, 1, sep - 1)
	else
		return url
	end
end

function maax.on_change(props, property, settings)
    local state = obs.obs_data_get_bool(settings, "enable_custom_url")
    local furl = obs.obs_properties_get(props, "iframe_new_url")
    local desc = obs.obs_properties_get(props, "iframe_new_url_desc")
    
    -- determine if the checkbox was just checked
    -- load the source URL if it's currently unchecked and now being checked
    if state then
        local current_source = obs.obs_data_get_string(settings, "target_source")
        if current_source ~= "" then
            local selectedsource = obs.obs_get_source_by_name(current_source)
            if selectedsource ~= nil then
                local selectedsource_settings = obs.obs_source_get_settings(selectedsource)
                local now_current_url = get_base_url(obs.obs_data_get_string(selectedsource_settings, "url"))
                
                -- Only set the data if it's currently empty, 
                -- to avoid overwriting a user's typed input
                if obs.obs_data_get_string(settings, "iframe_new_url") == "" then
                    obs.obs_data_set_string(settings, "iframe_new_url", now_current_url)
                end
                
                obs.obs_data_release(selectedsource_settings)
                obs.obs_source_release(selectedsource)
            end
        end
    else
        -- clear the data if the checkbox is unchecked
        obs.obs_data_set_string(settings, "iframe_new_url", "")
    end

    -- Update visibility
    if desc then obs.obs_property_set_visible(desc, state) end
    if furl then obs.obs_property_set_visible(furl, state) end
    
    return true
end