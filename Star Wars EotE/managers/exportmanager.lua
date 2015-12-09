local categories = {};

function processExport(params)
	Interface.openWindow("export", "");
end

function onInit()

	-- setup export categories
	registerCategory("stories", "stories", "Story");
	registerCategory("images", "images", "Images & Maps");
	registerCategory("npclist", "npclist", "NPC's");
	registerCategory("items", "items", "Items");
	registerCategory("vehicle", "vehicle", "Vehicles");
	--registerCategory("locations", "locations", "Locations");

	-- register the slash handler
	ChatManager.registerSlashHandler("export", processExport);
end

function registerCategory(name, class, label)
	local cat = {};
	
	cat.name = name;
	cat.class = class;
	cat.label = label;
	
	table.insert(categories, cat);
end

function getCategories()
	return categories;
end