function onInit()
	upgrade();
end

function copyNode(sourcenode, destinationnode)
	for k, n in pairs(sourcenode.getChildren()) do
		local node = destinationnode.createChild(n.getName(), n.getType());
		node.setValue(n.getValue());
		copyNode(n, node);
	end
end

function checkForDuplicateName(listnode, sourcenode)
	local sourcenamenode = sourcenode.getChild("name");
	if sourcenamenode then
		for k, n in pairs(listnode.getChildren()) do
			local listnamenode = n.getChild("name");
			if listnamenode then
				local listnamevalue = listnamenode.getValue();
				local sourcenamevalue = sourcenamenode.getValue();
				if listnamevalue ~= "" or sourcenamevalue ~= "" then
					if listnamevalue == sourcenamevalue then
						return true;
					end
				end
			end
		end
	end
	return false;
end

--
--
-- UPGRADING
--
--

function upgrade()

	-- upgrade the campaign registry
	upgradeCampaignRegistry();

	-- if the user is the host
	if User.isHost() then
	
		-- actors
		local actorsnode = DB.findNode("initiativetracker.actors");
		if actorsnode then
			upgradeActors(actorsnode);
		end
	
		-- characters
		local charactersnode = DB.findNode("charsheet");
		if charactersnode then
			upgradeCharacters(charactersnode);
		end
		
		-- npc groups
		local npcgroupsnode = DB.findNode("npcgroups");
		if npcgroupsnode then
			upgradeNpcGroups(npcgroupsnode);
		end

	end
end

function upgradeActors(actorsnode)
	for k, n in pairs(actorsnode.getChildren()) do
		upgradeActor(n);
	end	
end

function upgradeActor(actornode)

	-- classname
	local classnamenode = actornode.getChild("classname");
	if classnamenode then
		actornode.createChild("actor.classname", "string").setValue(classnamenode.getValue());
		classnamenode.delete();
	end

	-- recordname
	local sourcenode = nil;
	local recordnamenode = actornode.getChild("recordname");
	if recordnamenode then
		sourcenode = DB.findNode(recordnamenode.getValue());
		actornode.createChild("actor.recordname", "string").setValue(recordnamenode.getValue());
		recordnamenode.delete();
	else
		sourcenode = actornode;
	end
	
	-- active
	local activenode = sourcenode.getChild("active");
	if activenode then
		sourcenode.createChild("actor.active", "number").setValue(activenode.getValue());
		activenode.delete();
	end
	
	-- initiative
	local initiativenode = sourcenode.getChild("initiative");
	if initiativenode then
		sourcenode.createChild("actor.initiative", "number").setValue(initiativenode.getValue());
		initiativenode.delete();
	end
	
end

function upgradeCampaignRegistry()
	if not CampaignRegistry.version or CampaignRegistry.version < 1.3 then
		CampaignRegistry.version = 1.3;
		CampaignRegistry.windowpositions = {};	
	end
end

function upgradeCharacters(charactersnode)
	for k, n in pairs(charactersnode.getChildren()) do
		upgradeCharacter(n);
	end	
end

function upgradeCharacter(characternode)

	-- blessings
	local blessingsnode = characternode.getChild("blessings");
	if blessingsnode then
		upgradeActions(blessingsnode);
	end
	
	-- melee
	local meleenode = characternode.getChild("melee");
	if meleenode then
		upgradeActions(meleenode);
	end
	
	-- ranged
	local rangednode = characternode.getChild("ranged");
	if rangednode then
		upgradeActions(rangednode);
	end
	
	-- social
	local socialnode = characternode.getChild("social");
	if socialnode then
		upgradeActions(socialnode);
	end
	
	-- spells
	local spellsnode = characternode.getChild("spells");
	if spellsnode then
		upgradeActions(spellsnode);
	end
	
	-- support
	local supportnode = characternode.getChild("support");
	if supportnode then
		upgradeActions(supportnode);
	end
	
	-- social tier
	upgradeSocialTier(characternode);
	
	-- followers
	upgradeFollowers(characternode);

end

function upgradeNpcGroups(npcgroupsnode)
	for k, n in pairs(npcgroupsnode.getChildren()) do
		upgradeNpcGroup(n);
	end
end

function upgradeNpcGroup(npcgroupnode)
	
	-- npcs
	local npcsnode = npcgroupnode.getChild("npcs");
	if npcsnode then
		upgradeNpcs(npcsnode);
	end

end

function upgradeNpcs(npcsnode)
	for k, n in pairs(npcsnode.getChildren()) do
		upgradeNpc(n);
	end
end

function upgradeNpc(npcnode)

	-- blessings
	local blessingsnode = npcnode.getChild("blessings");
	if blessingsnode then
		upgradeActions(blessingsnode);
	end
	
	-- melee
	local meleenode = npcnode.getChild("melee");
	if meleenode then
		upgradeActions(meleenode);
	end
	
	-- ranged
	local rangednode = npcnode.getChild("ranged");
	if rangednode then
		upgradeActions(rangednode);
	end
	
	-- social
	local socialnode = npcnode.getChild("social");
	if socialnode then
		upgradeActions(socialnode);
	end
	
	-- spells
	local spellsnode = npcnode.getChild("spells");
	if spellsnode then
		upgradeActions(spellsnode);
	end
	
	-- support
	local supportnode = npcnode.getChild("support");
	if supportnode then
		upgradeActions(supportnode);
	end

end

function upgradeActions(actionsnode)
	for k, n in pairs(actionsnode.getChildren()) do
		upgradeAction(n);
	end
end

function upgradeAction(actionnode)

	-- this code is for upgrading actions
	-- from version 1.0 of the ruleset to
	-- version 1.1. The changes that were
	-- made were to allow different recharge
	-- values to be specified for conservative
	-- and reckless stances
	local rechargenode = actionnode.getChild("recharge");
	if rechargenode then
	
		-- get the current recharge value as a string
		local rechargevalue = tostring(rechargenode.getValue());
		
		-- get the new conservative and reckless recharge values
		local conservativerecharge = 0;
		local recklessrecharge = 0;
		local periodposition = string.find(rechargevalue, "%.");
		if periodposition then
			conservativerecharge = string.sub(rechargevalue, 1, periodposition - 1);
			recklessrecharge = string.sub(rechargevalue, periodposition + 1, periodposition + 1);
		else
			conservativerecharge = rechargevalue;
			recklessrecharge = rechargevalue;
		end
		
		-- get the current conservative description
		local conservativedescription = nil;
		local conservativenode = actionnode.getChild("conservative");
		if conservativenode then
			conservativedescription = conservativenode.getValue();
		end
		
		-- get the current reckless description
		local recklessdescription = nil;
		local recklessnode = actionnode.getChild("reckless");
		if recklessnode then
			recklessdescription = recklessnode.getValue();
		end
		
		-- we now have all the details we require
		-- in order to upgrade this action
		
		-- delete the existing database nodes
		rechargenode.delete();
		if conservativenode then
			conservativenode.delete();
		end
		if recklessnode then
			recklessnode.delete();
		end
		
		-- create the new database nodes
		if conservativerecharge then
			actionnode.createChild("conservative.recharge", "number").setValue(conservativerecharge);
		end
		if conservativedescription then
			actionnode.createChild("conservative.description", "formattedtext").setValue(conservativedescription);
		end
		if recklessrecharge then
			actionnode.createChild("reckless.recharge", "number").setValue(recklessrecharge);
		end
		if recklessdescription then
			actionnode.createChild("reckless.description", "formattedtext").setValue(recklessdescription);
		end	
	end
	
	-- this code is for upgrading actions
	-- from version 1.2 of the ruleset to
	-- version 1.3. The changes that were
	-- made were to allow different difficulty
	-- values to be specified for conservative
	-- and reckless stances
	local challengenode = actionnode.getChild("challenge");
	if challengenode then
		actionnode.createChild("conservative.difficulty.challenge", "number").setValue(challengenode.getValue());
		actionnode.createChild("reckless.difficulty.challenge", "number").setValue(challengenode.getValue());
		challengenode.delete();
	end
	
	local misfortunenode = actionnode.getChild("misfortune");
	if misfortunenode then
		actionnode.createChild("conservative.difficulty.misfortune", "number").setValue(misfortunenode.getValue());
		actionnode.createChild("reckless.difficulty.misfortune", "number").setValue(misfortunenode.getValue());
		misfortunenode.delete();
	end
	
	local fortunenode = actionnode.getChild("fortune");
	if fortunenode then
		actionnode.createChild("conservative.difficulty.fortune", "number").setValue(fortunenode.getValue());
		actionnode.createChild("reckless.difficulty.fortune", "number").setValue(fortunenode.getValue());
		fortunenode.delete();
	end
	
	local expertisenode = actionnode.getChild("expertise");
	if expertisenode then
		actionnode.createChild("conservative.difficulty.expertise", "number").setValue(expertisenode.getValue());
		actionnode.createChild("reckless.difficulty.expertise", "number").setValue(expertisenode.getValue());
		expertisenode.delete();
	end
	
end

function upgradeSocialTier(characternode)
	local oldsocialtiernode = characternode.getChild("socialtier");
	if oldsocialtiernode then
		local newsocialtiernode = characternode.createChild("noble.tier", "string");
		newsocialtiernode.setValue(oldsocialtiernode.getValue());
		oldsocialtiernode.delete();
	end
end

function upgradeFollowers(characternode)
	local followersnode = characternode.getChild("followers");
	if followersnode then
		local petsnode = characternode.createChild("pets");
		copyNode(followersnode, petsnode);
		followersnode.delete();
	end
end