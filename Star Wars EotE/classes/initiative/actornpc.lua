local closing = false;

function onInit()
Debug.console("actornpc.lua:onInit.");
	if getDatabaseNode().isOwner() then
		--registerMenuItem("End of Turn Actions", "deletetoken", 4);
	end
	if User.isHost() then
		registerMenuItem("Delete NPC from Actor List", "delete", 6);		
	end
end

function onMenuSelection(item)
	if item == 4 then
		NpcManager.endOfTurn(getDatabaseNode());
	elseif item == 6 then
		InitiativeManager.removeActor(getDatabaseNode());	
	end
end

function onDrop(x, y, draginfo)
	Debug.console("actornpc.lua:onDrop.  Class = " .. self.getClass());
	NpcManager.onDrop(getDatabaseNode(), x, y, draginfo);
	return true;
end