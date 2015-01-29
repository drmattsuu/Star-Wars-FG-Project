entrymap = {};

function addCategories()
	local w;

	local categories = ExportManager.getCategories();
	
	for k, v in ipairs(categories) do
		w = createWindow();
		w.setExportName(v.name);
		w.setExportClass(v.class);
		w.label.setValue(v.label);
	end
end

function onInit()
	getNextWindow(nil).close();

	addCategories();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		for k,v in ipairs(getWindows()) do
			local class, recordname = draginfo.getShortcutData();
		
			-- Find matching export category
			if string.find(recordname, v.exportsource) == 1 then
				-- Check duplicates
				for l,c in ipairs(v.entries.getWindows()) do
					if c.getDatabaseNode().getNodeName() == recordname then
						return true;
					end
				end
			
				-- Create entry
				local w = v.entries.createWindow(draginfo.getDatabaseNode());
				w.open.setValue(class, recordname);
				
				v.all.setState(false);
				break;
			end
		end
		
		return true;
	end
end
