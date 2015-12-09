SPECIAL_MSGTYPE_REFRESHACTORLIST = "refreshactorlist";
SPECIAL_MSGTYPE_REFRESHINITSLOTLIST = "refreshinitslotlist";
SPECIAL_MSGTYPE_ADDTOINITSLOT = "clientaddtoinitslot";
SPECIAL_MSGTYPE_NEXTACTOR = "clientnextactor";

local actorlistnode = nil;
local actorlistcontrol = nil;
local initslotlistcontrol = nil;
local initslotlistnode = nil;
local activeinitslotnode = nil;
local actedthisroundlist = {};

function onInit()

	-- if host then create the actor list node and subscribe to user logins
	if User.isHost() then
	
		-- create the actor list node
		actorlistnode = DB.createNode("initiativetracker.actors");
		
		-- Create the init slot list node
		initslotlistnode = DB.createNode("initiativetracker.initslots");	

		-- Create the indicator for the currently active init slot class (npc or charsheet) - used to control the addtoinitslot button state
		--initslotlistnode.createChild("..activeslotclass", "string");
		--DB.createNode("initiativetracker.activeslotclass", "string");
		local activeslotnode = DB.createNode("initiativetracker.activeslotclass");
		--Debug.console("initiativemanager.lua:onInit() - activeslotnode = " .. activeslotnode.getNodeName());
		activeslotnode.createChild("slotactiveclass", "string").setValue("blank");
		activeslotnode.createChild("slotactiveactornode", "string").setValue("blank");
		--Debug.console("initiativemanager.lua:onInit() - activeslotnode.getValue = " .. activeslotnode.getChild("slotactiveclass").getValue());
		
		getActiveInitSlot();
		
		-- subscribe to the login events
		User.onLogin = onLogin;

		-- subscribe to module changes
		-- Trenloe - not sure why these are needed - these initiate cleaning the actor list when modules are activated/deactivated - shouldn't be needed???  Or, do these cause module state persisting?
		Module.onModuleAdded = onModuleAdded;
		Module.onModuleRemoved = onModuleRemoved;
		Module.onModuleUpdated = onModuleUpdated;
		
		-- Build actedthisroundlist table
		buildActedThisRound();

	end

	-- register special messages
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_REFRESHACTORLIST, handleRefreshActorList);
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_REFRESHINITSLOTLIST, handleRefreshInitSlotList);
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_ADDTOINITSLOT, handleClientAddToInitSlot);
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_NEXTACTOR, handleNextActor);
		
end

function clientAddToInitSlot(actornode)
	msg = {};
	msg[1] = actornode.getNodeName();
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_ADDTOINITSLOT, msg);
end

function handleClientAddToInitSlot(msguser, msgidentity, msgparams)
	if User.isHost() then
		local actornodename = msgparams[1];
		local actornode = DB.findNode(actornodename);
		if actornode then
			addToInitSlot(actornode);
		end
	end
end

function onLogin(username, activated)
--	if User.isHost() and activated then
	
		-- add the user as a holder of the initiative tracker node
--		DB.findNode("initiativetracker").addHolder(username);
		
		-- add the user as a holder for each of the source nodes
--		for k, v in pairs(actorlistnode.getChildren()) do
--			local recordnode = v.getChild("actor.recordname");
--			if recordnode then
--				local sourcenode = DB.findNode(recordnode.getValue());
--				if sourcenode then
--					sourcenode.createChild("actor.active", "number").addHolder(username);
--					sourcenode.createChild("actor.initiative", "number").addHolder(username);
--					sourcenode.createChild("name", "string").addHolder(username);
--				end
--			end
--		end	
--	end
end

function registerControl(control)
	--Debug.console("InitiativeManager.registerControl - control name = " .. control.getName());
	if control.getName() == "trackerinitslotlist" then
		initslotlistcontrol = control;
		handleRefreshInitSlotList();
	else
		actorlistcontrol = control;
		handleRefreshActorList();
	end
end

function addInitSlot(classname, recordname)
	Debug.console("addInitSlot - classname = " .. classname .. ", recordname = " .. recordname);
	-- Add a new init slot - called from addActor.
	if initslotlistcontrol then
	
		-- ensure that we have the initslot list node
		if not initslotlistnode then
			initslotlistnode = DB.findNode("initiativetracker.initslots");
		end
		--Debug.console("handleRefreshActorList.  initslotlistnode = " .. initslotlistnode.getName());
		
		--initslotlistcontrol.createWindowWithClass("initslotempty", n);
		
		
		-- add the actor
		local sourcenode = DB.findNode(recordname);
		--Debug.console("addInitSlot - sourcenode = " .. sourcenode.getNodeName());
		
		if sourcenode then
	
			-- create the actor node
			local initslotnode = initslotlistnode.createChild();
			initslotnode.createChild("actor.classname", "string").setValue(classname);
			
			-- if the sourcenode is static, then the actor node is the source
			if sourcenode.isStatic() then
			
				-- create the active, initiative, and name nodes for the actor
				initslotnode.createChild("actor.active", "number").setValue(0);
				initslotnode.createChild("actor.initiative", "number").setValue(0);
				initslotnode.createChild("name", "string");
				
				-- copy the details of the static node
				--DatabaseManager.copyNode(sourcenode, actornode);
				
			else
				
				-- create the record name node for the actor
				initslotnode.createChild("actor.recordname", "string").setValue(recordname);
				initslotnode.createChild("actor.initiative", "number").setValue(0);
				if classname == "charsheet" then
					initslotnode.createChild("initslotname", "string").setValue("Player Party Slot");
				elseif classname == "npc" then
					initslotnode.createChild("initslotname", "string").setValue("GM NPC Slot");
				end
				
				-- add all users as a holder
				for k, v in ipairs(UserManager.getCurrentUsers()) do
					initslotnode.addHolder(v);
				end			
			end
			--Debug.console("addInitSlot - adding window class with sourcenode of " .. initslotnode.getNodeName());
			initslotlistcontrol.createWindowWithClass("initslotempty", initslotnode);
			refreshInitSlotList();

		end
			
	end
end

function unregisterControl(control)
	if control then
		--Debug.console("InitiativeManager.unregisterControl - control name = " .. control.getName());
		if control.getName() == "trackerinitslotlist" then
			initslotlistcontrol = nil;
		else
			actorlistcontrol = nil;
		end
	end

end

function refreshActorList()
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_REFRESHACTORLIST, {});
end

function handleRefreshActorList(msguser, msgidentity, msgparams)
	if actorlistcontrol then
	
		-- ensure that we have the actor list node
		if not actorlistnode then
			actorlistnode = DB.findNode("initiativetracker.actors");
		end
		--Debug.console("handleRefreshActorList.  actorlistnode = " .. actorlistnode.getName());
		-- add any new windows.  Step through database actorlist node and compare nodes with windows in windowlist actorlistcontrol
		for k, n in pairs(actorlistnode.getChildren()) do
			local exists = false;
			for i, w in ipairs(actorlistcontrol.getWindows()) do
				local recordnode = n.getChild("actor.recordname");
				if recordnode then
					if w.getDatabaseNode().getNodeName() == recordnode.getValue() then
						exists = true;
					end
				else
					if w.getDatabaseNode().getNodeName() == n.getNodeName() then
						exists = true;
					end
				end
			end
			if not exists then
				local classnode = n.getChild("actor.classname");
				local recordnode = n.getChild("actor.recordname");
				if recordnode then
					Debug.console("handleRefreshActorList - looking to add record to actorlistcontrol:  " .. recordnode.getValue());
					local sourcenode = DB.findNode(recordnode.getValue());
					if sourcenode then
						actorlistcontrol.createWindowWithClass("actor" .. classnode.getValue(), sourcenode);
					else
						Debug.console("handleRefreshActorList - Cannot add " .. recordnode.getValue() .. " to actor list.  DB.findNode returns nil");
					end
				else
					actorlistcontrol.createWindowWithClass("actor" .. classnode.getValue(), n);			
				end
			end
		end
		
		-- remove any deleted windows
		for i, w in ipairs(actorlistcontrol.getWindows()) do
			local exists = false;
			for k, n in pairs(actorlistnode.getChildren()) do
				local recordnode = n.getChild("actor.recordname");
				if recordnode then
					if w.getDatabaseNode().getNodeName() == recordnode.getValue() then
						exists = true;
					end
				else
					if w.getDatabaseNode().getNodeName() == n.getNodeName() then
						exists = true;
					end
				end
			end
			if not exists then
				--Debug.console("handleRefreshActorList - removing window for actor: " .. k);
				w.close();
			end
		end		
	end
	return true;
end

function refreshInitSlotList()
	--Debug.console("refreshInitSlotList - starting");
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_REFRESHINITSLOTLIST, {});
end

function handleRefreshInitSlotList(msguser, msgidentity, msgparams)
	Debug.console("handleRefreshInitSlotList - starting");

	--if Interface.findWindow("initiativetracker","initiativetracker") then
		--Debug.console("handleRefreshInitSlotList - initiative tracker window open.");
		if initslotlistcontrol then
		
			-- ensure that we have the actor list node
			if not initslotlistnode then
				initslotlistnode = DB.findNode("initiativetracker.initslots");
			end
			--Debug.console("handleRefreshInitSlotList.  initslotlistnode = " .. initslotlistnode.getNodeName());
			-- add any new windows
			if initslotlistcontrol.getWindowCount() then
				for k, n in pairs(initslotlistnode.getChildren()) do
					--Debug.console("handleRefreshInitSlotList - stepping through initslot children: " .. n.getNodeName());
					local exists = false;
					--Debug.console("handleRefreshInitSlotList - about to call initslotlistcontrol.getWindows(), total windows to get : " .. initslotlistcontrol.getWindowCount());
					if initslotlistcontrol.getWindowCount() > 0 then
						for i, w in pairs(initslotlistcontrol.getWindows()) do
							--Debug.console("handleRefreshInitSlotList - stepping through initslot control windows: " .. i);
							local recordnode = n.getChild("actor.recordname");
							--Debug.console("handleRefreshInitSlotList - w.getDatabaseNode().getNodeName() = " .. w.getDatabaseNode().getNodeName());
							if recordnode then
								--Debug.console("handleRefreshInitSlotList - about to call w.getDatabaseNode().getChild(actor.recordname).");
								--if w.getDatabaseNode().getNodeName() == recordnode.getValue() then
								local windowdbnode = w.getDatabaseNode().getChild("actor.recordname");
								if windowdbnode then
									--Debug.console("handleRefreshInitSlotList - have a windowdbnode of: " .. windowdbnode.getNodeName());
									if windowdbnode.getNodeName() == recordnode.getNodeName() then
										exists = true;
									end
								end
							else
								if w.getDatabaseNode().getNodeName() == n.getNodeName() then
									exists = true;
								end
							end
						end
					end
					--Debug.console("handleRefreshInitSlotList. After stepping through initslot control windows.");
					if not exists then
						local classnode = n.getChild("actor.classname");
						local recordnode = n.getChild("actor.recordname");			
						if recordnode then
							local initslotnode = n;						
							if initslotnode then
								--Debug.console("handleRefreshInitSlotList - adding window class with sourcenode of initslotnode = " .. initslotnode.getNodeName());	
								--addInitSlot(classnode.getValue(), recordnode.getValue());
								initslotlistcontrol.createWindowWithClass("initslotempty", initslotnode);
								--Debug.console("handleRefreshInitSlotList - after createWindowWithClass.");
							end
						else
							--Debug.console("handleRefreshInitSlotList - adding window class with sourcenode of n = " .. n.getNodeName());
							initslotlistcontrol.createWindowWithClass("initslotempty", n);			
						end
					end
				end
			end
			
			--Debug.console("handleRefreshInitSlotList - about to remove deleted windows from the list.");
			-- remove any deleted windows
			for i, w in ipairs(initslotlistcontrol.getWindows()) do
				local exists = false;
				for k, n in pairs(initslotlistnode.getChildren()) do
					local recordnode = n.getChild("actor.recordname");
					if recordnode then
						if w.getDatabaseNode().getChild("actor.recordname").getNodeName() == recordnode.getNodeName() then
							exists = true;
						end
					else
						if w.getDatabaseNode().getNodeName() == n.getNodeName() then
							exists = true;
						end
					end
				end
				if not exists then
					w.close();
				end
			end		
		end
		--Debug.console("handleRefreshInitSlotList - ending - about to call getActiveInitSlot()");
		getActiveInitSlot();
		--Debug.console("handleRefreshInitSlotList - returning true.");
	--end
	
	return true;
end

function removeInitSlot(sourcenode)
	if User.isHost() then
		--Debug.console("removeInitSlot - starting.  Sourcenode = " .. sourcenode.getNodeName());
		for k, v in pairs(initslotlistnode.getChildren()) do
			--local recordnode = v.getChild("actor.recordname");
			if recordnode then
				if sourcenode.getNodeName() == v.getNodeName() then
					v.delete();
					break;
				end
			else
				if sourcenode.getNodeName() == v.getNodeName() then
					v.delete();
					break;
				end
			end
		end
		--refreshActorList();
		refreshInitSlotList();
	end
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.isType("playercharacter") or draginfo.isType("partyidentity") or draginfo.isType("npc") or draginfo.isType("retainer") or draginfo.isType("shortcut") then
			local classname, recordname = draginfo.getShortcutData();
			--Debug.console("initiativemanager.lua:onDrop.  Classname = " .. classname .. ", recordname = " .. recordname);
			if classname == "partysheet" then
				return addParty(classname, recordname);
			elseif classname == "npcgroup" then
				return addNpcGroup(classname, recordname);
			elseif classname == "charsheet" or classname == "npc" or classname == "pet" or classname == "horse" or classname == "retainer" then
				return addActor(classname, recordname);
			end
		end
	end
	return false;
end

function addParty(classname, recordname)
	if User.isHost() then
		for k,v in pairs(User.getAllActiveIdentities()) do
			addActor("charsheet", "charsheet." .. v, false);
		end
		return true;
	end
	return false;
end

function addNpcGroup(classname, recordname)
	if User.isHost() then
		local npcgroupnode = DB.findNode(recordname);
		if npcgroupnode then
			for k,v in pairs(npcgroupnode.createChild("npcs").getChildren()) do
				addActor("npc", v.getNodeName(), false);
			end
			return true;			
		end
	end
	return false;
end

function addActor(classname, recordname)
	if User.isHost() then
	
		-- ensure that the actor does not already exist - only do this for PCs
		if classname == "charsheet" then
			for k, v in pairs(actorlistnode.getChildren()) do
				local recordnode = v.getChild("actor.recordname");
				if recordnode and recordnode.getValue() == recordname then
					return false;
				end
			end
		end
	
		-- add the actor
		local sourcenode = DB.findNode(recordname);
		
		local newNPCName = "";
		if sourcenode then
			Debug.console("Record class = " .. classname);
			
			-- If an NPC - get the new NPC name - appending a number if it exists already.
			if classname == "npc" then
				newNPCName = getActorNPCName(sourcenode);
			end
	
			-- create the actor node
			local actornode = actorlistnode.createChild();
			actornode.createChild("actor.classname", "string").setValue(classname);
			
			-- if the sourcenode is static (cannot be edited, from a module, etc.), then the actor node is the source
			if sourcenode.isStatic() then
			
				-- create the active, initiative, and name nodes for the actor
				actornode.createChild("actor.active", "number").setValue(0);
				actornode.createChild("actor.initiative", "number").setValue(0);
				actornode.createChild("name", "string");
				
				-- copy the details of the static node
				DatabaseManager.copyNode(sourcenode, actornode);
				
			else
				
				if classname == "charsheet" then
					-- create the record name node for the actor - this is a link.
					actornode.createChild("actor.recordname", "string").setValue(recordname);
					recordname = actornode.getNodeName();
				elseif classname == "npc" then
					-- Copy the node
					DB.copyNode(sourcenode, actornode);
					-- set the new name
					actornode.getChild("name").setValue(newNPCName);
					recordname = actornode.getNodeName();
					Debug.console("Actornode recordname = " .. recordname);
				end
				
				-- add the active, initiative, and name nodes to the source
				local activenode = sourcenode.createChild("actor.active", "number");
				activenode.setValue(0);			
				local initiativenode = sourcenode.createChild("actor.initiative", "number");
				initiativenode.setValue(0);
				local namenode = sourcenode.createChild("name", "string");
				
				-- add all users as a holder
				for k, v in ipairs(UserManager.getCurrentUsers()) do
					activenode.addHolder(v);
					initiativenode.addHolder(v);
					namenode.addHolder(v);
				end			
			end
			
			addInitSlot(classname, recordname);
			
			-- refresh the actor node list
			refreshActorList();

			-- and return
			return true;
		end
	end
	return false;
end

function getActorNPCName(sourcenode)
	-- Looks for other instances of the same NPC name in the actor list and returns a new name with the next numeric at the end.
	local npcName = sourcenode.getChild("name").getValue();
	local newNPCName = npcName;
	Debug.console("Running getActorNPCName, name = " .. npcName);
	
	local actorlistNode = DB.findNode("initiativetracker.actors");
	if actorlistNode then
		local isMatch = false;
		local nNextNumber = 1;
		for k, v in pairs(actorlistnode.getChildren()) do
			Debug.console("Processing actor " .. k);
			if v.getChild("actor.classname").getValue() == "npc" then
				local actorName = v.getChild("name").getValue();
				Debug.console("Comparing actorName " .. actorName .. " with npcName " .. npcName);
				if actorName == npcName then
					-- We already have an actor with the same name.
					isMatch = true;
					break;
				end
			end
		end
		if isMatch then
			repeat
				-- We already have an actor with the same name - work out which number to add on the end.
				newNPCName = npcName .. " " .. nNextNumber;
				isMatch = false;
				for k, v in pairs(actorlistnode.getChildren()) do
					Debug.console("Processing actor " .. k);
					if v.getChild("actor.classname").getValue() == "npc" then
						local actorName = v.getChild("name").getValue();
						Debug.console("Comparing actorName " .. actorName .. " with npcName " .. newNPCName);
						if actorName == newNPCName then
							-- We already have an actor with the same name.
							isMatch = true;
							break;
						end
					end
				end
				nNextNumber = nNextNumber + 1;
			until not isMatch
		end
	
	end

	
	Debug.console("End of getActorNPCName, name = " .. npcName);	
	return newNPCName;
end

function removeActor(sourcenode)
	if User.isHost() then
		for k, v in pairs(actorlistnode.getChildren()) do
			local recordnode = v.getChild("actor.recordname");
			if recordnode then
				if sourcenode.getNodeName() == recordnode.getValue() then
					-- clear init values in base record
					local baseactornode = sourcenode.getChild("actor");
					if baseactornode then
						baseactornode.getChild("active").setValue(0);
						baseactornode.getChild("boost_dice").setValue(0);
						baseactornode.getChild("initiative").setValue(0);
						baseactornode.getChild("setback_dice").setValue(0);
					end
					v.delete();
					break;
				end
			else
				if sourcenode.getNodeName() == v.getNodeName() then
					v.delete();
					break;
				end
			end
		end
		refreshActorList();
	end
end

function activateActor(actornode)
	-- Usually called by the actoractiveindactor.lua onClickRelease event, when the GM clicks on the active indicator icon to the left of the initslot.
	--Debug.console("activateActor.  init tracker initslot node = " .. actornode.getNodeName());
	local activechartype = "";
	if User.isHost() then
		--for k, v in pairs(actorlistnode.getChildren()) do
		for k, v in pairs(initslotlistnode.getChildren()) do
			local sourcenode = v;
			--Debug.console("activateActor.  sourcenode = " .. sourcenode.getNodeName());
			-- set the active node
			local activenode = sourcenode.createChild("actor.active", "number");
			if sourcenode.getNodeName() == actornode.getNodeName() then
				activenode.setValue(1);
				-- Set activeinitslotnode for future use.
				activeinitslotnode = activenode;
				-- Store classname (charsheet or npc) so we can update the AddInitSlotButtons later
				activechartype = activenode.getChild("..classname").getValue();
				--Debug.console("activateActor.  activechartype = " .. activechartype);
			else
				activenode.setValue(0);
			end
		end
		
		-- Check if this slot already contains an actor from a previous action - don't want to  the actor from the acted this round table.
		--if actornode.getChild("initslot_actornodename").getValue() ~= "" then
		--	setAddToInitSlotButtons("none");
		--else
		--	setAddToInitSlotButtons(activechartype);
		--end
		
		refreshInitSlotList();
		
		return true;
	end
end

function cleanActorList()
	if User.isHost() then
		for k, v in pairs(actorlistnode.getChildren()) do
			local recordnode = v.getChild("actor.recordname");
			if recordnode then
				local sourcenode = DB.findNode(recordnode.getValue());
				if not sourcenode then
					v.delete();
				end
			end
		end
		refreshActorList();
	end
end

function onModuleAdded(name)
	if User.isHost() then
		cleanActorList()
	end
end

function onModuleRemoved(name)
	if User.isHost() then
		cleanActorList()
	end
end

function onModuleUpdated(name)
	if User.isHost() then
		cleanActorList()
	end
end

function endOfTurn()
	--enable all turn indicator flags
	--characterlist.enableAllTurnIndicators();
	
	if User.isHost() then
		--hostEndOfTurn();
		resetInitSlotList();
	else
		playerEndOfTurn();
	end
end

function playerEndOfTurn()
	if not User.isHost() then
		local identity = User.getCurrentIdentity();
		if identity then
			CharacterManager.endOfTurn(DB.findNode("charsheet." .. identity));
		end
	end
end

function hostEndOfTurn()
	if User.isHost() then
		local npcgroups = {};
		local npcs = {};
		
		-- remove party recharge
		PartySheetManager.endOfTurn();
	
		-- loop through each actor
		for k, v in pairs(actorlistnode.getChildren()) do
			local classnode = v.getChild("actor.classname");
			local recordnode = v.getChild("actor.recordname");
			if classnode and recordnode then
				local sourcenode = DB.findNode(recordnode.getValue());
				if sourcenode then
					local classname = classnode.getValue();
					if classname == "npc" then
					
						-- this actor represents an npc so add to the npc list
						if not npcs[sourcenode.getNodeName()] then
							npcs[sourcenode.getNodeName()] = sourcenode;
						end
					
						-- determine if this npc is a member of an npc group
						local parentnode = sourcenode.getParent();
						if parentnode then
							if parentnode.getName() == "npcs" then
								local npcgroupnode = parentnode.getParent();
								if npcgroupnode then
									if not npcgroups[npcgroupnode.getNodeName()] then
										npcgroups[npcgroupnode.getNodeName()] = npcgroupnode;
									end
								end
							end
						end
					end
				end
			end
		end
		
		-- remove recharge from each npc group that is referenced
		for k, v in pairs(npcgroups) do
			NpcGroupManager.endOfTurn(v);
		end
		
		-- remove recharge from each npc that is referenced
		for k, v in pairs(npcs) do
			NpcManager.endOfTurn(v);		
		end
		
	end
end

function updateActorInitiative(characternode, initiativecount)
	if User.isHost() then
		local characterNodeName = characternode.getNodeName();
		Debug.console("InitiativeManager.updateActorInitiative. characternode = " .. characterNodeName .. ", initiativecount = " .. initiativecount);
		--DB.setValue(characternode, "actor.initiative", "number", initiativecount);
		if string.match(characterNodeName, "charsheet") then
			-- We have a character sheet reference (PC not NPC) - need to find the correct initiativetracker.actors.id-XXXXX reference.
			local actorNode = nil;
			for k,v in pairs(actorlistnode.getChildren()) do
				Debug.console("Actor list node = " .. v.getNodeName());
				if v.getChild("actor.recordname") then
					Debug.console("Checking " .. v.getChild("actor.recordname").getValue() .. " with " .. characterNodeName);
					if v.getChild("actor.recordname").getValue() == characterNodeName then
						-- We have a match - use this record as the characternode
						characternode = v;
						break;
					end	
				end
			end
		end
		
		-- Step through initslots records and find the record added by this character - update that node with the new initiative.
		for k,v in pairs(initslotlistnode.getChildren()) do
			Debug.console("Looking at current child: " .. k .. " comparing " .. v.getChild("actor.recordname").getValue() .. " with " .. characternode.getNodeName());
			if v.getChild("actor.recordname").getValue() == characternode.getNodeName() then
				--Debug.console("Have the " .. initskillname .. " db node = " .. v.getNodeName());
				DB.setValue(v, "actor.initiative", "number", initiativecount);
				break;
			end
		end
	end
end

function getActiveInitSlot()
	if initslotlistnode then
		for k, v in pairs(initslotlistnode.getChildren()) do
			local sourcenode = v;
			-- Clear the current activeinitslotnode
			activeinitslotnode = nil;
			--Debug.console("getActiveInitSlot.  sourcenode = " .. sourcenode.getNodeName());
			-- set the active node
			--local activenode = sourcenode.getChild("actor.active");
			if sourcenode.getChild("actor.active").getValue() == 1 then
				-- Set activeinitslotnode for future use.
				activeinitslotnode = sourcenode;
				--Set the active classname (npc or charsheet) so that addtoinitslot buttons get enabled/disabled
				local activechartype = activeinitslotnode.getChild("actor.classname").getValue();
				
				-- Check if this slot already contains an actor from a previous action - don't want to activate buttons for the actor if they acted this round.
				if activeinitslotnode then
					if activeinitslotnode.getChild("initslot_actornodename") then
						if activeinitslotnode.getChild("initslot_actornodename").getValue() ~= "" then
							setAddToInitSlotButtons("none");
						else
							setAddToInitSlotButtons(activechartype);
						end
					end
				end
				
				--setAddToInitSlotButtons(activechartype);
				return activeinitslotnode;
			end
		end
	end
	return activeinitslotnode;
end

function setAddToInitSlotButtons(activechartype)
	-- activechartype can be npc or charsheet - use this to set the addToInitSlot button states
	--Debug.console("InitiativeManager.setAddToInitSlotButtons: activechartype = " .. activechartype);
	
	-- Only host can set the DB node value - should trigger onUpdate code on all clients to update he button state
	if User.isHost() then
		DB.findNode("initiativetracker.activeslotclass.slotactiveclass").setValue(activechartype);
	end
end

function addToInitSlot(actornode)
	--Debug.console("InitiativeManager.addToInitSlot - actornode.getNodeName = " .. actornode.getNodeName());
	if getActiveInitSlot() then
		--Debug.console("InitiativeManager.addToInitSlot - activeinitslotnode = " .. activeinitslotnode.getNodeName());
		local charactername = actornode.getChild("name").getValue();
		local charactertoken = actornode.getChild("token").getValue();
		local actornodename = actornode.getNodeName();
		local npcCategoryNode = actornode.getChild("npc_category");
		if npcCategoryNode then
			category = npcCategoryNode.getValue();
		else
			category = "pc";
		end
		--Debug.console("InitiativeManager.addToInitSlot - charactername = " .. charactername .. ", charactertoken = " .. charactertoken);
		-- Set name and token in the init slot
		activeinitslotnode.getChild("initslot_actornodename").setValue(actornodename);		
		activeinitslotnode.getChild("initslotname").setValue(charactername);
		activeinitslotnode.getChild("initslotactor_token").setValue(charactertoken);
		-- Create the category - NPC type (minion, rival, nemesis) or pc
		activeinitslotnode.createChild("npc_category").setValue(category);
		table.insert(actedthisroundlist, actornode);
	end
	--Refresh the init slot list and buttons
	refreshInitSlotList();
	return true;
end

function resetInitSlotList()
	-- Used at the end of the round to remove all actors assigned to init slots.
	local maxinitslotdbnode = nil;
	local maxinit = 0.0;
	local initslotlisttable = initslotlistcontrol.getWindows();
	if #initslotlisttable > 0 then
		for k, v in pairs(initslotlisttable) do
			local initslotdbnode = v.getDatabaseNode();
			local charactername = "";
			if initslotdbnode.getChild("actor.classname").getValue() == "npc" then
				charactername = "GM NPC Slot";
			elseif initslotdbnode.getChild("actor.classname").getValue() == "charsheet" then
				charactername= "Player Party Slot";
			end
			initslotdbnode.getChild("initslot_actornodename").setValue("");			
			initslotdbnode.getChild("initslotname").setValue(charactername);
			initslotdbnode.getChild("initslotactor_token").setValue("");
			initslotdbnode.getChild("actor.active").setValue(0);
			
			local thisslotinit = initslotdbnode.getChild("actor.initiative").getValue();
			
			if #initslotlisttable == 1 then
				initslotdbnode.getChild("actor.active").setValue(1);
			else
				if thisslotinit > maxinit then
					maxinit = thisslotinit;
					maxinitslotdbnode = initslotdbnode;
				elseif thisslotinit == maxinit then
					-- if maxinit values are equal, make a PC init higher
					if initslotdbnode.getChild("actor.initiative").getValue() == "charsheet" then
						maxinitslotdbnode = initslotdbnode;
					end		
				end
			end
		end
		if #initslotlisttable > 1 and maxinitslotdbnode then
			-- Set the active init slot as the first
			maxinitslotdbnode.getChild("actor.active").setValue(1);
		else
			if User.isHost() then
				Debug.chat("Cannot set init marker to first initslot as no initiative values are available.  Have all PCs and NPCs roll their initiative from the combat tab of their character sheets");
			end				
		end
	end
	
	-- Send the "reset" command to listening actorslots so as to change the name colour
	local nodeslotactiveclass = DB.findNode("initiativetracker.activeslotclass.slotactiveclass");
	if nodeslotactiveclass then
		nodeslotactiveclass.setValue("reset");
	end
	
	-- Reset acted this round table.
	actedthisroundlist = {};
	
	--Refresh the init slot list and buttons
	refreshInitSlotList();
end

function listActedThisRound()
	buildActedThisRound();
	for k,v in pairs(actedthisroundlist) do
			--Debug.console("InitiativeManager.listActedThisRound - actedthisroundlist table, row " .. k .. " = " .. v.getNodeName());
	end
	return actedthisroundlist;
end

function buildActedThisRound()
	-- Used when init tracker is opened to build the table of already acted actornodes from the database
	
	-- ensure that we have the initslot list node
	if not initslotlistnode then
		initslotlistnode = DB.findNode("initiativetracker.initslots");
	end
	
	--Clear the table before rebuilding
	actedthisroundlist = {};
	
	for k, v in pairs(initslotlistnode.getChildren()) do
		local initslotdbnode = v;
		if initslotdbnode.getChild("initslot_actornodename") then 
			local actornodename = initslotdbnode.getChild("initslot_actornodename").getValue();
			if actornodename ~= "" then
				table.insert(actedthisroundlist, DB.findNode(actornodename));
			end
		end
	end
end

function clearInitSlot(initslotdbnode)
	-- Used at the end of the round to remove all actors assigned to init slots.
	--Debug.console("InitiativeManager.clearInitSlot - initslotdbnode name = " .. initslotdbnode.getNodeName());
	if initslotdbnode then
		local initslotactordbnodename = initslotdbnode.getChild("initslot_actornodename").getValue();
		--Debug.console("InitiativeManager.clearInitSlot - initslotactordbnodename = " .. initslotactordbnodename);
		local charactername = "";
		if initslotdbnode.getChild("actor.classname").getValue() == "npc" then
			charactername = "GM NPC Slot";
		elseif initslotdbnode.getChild("actor.classname").getValue() == "charsheet" then
			charactername= "Player Party Slot";
		end
		initslotdbnode.getChild("initslotname").setValue(charactername);
		initslotdbnode.getChild("initslotactor_token").setValue("");
		initslotdbnode.getChild("initslot_actornodename").setValue("");
		-- Remove the actor from the acted this round table.
		for k,v in pairs(actedthisroundlist) do
			--Debug.console("InitiativeManager.clearInitSlot - actedthisround list line = " .. k .. ", " .. v.getNodeName());
			if v.getNodeName() == initslotactordbnodename then
				--Debug.console("InitiativeManager.clearInitSlot - removing " .. v.getNodeName());
				table.remove(actedthisroundlist, k);
				-- Reset the indicators
				getActiveInitSlot();
			end
		end
		refreshInitSlotList();
	end
end

function isOwnedIdentity(charsheetdbnode)
	-- Checks the nodename of the character sheet dbnode passed into the function and if this is an owned (controlled) identity then returns true.
	local ownedidentitylist = User.getOwnedIdentities();
	
	--Debug.console("InitiativeManager.isOwnedIdentity - owned identities = " .. table.concat(ownedidentitylist, ", ") .. ", node to check = " .. charsheetdbnode.getNodeName());
	
	for k,v in pairs(ownedidentitylist) do
		--Debug.console("InitiativeManager.isOwnedIdentity - k, v = " .. k .. ", " .. v);
		if charsheetdbnode.getNodeName() == ("charsheet." .. v) then
			--Debug.console("InitiativeManager.isOwnedIdentity = true!");
			return true;
		end	
	end
	
	return false;

end

function clientNextActor()

	-- Only allow a player to advance the active indicator if the currently active node is a PC
	-- only allow the owner of the current PC assigned to the init slot to advance the active indicator.
	local activeinitslotdbnode = getActiveInitSlot();
	
	if activeinitslotdbnode then
	
		if isOwnedIdentity(DB.findNode(activeinitslotdbnode.getChild("initslot_actornodename").getValue())) then
		
			--Debug.console("InitiativeManager.clientNextActor - owned identities = " .. table.concat(User.getOwnedIdentities(), ", "));
					
			--if activeinitslotdbnode.getChild("actor.classname").getValue() == "charsheet" then
				ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_NEXTACTOR, msg);
			--end
		end
	end
end

function handleNextActor(msguser, msgidentity, msgparams)
	if User.isHost() then
		nextActor();
	end
end

function nextActor()

	if User.isHost() then
		local activeinitslotdbnode = getActiveInitSlot();
		
		if activeinitslotdbnode then
		
			local initslotwindows = initslotlistcontrol.getWindows();
			
			for k,v in ipairs(initslotwindows) do
				if v.getDatabaseNode().getNodeName() == activeinitslotdbnode.getNodeName() then
					local nextinitslotwindow = initslotlistcontrol.getNextWindow(v);
					if nextinitslotwindow then
						v.getDatabaseNode().getChild("actor.active").setValue(0);
						nextinitslotwindow.getDatabaseNode().getChild("actor.active").setValue(1);
						refreshInitSlotList();
						return;
					elseif nextinitslotwindow == nil then
						-- We are at the end of the windows in the windowlist, set this last slot to inactive - i.e. all slots will now not be active - no active indicators shown.
						v.getDatabaseNode().getChild("actor.active").setValue(0);
						local nodeslotactiveclass = DB.findNode("initiativetracker.activeslotclass.slotactiveclass");
						if nodeslotactiveclass then
							nodeslotactiveclass.setValue("blank");
						end
						-- nextinitslotwindow.getDatabaseNode().getChild("actor.active").setValue(1);
						refreshInitSlotList();
						-- Write end of rounds message to all the chat window on all clients
						local msg = {};
						msg.font = "msgfont";
						msg.text = "End of Round.";
						ChatManager.deliverMessage(msg);
						return;
					end
				end
			end
		end
	end
end


function rebuildInitSlots()
	-- Deletes the current init slots and rebuilds them based on the current actor list.
	-- Handy if some init slots or actors have been deleted and the links between actors and init slots need tidying up.
	if User.isHost() then
		-- Delete all current init slots
		for k, v in pairs(initslotlistnode.getChildren()) do
			v.delete();
		end
		
		for k,actornode in pairs(actorlistnode.getChildren()) do
			recordname = actornode.getNodeName();
			classname = actornode.getChild("actor.classname").getValue();
			Debug.console("About to add " .. classname .. " with record " .. recordname)
			addInitSlot(classname, recordname);
		end
		
		-- refresh the init slot list
		refreshInitSlotList();
	end

end

function removeAllInitSlots()
	if User.isHost() then
		--Debug.console("removeInitSlot - starting.  Sourcenode = " .. sourcenode.getNodeName());
		for k, v in pairs(initslotlistnode.getChildren()) do
			v.delete();
		end
		--refreshActorList();
		--refreshInitSlotList();
	end
end
