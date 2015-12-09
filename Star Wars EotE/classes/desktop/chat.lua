--Mods: Trenloe, Nov 2013.  Added onInit function to write intro message to chat window.
local dragging = false;

function onInit()
	--local msg = {sender = "", font = "emotefont", icon="SW_logo"};
	-- Star Wars EotE logo removed for copyright reasons.
	local msg = {sender = "", font = "emotefont"};
    msg.text = "Star Wars®: Edge of the Empire community ruleset V2.1.0 (FG 3.0.12+), Initial v2 release: Star Wars Day 2015.  Update July 2015.  Base ruleset by JamesManhattan, heavily based on the WFRP 3e ruleset by Neil G. Foster.  Many, many additions by Trenloe.  Graphical update by Lobosolo  \rStar Wars and all associated elements are © 2014 Lucasfilm Ltd. & TM. All rights reserved.\r\rThis ruleset is a community project developed for no monetary gain and with the understanding that game mechanics are not protected by US Copyright laws: http://www.copyright.gov/fls/fl108.html  \rAs such, no literary work (which is covered by US Copyright) has been included in this ruleset.  Edge of the Empire, Age of Rebellion and Force and Destiny are trademarks owned by Fantasy Flight Games.  Reference to other copyrighted material in no way constitutes a challenge to the respective copyright holders of that material."
	-- Launch Message to chat window
    Comm.addChatMessage(msg);
	
	-- Display message of the day to the GM if the MOTD preference is enabled (by default in a new campaign).
	if User.isHost() and PreferenceManager.getValue("interface_motd") then
		local msg = {sender = "", font = "chatbolditalicfont", icon=""};
		-- Display Message of the Day to chat window
		msg.text = "Message of the Day: Additional options have been added to the campaign preferences Star Wars FFG Versions section:\rAge of Rebellion, Edge of the Empire and Force and Destiny version options.  These are on by default.\r\rTo turn off this message disable Interface -> Show Message of the Day (MOTD) on startup in the campaign Preferences."
		Comm.addChatMessage(msg);
	end
	
end

function onDrop(x, y, draginfo)
	Debug.console("draginfo.getType = " .. draginfo.getType());
	if draginfo.isType("chit") then
		Debug.console("Customdata = " .. draginfo.getCustomData());
		if draginfo.getCustomData() == "critical" then
			return addCritical();
		elseif draginfo.getCustomData() == "criticalvehicle" then
			return addCriticalVehicle();	
		end
	end
	if draginfo.getType() == "number" then
		ModifierStack.applyModifierStackToRoll(draginfo);
	end
end

function onDiceLanded(draginfo)
	local handler = ChatManager.getDiceHandler(draginfo);
	if handler then
		return handler(draginfo);
	end
end

function addCritical()
	
		Debug.console("Running addCritical dropped in chat window")
	
		local modifier = 0;
		
		-- Set the description
		local description = "[CRITICAL]"
		
		-- build the dice table
		local dice = {};
		table.insert(dice, "d100");
		table.insert(dice, "d10");
		
		-- throw the dice - need to handle the result in the chatmanager handler.
		ChatManager.throwDice("dice", dice, modifier, description, {"", msgidentity, gmonly});

	
	-- and return
	return true;
		

end

function addCriticalVehicle()
	
	Debug.console("Running addCriticalVehicle dropped in chat window.")

	local modifier = 0;
	
	-- Set the description
	local description = "[CRITVEHICLE]"
	
	-- build the dice table
	local dice = {};
	table.insert(dice, "d100");
	table.insert(dice, "d10");

	-- throw the dice - need to handle the result in the chatmanager handler.
	ChatManager.throwDice("dice", dice, modifier, description, {npcnodename, msgidentity, gmonly});
	
	-- and return
	return true;

end