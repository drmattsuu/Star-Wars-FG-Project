-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bShared = false;
local bIntact = true;

function onInit()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	if User.isHost() and node.getModule() then
		modified.setVisible(true);
		modified.setTooltipText(node.getModule());
		if node.isReadOnly() then
			modified.setIcon("record_readonly");
		end
		node.onIntegrityChange = onIntegrityChange;
		onIntegrityChange(node);
	end

	node.onObserverUpdate = onObserverUpdate;
	onObserverUpdate(node);
	
	if isidentified and nonid_name then
		onIDChanged();
	end
end

function onMenuSelection(selection)
	if selection == 7 then
		unshare();
	elseif selection == 8 then
		getDatabaseNode().revert();
	end
end

function buildMenu()
	resetMenuItems();
	
	if not bIntact then
		registerMenuItem(Interface.getString("menu_revert"), "shuffle", 8);
	end
	if bShared then
		registerMenuItem(Interface.getString("menu_unshare"), "unshare", 7);
	end
end

function onIntegrityChange()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	bIntact = node.isIntact();
	
	if bIntact then
		modified.setIcon("record_intact");
	else
		modified.setIcon("record_dirty");
	end

	buildMenu();
end

function onObserverUpdate()
	local node = getDatabaseNode();
	
	if User.isHost() then
		if node.isPublic() then
			access.setValue(3);
			access.setTooltipText(Interface.getString("tooltip_public"));
			bShared = true;
		else
			local sOwner = node.getOwner();
			local aHolderNames = {};
			local aHolders = node.getHolders();
			for _,sHolder in pairs(aHolders) do
				if sOwner then
					if sOwner ~= sHolder then
						table.insert(aHolderNames, sHolder);
					end
				else
					table.insert(aHolderNames, sHolder);
				end
			end
			
			bShared = (#aHolderNames > 0);
			if bShared then
				access.setValue(2);
				local sShared = Interface.getString("tooltip_shared") .. " " .. table.concat(aHolderNames, ", ");
				access.setTooltipText(sShared);
			else
				access.setValue(0);
				access.setTooltipText();
			end
		end
		
		buildMenu();
	else
		if node.isOwner() then
			if node.isPublic() then
				access.setValue(3);
			else
				access.setValue(0);
			end
		else
			access.setValue(1);
		end
	end
end

function unshare()
	Debug.console("campaign_list_record.lua: unshare()");
	local node = getDatabaseNode();
	if node.isPublic() then
		Debug.console("campaign_list_record.lua: unshare() setPublic(false)");
		node.setPublic(false);
	else
		Debug.console("campaign_list_record.lua: unshare() removeAllHolders");
		node.removeAllHolders(true);
	end
end

function onIDChanged()
	local bID = ItemManager.getIDState(getDatabaseNode());
	name.setVisible(bID);
	nonid_name.setVisible(not bID);
end
