function onInit()
	
	-- subscribe to window events
	Interface.onWindowOpened = onWindowOpened;
	Interface.onWindowClosed = onWindowClosed;
	
end

function onWindowOpened(window)
	if window.getClass() == "splash" then
		return nil;
	end

	local sourcename = "";
	if window.getDatabaseNode() then
		sourcename = window.getDatabaseNode().getNodeName();
	end

	if CampaignRegistry.windowpositions then
		if CampaignRegistry.windowpositions[window.getClass()] then
			if CampaignRegistry.windowpositions[window.getClass()][sourcename] then
				local pos = CampaignRegistry.windowpositions[window.getClass()][sourcename];
				
				window.setPosition(pos.x, pos.y);
				window.setSize(pos.w, pos.h);
			end
		end
	end
end

function onWindowClosed(window)
	if window.getClass() == "splash" then
		return nil;
	end

	if not CampaignRegistry.windowpositions then
		CampaignRegistry.windowpositions = {};
	end
	
	if not CampaignRegistry.windowpositions[window.getClass()] then
		CampaignRegistry.windowpositions[window.getClass()] = {};
	end
	
	-- Get window data source node name
	local sourcename = "";
	if window.getDatabaseNode() then
		sourcename = window.getDatabaseNode().getNodeName();
	end
	
	-- Get window positioning data
	local x, y = window.getPosition();
	local w, h = window.getSize();
	
	-- Store positioning data
	local pos = {};
	pos.x = x;
	pos.y = y;
	pos.w = w;
	pos.h = h;
	
	CampaignRegistry.windowpositions[window.getClass()][sourcename] = pos;
end

-- Copied from CoreRPG
function getReadOnlyState(nodeRecord)
	local bLocked = (DB.getValue(nodeRecord, "locked", 0) ~= 0);
	local bReadOnly = true;
	if nodeRecord.isOwner() and not nodeRecord.isReadOnly() and not bLocked then
		bReadOnly = false;
	end
	
	return bReadOnly;
end
