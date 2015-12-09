SPECIAL_MSGTYPE_UPDATEDIEBOXLIST = "updatedieboxlist";
SPECIAL_MSGTYPE_UPDATECLIENTDIEBOXLIST = "updateclientdieboxlist";

local updatingflag = false;

function onInit()
	Debug.console("dieboxviewlist.lua: onInit()");
	-- Register special message handler to share dicepool with other FG instances
	--ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_UPDATEDIEBOXLIST, handleUpdateDieBoxList);
	--ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_UPDATECLIENTDIEBOXLIST, handleUpdateClientDieBoxList);
	
	DieBoxViewListManager.registerControl(self);
	
	if User.isHost() then
		--if not updatingflag then
			DieBoxViewListManager.updateDieBoxList("");
			--DieBoxViewListManager.synchDieBoxData();
		--end
	else
		-- request user list from the GM.
		DieBoxViewListManager.updateClientDieBoxList();
		DieBoxViewListManager.synchDieBoxData();
	end
	
	-- TODO: Synch all dice boxes here!
	-- Need to go round all current dicepools and get values and then populate the diceboxviewlist.
	
end

function unregisterSMHandler()
	Debug.console("dieboxviewlist.lua: unregisterSMHandler()");
	--ChatManager.unregisterSpecialMessageHandler(SPECIAL_MSGTYPE_UPDATEDIEBOXLIST, handleUpdateDieBoxList);
	--ChatManager.unregisterSpecialMessageHandler(SPECIAL_MSGTYPE_UPDATECLIENTDIEBOXLIST, handleUpdateClientDieBoxList);
end

function updateClientDieBoxList()
	Debug.console("dieboxviewlist.lua: updateClientDieBoxList()");
	local msgparams = {};
	-- Only the GM can create the list of logged in users.
	msgparams[1] = User.getUsername();	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_UPDATECLIENTDIEBOXLIST, msgparams);		
		
end

function handleUpdateClientDieBoxList(msguser, msgidentity, msgparams)
	local username = msgparams[1];
	Debug.console("dieboxviewlist.lua: handleUpdateClientDieBoxList()  Username = " .. username);
	if User.isHost() then 
		updateDieBoxList(username);
	end

end

function updateDieBoxList(username)
	--username used to update only for a specific user - request from user side for an update
	Debug.console("dieboxviewlist.lua: updateDieBoxList()  getWindowCount() = " .. self.getWindowCount());
	local userlist = {};
	
	-- Only the GM can create the list of logged in users.
	if User.isHost() then
		-- Create the GM dieboxviewslot
		local gmname = "GM - " .. User.getUsername();
		table.insert(userlist, gmname);
		-- Create all of the dieboxviewslot windows based off all of the logged in players.
		for k,v in pairs(User.getActiveUsers()) do
			table.insert(userlist, v);
			--local dieboxwindow = createWindow();
			--dieboxwindow.setIdentityName(v);
		end	
		
		local msgparams = {};
		userliststring = table.concat(userlist, ",");
		Debug.console("dieboxviewlist.lua: updateDieBoxList().  User list = " .. userliststring);
		--Debug.console("dicepoolmanager.lua: readDicepool.  Dieliststring = " .. dieliststring);
		msgparams[1] = userliststring;	
		msgparams[2] = username;
		ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_UPDATEDIEBOXLIST, msgparams);		
	end	
		
end

function handleUpdateDieBoxList(msguser, msgidentity, msgparams)
	local userliststring = msgparams[1];
	local username = msgparams[2];	
	local userlist = {};
	Debug.console("dieboxviewlist.lua: handleUpdateDieBoxList()  userliststring = " .. userliststring .. ", username = " .. username);
	if username == "" or User.getUsername() == username then
		Debug.console("dieboxviewlist.lua: handleUpdateDieBoxList()  updating...");
		--updatingflag = true;
	
		--Debug.console("dicepoolmanager.lua: handleSendPlayerDicepool. msguser = " .. msguser .. ", msgidentity = " .. msgidentity);
		
		-- Make userlist table from userliststring
		userlist = StringManager.split(userliststring, ",");
		
		-- Remove all current windows in the windowlist - we will add in new ones.
		closeAll();
		-- Create all of the dieboxviewslot windows based off all of the logged in players.
		for k,v in pairs(userlist) do
			Debug.console("dieboxviewlist.lua: handleUpdateDieBoxList().  Looping through userlist table - " .. k .. ", " .. v);
			local dieboxwindow = createWindow();
			Debug.console("dieboxviewlist.lua: handleUpdateDieBoxList(). After creating window.");
			-- Set the name of the entry in the dicepool viewer to the name of the currently active PC for the player in question
			dieboxwindow.setIdentityName(User.getCurrentIdentity(v));
		end
		Debug.console("dieboxviewlist.lua: handleUpdateDieBoxList()  getWindowCount() = " .. self.getWindowCount());
	end
	--updatingflag = false;
	
	--Need to code on player side - use OOB?

end

function onClose()
	--InitiativeManager.unregisterControl();
end

function onDrop(x, y, draginfo)
	Debug.console("initslotlist.lua:onDrop.");
	local actorwindow = getWindowAt(x, y);
	if actorwindow then
		return actorwindow.onDrop(x, y, draginfo);
	else
		return InitiativeManager.onDrop(x, y, draginfo);
	end
end

--function onSortCompare(w1, w2)
--	if w1.initslotinitiative.getValue() ~= w2.initslotinitiative.getValue() then
--		return w1.initslotinitiative.getValue() < w2.initslotinitiative.getValue();
--	elseif w1.getClass() ~= w2.getClass() then
--		return w1.getClass() > w2.getClass();
--	elseif w1.initslotclassname.getValue() ~= w2.initslotclassname.getValue() then
--		return w1.initslotclassname.getValue() > w2.initslotclassname.getValue();
--	else
--		return w1.initslotname.getValue() > w2.initslotname.getValue();
--	end
--end