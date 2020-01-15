-- Module export LUA code.
-- Sept 13th 2014 - Trenloe: Modified to be compatible with FG 3.x.  Thanks for the pointers from the WFRP 3 code Stewart!

--local hostnodes = {};
--local commonnodes = {};
--local clientnodes = {};
local nodelist = {};
local tokenlist = {};
local moduleproperties = {};
local hasindex = false;


function onInit()
	registerMenuItem("Export", "edit", 5);
end

--function getExportState(window)
--	if window then
--		if window.host and window.host.getState() then
--			return "host";
--		elseif window.common and window.common.getState() then
--			return "common";
--		elseif window.client and window.client.getState() then
--			return "client";
--		end
--	end
--end

function getIndexState(window)
	if window and window.index and window.index.getValue() == 1 then
		return true;
	else
		return false;
	end
end

--function addExportNode(node, exportstate, indexstate, exportclass)
--	-- Find the correct export table
--	local nodetable = nil;
--	if exportstate == "host" then
--		nodetable = hostnodes;
--	elseif exportstate == "common" then
--		nodetable = commonnodes;
--	elseif exportstate == "client" then
--		nodetable = clientnodes;
--	else
--		return;
--	end
--	
--	local libnodename = "library." .. moduleproperties.namecompact;

function addExportNode(node)
	local nodeentrytable = {};
	
	nodeentrytable.import = node.getNodeName();

	if node.getCategory() then
		nodeentrytable.category = node.getCategory();
		nodeentrytable.category.mergeid = moduleproperties.mergeid;
	end
	
	nodelist[node.getNodeName()] = nodeentrytable;
end

function onMenuSelection(...)
	-- Reset data
	nodelist = {};
	tokenlist = {};
	moduleproperties = {};
	hasindex = false;

	-- Global properties
	moduleproperties.name = name.getValue();
	moduleproperties.file= file.getValue();
	moduleproperties.author = author.getValue();
	moduleproperties.thumbnail = thumbnail.getValue();
	moduleproperties.indexgroup = indexgroup.getValue();
	moduleproperties.mergeid = mergeid.getValue();

	moduleproperties.namecompact = string.lower(string.gsub(moduleproperties.name, "%W", ""));
	
	-- Pre checks
	if moduleproperties.name == "" then
		ChatManager.addMessage( { font = "systemfont", text = "Module name not specified" } );
		name.setFocus(true);
		return;
	end
	if moduleproperties.file == "" then
		ChatManager.addMessage( { font = "systemfont", text = "Module file not specified" } );
		file.setFocus(true);
		return;
	end
	
	-- Loop through categories
	for ck, cw in ipairs(categories.getWindows()) do
		-- Construct export lists
		if cw.all.getState() then
			-- Add all child nodes
			local sourcenode = DB.findNode(cw.exportsource);
			
			if sourcenode then
				for nk, nv in pairs(sourcenode.getChildren()) do
					if nv.getType() == "node" then
						addExportNode(nv);
					end
				end
			end
		else
			-- Loop through entries in category
			for ek, ew in ipairs(cw.entries.getWindows()) do
				addExportNode(ew.getDatabaseNode());
			end
		end
	end
	
	-- Tokens
	for tk, tw in ipairs(tokens.getWindows()) do
		table.insert(tokenlist, tw.token.getPrototype());
	end
	
	-- Export
	playervisible = false	-- New v3.3.0 parameter for player module.  Not used currently in this ruleset
	--if not Module.export(moduleproperties.name, moduleproperties.file, moduleproperties.author, hostnodes, commonnodes, clientnodes, tokenlist, moduleproperties.thumbnail) then
	if not Module.export(moduleproperties.name, moduleproperties.indexgroup, moduleproperties.author, moduleproperties.file, moduleproperties.thumbnail, nodelist, tokenlist, playervisible) then
		ChatManager.addMessage( { font = "systemfont", text = "Module export failed!" } );
	else
		ChatManager.addMessage( { font = "systemfont", text = "Module exported successfully" } );
	end
end
