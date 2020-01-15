local updating = false;

function onInit()
	createNewCategories("");
	
	Module.onModuleLoad = onModuleLoad;
	Module.onModuleUnload = onModuleUnload;
end

function onModuleLoad()
	updating = true;

	-- close all category headings
	for k, v in ipairs(getWindows()) do
		if v.getClass() == "library_category" then
			--Debug.console("Closing category window: ", v);
			v.close();
		end
	end

	createNewCategories("");
		
	updating = false;	
end

function onModuleUnload(moduleName)
	Debug.console("onModuleUnload = " .. moduleName);
	
	updating = true;

	-- close all category headings
	for k, v in ipairs(getWindows()) do
		if v.getClass() == "library_category" then
			--Debug.console("Closing category window: ", v);
			v.close();
		end
	end

	createNewCategories(moduleName);
		
	updating = false;	
end

function createNewCategories(moduleName)
	-- create new categories
	local categories = {};
	for k, v in ipairs(getWindows()) do
		local category = DB.getValue(v.getDatabaseNode(), "categoryname", "");
		if category ~= "" and not categories[category]  and DB.getModule(v.getDatabaseNode()) ~= moduleName then
			--Debug.console("category windowinstance = ", v);
			--Debug.console("Node = ", DB.findNode(v.getDatabaseNode().getNodeName()));
			--Debug.console("Module = ", DB.getModule(v.getDatabaseNode()));
			--Debug.console("Entry name = ", DB.getValue(v.getDatabaseNode(), "name", ""));
			local c = createWindowWithClass("library_category");
			c.name.setValue(category);
			categories[category] = category;
		end
	end	
end

function onListRearranged(listchanged)
	if listchanged then
		update();
	end
end

function update()
	if not updating then
		updating = true;
	
		-- close all category headings
--		for k, v in ipairs(getWindows()) do
--			if v.getClass() == "library_category" then
--				v.close();
--			end
--		end

		-- create new categories
--		local categories = {};
--		for k, v in ipairs(getWindows()) do
--			local category = DB.getValue(v.getDatabaseNode(), "categoryname", "");
--			if category ~= "" and not categories[category] then
				--Debug.console("categoryname = " .. category);
--				local c = createWindowWithClass("library_category");
--				c.name.setValue(category);
--				categories[category] = category;
--			end
--		end
	
		-- apply sort
		applySort();
	
		updating = false;
	end
end

function onSortCompare(w1, w2)
	--Debug.console("onSortCompare");
	local iscategory1, iscategory2;
	local category1, category2;

	if w1.getClass() == "library_section" then
		category1 = DB.getValue(w1.getDatabaseNode(), "categoryname", "");
		--Debug.console("W1 section name = " .. w1.name.getValue());
		iscategory1 = false;
	elseif w1.getClass() == "library_category" then
		category1 = w1.name.getValue();
		iscategory1 = true;
	end
	
	if w2.getClass() == "library_section" then
		category2 = DB.getValue(w2.getDatabaseNode(), "categoryname", "");
		--Debug.console("W2 section name = " .. w2.name.getValue());
		iscategory2 = false;
	elseif w2.getClass() == "library_category" then
		category2 = w2.name.getValue();
		iscategory2 = true;
	end
	
	if not category1 then
		category1 = "";
	end
	if not category2 then
		category2 = "";
	end

	if category1 ~= category2 then
		--Debug.console("Sorting on category: ", category1, category2);
		--Debug.console("category1, category2 = ", category1, category2);	
		return category1 > category2;
	end
	
	if iscategory1 then
		return false;
	elseif iscategory2 then
		return true;
	end
	
	local value1 = string.lower(w1.name.getValue());
	local value2 = string.lower(w2.name.getValue());
	if value1 ~= value2 then
		--Debug.console("Sorting on entry: ", value1, value2);
		--Debug.console("Name1, Name2 = ", value1, value2);	
		return value1 > value2;
	end
end
