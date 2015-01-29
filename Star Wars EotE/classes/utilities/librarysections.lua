local updating = false;

function onListRearranged(listchanged)
	if listchanged then
		update();
	end
end

function update()
	if not updating then
		updating = true;
	
		-- close all category headings
		for k, v in ipairs(getWindows()) do
			if v.getClass() == "library_category" then
				v.close();
			end
		end

		-- create new categories
		local categories = {};
		for k, v in ipairs(getWindows()) do
			local category = DB.getValue(v.getDatabaseNode(), "categoryname", "");
			if category ~= "" and not categories[category] then
				local c = createWindowWithClass("library_category");
				c.name.setValue(category);
				categories[category] = category;
			end
		end
	
		-- apply sort
		applySort();
	
		updating = false;
	end
end

function onSortCompare(w1, w2)
	local iscategory1, iscategory2;
	local category1, category2;

	if w1.getClass() == "library_section" then
		category1 = DB.getValue(w1.getDatabaseNode(), "categoryname", "");
		iscategory1 = false;
	elseif w1.getClass() == "library_category" then
		category1 = w1.name.getValue();
		iscategory1 = true;
	end
	
	if w2.getClass() == "library_section" then
		category2 = DB.getValue(w2.getDatabaseNode(), "categoryname", "");
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
		return value1 > value2;
	end
end
