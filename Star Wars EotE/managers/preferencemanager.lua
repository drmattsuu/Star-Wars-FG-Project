local SPECIAL_MSGTYPE_PREFERENCECHANGED = "preferencechanged";

local entries = {};
local groups = {};
local values = {};
local observers = {};

function onInit()

	-- subscribe to user logins
	if User.isHost() then
		User.onLogin = onLogin;	
	end
	
	-- register a special message for shared preference changes
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_PREFERENCECHANGED, processPreferenceChangedMessage);	

	-- initialize the registry preferences
	if not CampaignRegistry.preferences then
		CampaignRegistry.preferences = {};
	end
	values = CampaignRegistry.preferences;

	-- register default preferences
	if not User.isLocal() then
		registerOption("images_snaptogrid", "Images", "Snap to grid", "boolean", true, false);
		registerOption("interface_showdicetower", "Interface", "Show dice tower on desktop", "boolean", false, true);					
		if User.isHost() then
			registerOption("user_gmidentity", "User", "Gamemaster identity", "string", "GM", false);
			registerOption("images_hexgrid", "Images", "Use hex grid", "boolean", false, false);
		end
	end
	registerOption("interface_closebutton", "Interface", "Show close button on windows", "boolean", true, false);
	registerOption("interface_resetmodifierstack", "Interface", "Reset modifier stack after die roll or drag", "boolean", true, false);
	registerOption("interface_motd", "Interface", "Show Message of the Day (MOTD) on startup", "boolean", true, false);
	registerOption("interface_cleardicepoolondrag", "Dice", "Clear dice pool on drag", "boolean", true, false);
	registerOption("interface_showdicepooltracker", "Dice", "Show dice pool tracker to players (activates when player joins game)", "boolean", true, true);	
	
	--The following option removed as ruleset automation relies on the dice summary (INIT, Damage, etc.).
	--registerOption("interface_showdiceresultsummary", "Dice", "Show dice result summary", "boolean", true, true);		
	
	-- New section - versions
	if User.isLocal() then
		registerOption("version_edgeoftheempire", "Star Wars FFG Versions", "Edge of the Empire", "boolean", true, false);	
		registerOption("version_ageofrebellion", "Star Wars FFG Versions", "Age of Rebellion", "boolean", true, false);
		registerOption("version_forceanddestiny", "Star Wars FFG Versions", "Force and Destiny", "boolean", true, false);	
	else
		registerOption("version_edgeoftheempire", "Star Wars FFG Versions", "Edge of the Empire", "boolean", true, true);	
		registerOption("version_ageofrebellion", "Star Wars FFG Versions", "Age of Rebellion", "boolean", true, true);
		registerOption("version_forceanddestiny", "Star Wars FFG Versions", "Force and Destiny", "boolean", true, true);
	end
	
	-- Hide Edge of the Empire specific items
	--registerOption("hide_edgeoftheempire", "Star Wars FFG Versions", "Hide Edge of the Empire specific details", "boolean", false, false);

end

function onLogin(username, activated)
	if User.isHost() and activated then
		for k,v in pairs(entries) do
			if v.shared then
				setValue(v.name, getValue(v.name));
			end
		end
	end
end

function registerOption(name, group, label, type, default, shared)

	-- create the preference entry
	local entry = {};
	entry.name = name;
	entry.group = group;
	entry.label = label;
	entry.type = type;
	entry.default = default;
	entry.shared = shared;
	
	-- add the entry
	entries[name] = entry;
	
	-- add the entry to the groups
	if not groups[group] then
		groups[group] = {};
	end
	table.insert(groups[group], entry);
	
	-- create the entry value if required
	if values[name] == nil then
		values[name] = default;
	end
		
end

function populateDialog(w)
	for k,v in pairs(groups) do
		local g = w.groups.createWindow();
		
		-- Set group label
		g.label.setValue(k);
		
		-- Populate group
		for ek, entry in pairs(v) do
			if not entry.shared or (entry.shared and User.isHost()) then
				local e = g.entries.createWindowWithClass("preferences_entry_" .. entry.type);
				e.label.setValue(entry.label);
				e.setOptionData(entry);
			end
		end
	end
end

function setValue(name, value)
	local entry = entries[name];
	if entry.shared then
		local msgparams = {};	
		msgparams[1] = name;
		if entry.type ~= "boolean" then
			msgparams[2] = value;
		else
			if value then
				msgparams[2] = 1;
			else
				msgparams[2] = 0;
			end
		end
		ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_PREFERENCECHANGED, msgparams)
	else
		values[name] = value;
		if observers[name] then
			for k, v in pairs(observers[name]) do
				v(name, value);
			end
		end
	end
end

function getValue(name)
	return values[name];
end

function processPreferenceChangedMessage(msguser, msgidentity, msgparams)
	local name = msgparams[1];
	local value = msgparams[2];
	local entry = entries[name];
	if entry.type == "number" then
		value = tonumber(value);
	elseif entry.type == "boolean" then
		value = tonumber(value);
		if value == 0 then
			value = false;
		else
			value = true;
		end
	end
	values[name] = value;
	if observers[name] then
		for k, v in pairs(observers[name]) do
			v(name, value);
		end
	end		
end

function registerValueObserver(name, observer)
	if not observers[name] then
		observers[name] = {};
	end
	table.insert(observers[name], observer);
end

function unregisterValueObserver(name, observer)
	if observers[name] then
		for k, v in pairs(observers[name]) do
			if v == observer then
				observers[name][k] = nil;
			end
		end
	end
end


