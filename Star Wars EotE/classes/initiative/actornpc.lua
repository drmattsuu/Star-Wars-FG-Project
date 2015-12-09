local closing = false;

function onInit()
Debug.console("actornpc.lua:onInit.");
	if getDatabaseNode().isOwner() then
		--registerMenuItem("End of Turn Actions", "deletetoken", 4);
	end
	if User.isHost() then
		registerMenuItem("Delete NPC from Actor List", "delete", 6);
		registerMenuItem("Roll Initiative", "turn", 7);		
	end
	
	Debug.console("Actor NPC database node = " .. getDatabaseNode().getNodeName());
	
	if getDatabaseNode().getChild("npc_category") then
		Debug.console("npc_category = " .. getDatabaseNode().getChild("npc_category").getValue());
		if string.lower(getDatabaseNode().getChild("npc_category").getValue()) == "minion" then
			strain_current.setVisible(false);
			strain_threshold.setVisible(false);
			
			minion_number_label.setVisible(true);
			minion_number_remaining.setVisible(true);

		else
			if string.lower(getDatabaseNode().getChild("npc_category").getValue()) == "nemesis" then
				if User.isHost() then
					strain_current.setVisible(true);
					strain_threshold.setVisible(true);
				end
			else
				strain_current.setVisible(false);
				strain_threshold.setVisible(false);					
			end
			
			minion_number_label.setVisible(false);
			minion_number_remaining.setVisible(false);				
		end
	end
	
end

function onMenuSelection(item)
	if item == 4 then
		NpcManager.endOfTurn(getDatabaseNode());
	elseif item == 6 then
		InitiativeManager.removeActor(getDatabaseNode());	
	elseif item == 7 then
		rollSingleNPCInit();		
	end
end

function onDrop(x, y, draginfo)
	Debug.console("actornpc.lua:onDrop.  Class = " .. self.getClass());
	NpcManager.onDrop(getDatabaseNode(), x, y, draginfo);
	return true;
end

function rollSingleNPCInit()
	local initSkill = windowlist.window.init_skill_value.getInitSkill();
	Debug.console("Rolling NPC Inits.  Skill = " .. initSkill);
	
	Debug.console("initiativetracker.lua:onMenuSelection - actorlist window class = " .. getClass());
	if getClass() == "actornpc" then
		Debug.console("initiativetracker.lua:rollAllInit - actorlist npcactor node = " .. getDatabaseNode().getNodeName());
		
		local skillsnode = getDatabaseNode().getChild("skills");
		if not skillsnode then
			Debug.chat("No skills node available to roll initiative - skipping.  Make sure the skills tab on the NPC sheet has previously been opened for: " .. v.getDatabaseNode().getChild("name").getValue())
			return;
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
