local closing = false;

function onInit()
Debug.console("initslotempty.lua:onInit.");
	if getDatabaseNode().isOwner() then
		Debug.console("initslotempty.lua:onInit. databasenode is owned.");

		--registerMenuItem("End of Turn Actions", "deletetoken", 4);
	end
	if User.isHost() then
		registerMenuItem("Clear This Init Slot", "erase", 4);
		registerMenuItem("Delete This Init Slot", "delete", 6);		
	end
	Debug.console("initslotempty.lua:onInit.  End of function.");
end

function onMenuSelection(item)
	if item == 4 then
		InitiativeManager.clearInitSlot(getDatabaseNode());
	elseif item == 6 then
		InitiativeManager.removeInitSlot(getDatabaseNode());	
	end
end

function onDrop(x, y, draginfo)
	Debug.console("initslotempty.lua:onDrop.  Class = " .. self.getClass());
	NpcManager.onDrop(getDatabaseNode(), x, y, draginfo);
	return true;
end