function onInit()
	Debug.console("initiativetracker.lua:onInit.");
	if getDatabaseNode().isOwner() then
		--registerMenuItem("End of Turn Actions", "deletetoken", 4);
	end
	if User.isHost() then
		registerMenuItem("Delete all NPCs from tracker", "delete", 6);
		registerMenuItem("CONFIRM - Delete all NPCs from tracker???", "delete", 6, 3);		
	end
	
	self.onSizeChanged = onSizeChanged;
	
	InitiativeManager.buildActedThisRound();
	
	-- Show or hide vehicles based off showvehicles button state
	toggleVehicles(showvehicles.getState());
	
end

function onSizeChanged(source)
	if source.getClass() == "initiativetracker" then
		if source then
			local wWindow, hWindow = source.getSize();
			local listcontrolheight = (hWindow - 140) / 2;
--LOBOSOLO updating bounds of lists - BEGIN--
			source.trackerinitslotlist.setStaticBounds(12, 62, -28, listcontrolheight - 17);
			source.actorlist.setStaticBounds(12, -35 - listcontrolheight, -28, listcontrolheight - 17);
--LOBOSOLO updating bounds of lists - END--
		end					
	end
end

function onMenuSelection(item, subitem)
	if item == 4 then
		NpcManager.endOfTurn(getDatabaseNode());
	elseif item == 6 and subitem == 3 then
		for k,v in pairs (trackerinitslotlist.getWindows()) do
			if v.initslotclassname.getValue() == "npc" then
				InitiativeManager.removeInitSlot(v.getDatabaseNode());
			end
		end
		
		for k,v in pairs (actorlist.getWindows()) do
			--Debug.console("initiativetracker.lua:onMenuSelection - actorlist window class = " .. v.getClass());
			if v.getClass() == "actornpc" then
				--Debug.console("initiativetracker.lua:onMenuSelection - actorlist npcactor node = " .. v.getDatabaseNode().getNodeName());
				InitiativeManager.removeActor(v.getDatabaseNode());
			end
		end		

	end
end

function onDrop(x, y, draginfo)
	return true;
end

function clearTracker()
	for k,v in pairs (trackerinitslotlist.getWindows()) do
			InitiativeManager.removeInitSlot(v.getDatabaseNode());
	end
	
	for k,v in pairs (actorlist.getWindows()) do
		--Debug.console("initiativetracker.lua:onMenuSelection - actorlist window class = " .. v.getClass());
			--Debug.console("initiativetracker.lua:onMenuSelection - actorlist npcactor node = " .. v.getDatabaseNode().getNodeName());
			InitiativeManager.removeActor(v.getDatabaseNode());
	end	
end

function rollAllInit()
	local initSkill = self.init_skill_value.getInitSkill();
	Debug.console("Rolling All Inits.  Skill = " .. initSkill);
	
	for k,v in pairs (actorlist.getWindows()) do
		--Debug.console("initiativetracker.lua:onMenuSelection - actorlist window class = " .. v.getClass());
			Debug.console("initiativetracker.lua:rollAllInit - actorlist npcactor node = " .. v.getDatabaseNode().getNodeName());
			
			local skillsnode = v.getDatabaseNode().getChild("skills");
			local initskillnode = nil;
			local initskillname = "";
			--Debug.console("Skills node = " .. skillsnode.getNodeName());
			if initSkill == "Cool" then	
				initskillname = "Cool (Pr)";
			elseif initSkill == "Vig." then
				initskillname = "Vigilance (Will)";
			end

			for k,v in pairs(skillsnode.getChildren()) do
				--Debug.console("Looking at current child: " .. k);
				if v.getChild("name").getValue() == initskillname then
					--Debug.console("Have the " .. initskillname .. " db node = " .. v.getNodeName());
					initskillnode = v;
					break;
				end
			end	

			-- Populate the diebox with the dice for this INIT roll.
			local dice = {};
			local skilldescription;
			local msgidentity = DB.getValue(initskillnode, "...name", "");
			DicePoolManager.addSkillDice(initskillnode, dice);
			if table.getn(dice) > 0 then
				if initskillnode.getChild("name") then
					skilldescription = initskillnode.getChild("name").getValue() .. " [INIT]";		
				end
				DieBoxManager.addSkillDice(skilldescription, dice, initskillnode, msgidentity);
			end			
			
			--Roll the dice in the diebox - INIT will be populated to the correct init slot when the dice roll ends.
			DieBoxManager.rollInitDice();
			
			--InitiativeManager.updateActorInitiative(v.getDatabaseNode(), initiativecount)
			--InitiativeManager.removeActor(v.getDatabaseNode());
	end	

end

function rollNPCInit()
	local initSkill = self.init_skill_value.getInitSkill();
	Debug.console("Rolling NPC Inits.  Skill = " .. initSkill);
	
	for k,v in pairs (actorlist.getWindows()) do
		Debug.console("initiativetracker.lua:onMenuSelection - actorlist window class = " .. v.getClass());
		if v.getClass() == "actornpc" then
			Debug.console("initiativetracker.lua:rollAllInit - actorlist npcactor node = " .. v.getDatabaseNode().getNodeName());
			
			local skillsnode = v.getDatabaseNode().getChild("skills");
			if not skillsnode then
				Debug.chat("No skills node available to roll initiative - skipping.  Make sure the skills tab on the NPC sheet has previously been opened for: " .. v.getDatabaseNode().getChild("name").getValue())
				break;
			end
			
			local initskillnode = nil;
			local initskillname = "";
			--Debug.console("Skills node = " .. skillsnode.getNodeName());
			if initSkill == "Cool" then	
				initskillname = "Cool (Pr)";
			elseif initSkill == "Vig." then
				initskillname = "Vigilance (Will)";
			end

			for k,v in pairs(skillsnode.getChildren()) do
				--Debug.console("Looking at current child: " .. k);
				if v.getChild("name").getValue() == initskillname then
					--Debug.console("Have the " .. initskillname .. " db node = " .. v.getNodeName());
					initskillnode = v;
					break;
				end
			end	

			-- Populate the diebox with the dice for this INIT roll.
			local dice = {};
			local skilldescription;
			local msgidentity = DB.getValue(initskillnode, "...name", "");
			DicePoolManager.addSkillDice(initskillnode, dice);
			if table.getn(dice) > 0 then
				if initskillnode.getChild("name") then
					skilldescription = initskillnode.getChild("name").getValue() .. " [INIT]";		
				end
				DieBoxManager.addSkillDice(skilldescription, dice, initskillnode, msgidentity);
			end			
			
			--Roll the dice in the diebox - INIT will be populated to the correct init slot when the dice roll ends.
			DieBoxManager.rollInitDice();
			
			--InitiativeManager.updateActorInitiative(v.getDatabaseNode(), initiativecount)
			--InitiativeManager.removeActor(v.getDatabaseNode());
		end
	end	

end

function rollPCInit()
	local initSkill = self.init_skill_value.getInitSkill();
	Debug.console("Rolling PC Inits.  Skill = " .. initSkill);
	
	for k,v in pairs (actorlist.getWindows()) do
		Debug.console("initiativetracker.lua:onMenuSelection - actorlist window class = " .. v.getClass());
		if v.getClass() == "actorcharsheet" then
			Debug.console("initiativetracker.lua:rollAllInit - actorlist npcactor node = " .. v.getDatabaseNode().getNodeName());
			
			local skillsnode = v.getDatabaseNode().getChild("skills");
			local initskillnode = nil;
			local initskillname = "";
			--Debug.console("Skills node = " .. skillsnode.getNodeName());
			if initSkill == "Cool" then	
				initskillname = "Cool (Pr)";
			elseif initSkill == "Vig." then
				initskillname = "Vigilance (Will)";
			end

			for k,v in pairs(skillsnode.getChildren()) do
				--Debug.console("Looking at current child: " .. k);
				if v.getChild("name").getValue() == initskillname then
					--Debug.console("Have the " .. initskillname .. " db node = " .. v.getNodeName());
					initskillnode = v;
					break;
				end
			end	

			-- Populate the diebox with the dice for this INIT roll.
			local dice = {};
			local skilldescription;
			local msgidentity = DB.getValue(initskillnode, "...name", "");
			DicePoolManager.addSkillDice(initskillnode, dice);
			if table.getn(dice) > 0 then
				if initskillnode.getChild("name") then
					skilldescription = initskillnode.getChild("name").getValue() .. " [INIT]";		
				end
				DieBoxManager.addSkillDice(skilldescription, dice, initskillnode, msgidentity);
			end			
			
			--Roll the dice in the diebox - INIT will be populated to the correct init slot when the dice roll ends.
			DieBoxManager.rollInitDice();
			
			--InitiativeManager.updateActorInitiative(v.getDatabaseNode(), initiativecount)
			--InitiativeManager.removeActor(v.getDatabaseNode());
		end
	end

end

function clearAllInit()
	Debug.console("Clearing All Inits...");
	
	for k,v in pairs (actorlist.getWindows()) do
		--Debug.console("initiativetracker.lua:onMenuSelection - actorlist window class = " .. v.getClass());
			Debug.console("initiativetracker.lua:rollAllInit - actorlist npcactor node = " .. v.getDatabaseNode().getNodeName());	
			InitiativeManager.updateActorInitiative(v.getDatabaseNode(), 0)
	end

end

function toggleVehicles(showVehicles)
	-- Shows or hides vehicle line in actorlist based off showvehicles button state
	for k,v in pairs(actorlist.getWindows()) do
		toggleVehicle(v, showVehicles);
	end
end

function toggleVehicle(wHandle, showVehicle)
	-- If either the CT wide showvehicles or the actor showvehicleinct or false, hide the actor vehicle details.
	if not wHandle.showvehicleinct.getState() or not showvehicles.getState() then
		showVehicle = false;
	end
	Debug.console("wHandle class name = " .. wHandle.getClass());
	if User.isHost() or wHandle.getClass() == "actorcharsheet" then
		wHandle.maxspeed_label.setVisible(showVehicle);
		wHandle.vehicle_speed.setVisible(showVehicle);
		wHandle.vehicle_strain_threshold.setVisible(showVehicle);
		wHandle.vehicle_strain_current.setVisible(showVehicle);
		wHandle.vehicle_hull_trauma_threshold.setVisible(showVehicle);
		wHandle.vehicle_hull_trauma_current.setVisible(showVehicle);	
	else
		wHandle.maxspeed_label.setVisible(false);
		wHandle.vehicle_speed.setVisible(false);
		wHandle.vehicle_strain_threshold.setVisible(false);
		wHandle.vehicle_strain_current.setVisible(false);
		wHandle.vehicle_hull_trauma_threshold.setVisible(false);
		wHandle.vehicle_hull_trauma_current.setVisible(false);	
	end
	wHandle.vehicle_token.setVisible(showVehicle);
	wHandle.vehicle_name.setVisible(showVehicle);
	wHandle.silhouette_label.setVisible(showVehicle);
	wHandle.vehicle_silhouette.setVisible(showVehicle);
	wHandle.currentspeed_label.setVisible(showVehicle);
	wHandle.vehicle_currentspeed.setVisible(showVehicle);

end


