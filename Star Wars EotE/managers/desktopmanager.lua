stackcolumns = 2;
stackiconsize = { 47, 27 };
stackspacing = { 0, 0 };
stackoffset = { 5, 2 };

dockiconsize = { 91, 86 };
dockspacing = 4;
dockoffset = { 10, 4 };

stackcontrols = {};
dockcontrols = {};
subdockcontrols = {};

delayedCreate = {};

function onInit()

	registerPublicNodes();

	-- initialize the desktop
	if not User.isLocal() then
		if User.isHost() then
			registerStackShortcut("button_pointer", "button_pointer_down", "Colors", "pointerselection");
			registerStackShortcut("button_preferences", "button_preferences_down", "Preferences", "preferences");
			registerStackShortcut("button_characters", "button_characters_down", "Characters", "charactersheetlist", "charsheet");
			registerStackShortcut("button_portraits", "button_portraits_down", "Portraits", "portraitselection");
			registerStackShortcut("button_combat", "button_combat_down", "Initiative Tracker", "initiativetracker", "initiativetracker");
			registerStackShortcut("button_light", "button_light_down", "Lighting", "lightingselection");			
			registerStackShortcut("button_tracker", "button_tracker_down", "Dicepool Tracker", "dieboxview");	
			registerStackShortcut("button_modules", "button_modules_down", "Modules", "moduleselection");				

			registerDockShortcut("button_book", "button_book_down", "Story", "storylist", "stories");
			registerDockShortcut("button_maps", "button_maps_down", "Maps & Images", "imagelist", "images");
			--registerDockShortcut("button_people", "button_people_down", "NPCs", "npcgrouplist", "npcgroups");
			registerDockShortcut("button_encounters", "button_encounters_down", "NPCs", "npclist", "npclist");
			registerDockShortcut("button_itemchest", "button_itemchest_down", "Items", "itemlist", "items");
			--registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes" );
			--registerDockShortcut("button_locations", "button_locations_down", "Locations", "locationlist", "locations");
			registerDockShortcut("button_notes", "button_notes_down", "Library", "library");
			registerDockShortcut("button_tokens", "button_tokens_down", "Tokens", "tokenbag");
			
		else
			registerStackShortcut("button_pointer", "button_pointer_down", "Colors", "pointerselection");
			registerStackShortcut("button_preferences", "button_preferences_down", "Preferences", "preferences");
			registerStackShortcut("button_characters", "button_characters_down", "Characters", "identityselection");
			registerStackShortcut("button_portraits", "button_portraits_down", "Portraits", "portraitselection");
			registerStackShortcut("button_combat", "button_combat_down", "Initiative Tracker", "initiativetracker", "initiativetracker");
			if PreferenceManager.getValue("interface_showdicepooltracker") then
				registerStackShortcut("button_tracker", "button_tracker_down", "Dicepool Tracker", "dieboxview");			
			end
			registerStackShortcut("button_modules", "button_modules_down", "Modules", "moduleselection");			
			
			registerDockShortcut("button_book", "button_book_down", "Story", "storylist", "stories");
			registerDockShortcut("button_maps", "button_maps_down", "Maps & Images", "imagelist", "images");
			
			registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes." .. UserManager.getUserCode(User.getUsername()));
			--registerDockShortcut("button_people", "button_people_down", "Initiative Tracker", "initiativetracker", "initiativetracker");						
			registerDockShortcut("button_notes", "button_notes_down", "Library", "library");
			registerDockShortcut("button_tokencase", "button_tokencase_down", "Tokens", "tokenbag");
		end
	else
		registerStackShortcut("button_pointer", "button_pointer_down", "Colors", "pointerselection");
		registerStackShortcut("button_preferences", "button_preferences_down", "Preferences", "preferences");
		registerStackShortcut("button_characters", "button_characters_down", "Characters", "identityselection");
		registerStackShortcut("button_portraits", "button_portraits_down", "Portraits", "portraitselection");
		registerStackShortcut("button_combat", "button_combat_down", "Initiative Tracker", "initiativetracker", "initiativetracker");
		registerStackShortcut("button_modules", "button_modules_down", "Modules", "moduleselection");
		registerStackShortcut("button_library", "button_library_down", "Library", "library");
	end
end

function registerPublicNodes()
	if User.isHost() then
		DB.createNode("preferences").setPublic(true);
		DB.createNode("partysheet").setPublic(true);
		--DB.createNode("charsheet").setPublic(true);
		--DB.createNode("calendar").setPublic(true);
		DB.createNode("initiativetracker").setPublic(true);
		--DB.createNode("modifiers").setPublic(true);
		--DB.createNode("effects").setPublic(true);
		DB.createNode("lightsidechit").setPublic(true);
		DB.createNode("darksidechit").setPublic(true);
		DB.createNode("tokens").setPublic(true);
		
		-- Added to allow player side access to NPC token details - is this overkill?  Does it allow too much access?
		DB.createNode("npclist").setPublic(true);
	end
end

-- Chat window registration for general purpose message dispatching
function registerContainerWindow(w)
	window = w;

	-- Create controls that were requested while the window wasn't ready
	for k, v in pairs(delayedCreate) do
		v();
	end
	
	-- Add event handler for the window resize event
	window.onSizeChanged = updateControls;
end

-- Recalculate control locations
function updateControls()
	local maxy = 0;

	-- Stack (the small icons)
	for k, v in pairs(stackcontrols) do
		local n = k-1;
	
		local row = math.floor(n / stackcolumns);
		local column = n % stackcolumns;
	
		v.setStaticBounds((stackspacing[1] + stackiconsize[1]) * column + stackoffset[1], (stackspacing[2] + stackiconsize[2]) * row + stackoffset[2], stackiconsize[1], stackiconsize[2]);
		maxy = (stackspacing[2] + stackiconsize[2]) * (row+1) + stackoffset[2]
	end
	
	-- Calculate remaining available area
	local winw, winh = window.getSize();
	local availableheight = winh - maxy;
	local controlcount = #dockcontrols + #subdockcontrols;
	local neededheight = (dockspacing + dockiconsize[2]) * controlcount;
	
	local scaling = 1;
	if availableheight < neededheight then
		scaling = (availableheight - dockspacing * controlcount) / (dockiconsize[2] * controlcount);
	end

	-- Dock (the resource books)
	for k, v in pairs(dockcontrols) do
		local n = k-1;
		v.setStaticBounds(dockoffset[1] + (1-scaling)*dockiconsize[1]/2, maxy + (dockspacing + math.floor(dockiconsize[2]*scaling)) * n + dockoffset[2], math.floor(dockiconsize[1]*scaling), math.floor(dockiconsize[2]*scaling));
	end

	-- Subdock (the token icon)
	for k, v in pairs(subdockcontrols) do
		v.setStaticBounds(dockoffset[1] + (1-scaling)*dockiconsize[1]/2, winh - dockspacing*(k-1) - math.floor(dockiconsize[2]*scaling) * k, math.floor(dockiconsize[1]*scaling), math.floor(dockiconsize[2]*scaling));
	end
end

function registerStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName)
	function createFunc()
		createStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName);
	end

	if window == nil then
		table.insert(delayedCreate, createFunc);
	else
		createFunc();
	end
end

function createStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName)
	local control = window.createControl("stackitem", tooltipText);
	
	table.insert(stackcontrols, control);
	
	control.setIcons(iconNormal, iconPressed);
	control.setTooltipText(tooltipText);
	control.setValue(className, recordName or "");
	
	updateControls();
end

function registerDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock)
	function createFunc()
		createDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock);
	end

	if window == nil then
		table.insert(delayedCreate, createFunc);
	else
		createFunc();
	end
end

function createDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock)
	local control = window.createControl("dockitem", tooltipText);
	
	if useSubdock then
		table.insert(subdockcontrols, control);
	else
		table.insert(dockcontrols, control);
	end
	
	control.setIcons(iconNormal, iconPressed);
	control.setTooltipText(tooltipText);
	control.setValue(className, recordName or "");
	
	updateControls();
end

function openDesktopWindow(classname, recordname)
	local desktopwindowreference = Interface.findWindow(classname, recordname);
	if not desktopwindowreference then
		Interface.openWindow(classname, recordname);
	else
		desktopwindowreference.close();
	end
end
