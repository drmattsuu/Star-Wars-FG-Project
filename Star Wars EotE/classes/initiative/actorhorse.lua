local closing = false;

function onInit()
	if getDatabaseNode().isOwner() then
		registerMenuItem("End of Turn Actions", "deletetoken", 4);
	end
	if User.isHost() then
		registerMenuItem("Delete", "delete", 6);		
	end
end

function onMenuSelection(item)
	if item == 4 then
		HorseManager.endOfTurn(getDatabaseNode());
	elseif item == 6 then
		InitiativeManager.removeActor(getDatabaseNode());	
	end
end

function onDrop(x, y, draginfo)
	return HorseManager.onDrop(getDatabaseNode(), x, y, draginfo);
end