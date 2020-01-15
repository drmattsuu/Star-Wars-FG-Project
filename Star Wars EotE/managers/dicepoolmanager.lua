function addCharacteristicDice(characteristicnode, dice)
	if characteristicnode then
		local characteristicvalue = characteristicnode.getValue();
		if characteristicvalue > 0 then
		
			-- attempt to get the stance nodes
			local stancenode = characteristicnode.getChild("...stance.current");
			local conservativenode = characteristicnode.getChild("...stance.conservative");
			local recklessnode = characteristicnode.getChild("...stance.reckless");
			
			-- determine how many conservative and reckless dice we need
			--local conservativevalue = 0;
			--local recklessvalue = 0;
			--if stancenode.getParent().getParent().getParent().getName() == "charsheet" then
			--	local stancevalue = stancenode.getValue();
			--	if stancevalue > 0 then
			--		recklessvalue = stancevalue;
			--	else
			--		conservativevalue = math.abs(stancevalue);
			--	end
			--else
			--	local stancevalue = stancenode.getValue();
			--	if stancevalue == 0 then
			--		if conservativenode then
			--			conservativevalue = conservativenode.getValue();
			--		end
			--		if recklessvalue then
			--			recklessvalue = recklessnode.getValue();
			--		end
			--	elseif stancevalue == 1 then
			--		if conservativenode then
			--			conservativevalue = conservativenode.getValue();
			--		end
			--	elseif stancevalue == 2 then
			--		if recklessvalue then
			--			recklessvalue = recklessnode.getValue();
			--		end				
			--	end
			--end
			
			-- now build the die pool according to the stance values
			--for i = 1, characteristicvalue do
			--	if recklessvalue >= i then
			--		table.insert(dice, "dReckless");
			--	elseif recklessvalue + conservativevalue >= i then
			--		table.insert(dice, "dConservative");
			--	else
			--		table.insert(dice, "dCharacteristic");
			--	end				
			--end
			
			-- add any bonus fortune dice
			local fortunenode = characteristicnode.getChild("..bonus");
			if fortunenode then
				local fortunevalue = fortunenode.getValue();
				if fortunevalue > 0 then
					for i = 1, fortunevalue do
						table.insert(dice, "dFortune");
					end
				end
			end
			
			-- determine if the characteristic is strained
			local strainednode = nil;
			local characteristicname = string.lower(characteristicnode.getParent().getName());
			if characteristicname == "strength" or characteristicname == "toughness" or characteristicname == "agility" then
				strainednode = characteristicnode.getChild("...fatigue");
			else
				strainednode = characteristicnode.getChild("...stress");
			end
			if strainednode then
				local strainedvalue = strainednode.getValue();
				if strainedvalue > characteristicvalue then
					strainedvalue = strainedvalue - characteristicvalue;
					for i = 1, strainedvalue do
						table.insert(dice, "dMisfortune");
					end					
				end
			end
			
		--my new code JL
		for i = 1, characteristicvalue do
			table.insert(dice, "dAbility");
		end
			
		end
	end
end

function addSkillDice(skillnode, dice)
	if skillnode then
	
		-- get the characteristic type for this skill
		local characteristictype = "";		
		local characteristictypenode = skillnode.getChild("characteristic");
		if characteristictypenode then
			characteristictype = string.upper(characteristictypenode.getValue());
		end
			
		-- if we have a characteristic type then locate the characteristic node
		local characteristicnode = nil;		
		if characteristictype ~= "" then
			if characteristictype == "STR" then
				characteristicnode = skillnode.getChild("...strength.current");
			elseif characteristictype == "TO" then
				characteristicnode = skillnode.getChild("...toughness.current");
			elseif characteristictype == "AG" then
				characteristicnode = skillnode.getChild("...agility.current");
			elseif characteristictype == "INT" then
				characteristicnode = skillnode.getChild("...intelligence.current");
			elseif characteristictype == "WP" then
				characteristicnode = skillnode.getChild("...willpower.current");
			elseif characteristictype == "FEL" then
				characteristicnode = skillnode.getChild("...fellowship.current");
			elseif characteristictype == "BR" then
				characteristicnode = skillnode.getChild("...brawn.current");
			elseif characteristictype == "IN" then
				characteristicnode = skillnode.getChild("...intellect.current");
			elseif characteristictype == "CU" then
				characteristicnode = skillnode.getChild("...cunning.current");
			elseif characteristictype == "WI" then
				characteristicnode = skillnode.getChild("...willpower.current");
			elseif characteristictype == "PR" then
				characteristicnode = skillnode.getChild("...presence.current");
			end		
		end
		
		-- if we have a characteristic node, and we always should
		if characteristicnode then	
			
			--get the total characteristic score
			local characteresticscore = 0;	
			characteresticscore = characteristicnode.getValue();			
			
			-- get the advances for this skill
			local advances = 0;		
			local advancesnode = skillnode.getChild("advances");
			if advancesnode then
				advances = advancesnode.getValue();
			end
			
			-- we take the smaller of skill or ability and make them all yellow dice. The rest are green
			if advances < characteresticscore then
				if advances >= 0 then
					for i = 1, advances do
						table.insert(dice, "dProficiency");
					end
					for i = advances+1, characteresticscore do
						table.insert(dice, "dAbility");
					end
				end	
			else		--we get here if skill advances are greater than ability score	
				for i = 1, characteresticscore do
					table.insert(dice, "dProficiency");
				end
				for i = characteresticscore+1, advances do
					table.insert(dice, "dAbility");
				end				
			end 
			
			
			-- add the characteristic dice
			--addCharacteristicDice(characteristicnode, dice);
			
			-- add the expertise dice
			--if advances > 0 then
			--	for i = 1, advances do
			--		if i <= 3 then
			--			table.insert(dice, "dExpertise");
			--		end
			--	end			
			--end
			
			
		end
	end
end

function addSpecialisationDice(specialisationnode, dice)
	if specialisationnode then
		local skillnode = specialisationnode.getChild("...");
		if skillnode then
			addSkillDice(skillnode, dice);
			table.insert(dice, "dFortune");
		end
	end
end

function addActionDice(actionnode, dice)
	if actionnode then
	
		-- determine the type of this action
		local type = "";
		local typenode = actionnode.getParent();
		if typenode then
			local typename = typenode.getName();
			if typename == "blessings" then
				type = "blessing";
			elseif typename == "melee" then
				type = "melee";
			elseif typename == "ranged" then
				type = "ranged";
			elseif typename == "social" then
				type = "social";
			elseif typename == "spells" then
				type = "spell";
			elseif typename == "support" then
				type = "support";
			end
		end
	
		-- get the check for this action
		local checkvalue = "";
		local checknode = actionnode.getChild("check");
		if checknode then
			checkvalue = checknode.getValue();
		end
		
		-- if a check value is provided
		if checkvalue ~= "" then
		
			-- convert the check value to lower case
			checkvalue = string.lower(checkvalue);
		
			-- generate the source check value
			local skillcheckvalue = checkvalue;
		
			-- if the check is a 'X vs Y' check, then extract the X value
			if string.find(skillcheckvalue, "vs") then
				skillcheckvalue = string.sub(skillcheckvalue, 1, string.find(skillcheckvalue, "vs") - 1);
			end
			
			-- trim the check value
			skillcheckvalue = string.gsub(skillcheckvalue, "^%s*(.-)%s*$", "%1");
		
			-- now perform some string replacements
			if skillcheckvalue == string.lower(LanguageManager.getString("WS")) then
				skillcheckvalue = string.lower(LanguageManager.getString("Weapon Skill"));
			end
			if skillcheckvalue == string.lower(LanguageManager.getString("BS")) then
				skillcheckvalue = string.lower(LanguageManager.getString("Ballistic Skill"));
			end
			
			-- now attempt to locate a skill based on this check
			local skillnode = nil;
			local skillsnode = actionnode.getChild("...skills");
			if skillsnode then
				for k, n in pairs(skillsnode.getChildren()) do
					if not skillnode then
						local namenode = n.getChild("name");
						if namenode and string.lower(namenode.getValue()) == skillcheckvalue then
							skillnode = n;
						end
					end
				end
			end

			-- if a skill node was located
			if skillnode then
			
				-- build a dice pool from the skill
				addSkillDice(skillnode, dice);
				
			else
			
				-- if no skill was located, then attempt to perform
				-- some mapping to characteristics
				-- this is required for npcs that have skills
				if skillcheckvalue == string.lower(LanguageManager.getString("Animal Handling")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Fellowship"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Athletics")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Strength"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Ballistic Skill")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Agility"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Chanelling")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Willpower"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Charm")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Fellowship"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Coordination")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Agility"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Discipline")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Willpower"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Education")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("First Aid")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Folk Lore")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Guile")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Fellowship"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Intimidate")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Strength"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Intuition")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Invocation")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Fellowship"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Leadership")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Fellowship"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Magical Sight")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Medicine")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Nature Lore")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Observation")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Piety")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Willpower"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Resilience")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Toughness"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Ride")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Agility"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Skulduggery")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Agility"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Spellcraft")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Intelligence"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Stealth")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Agility"));
				elseif skillcheckvalue == string.lower(LanguageManager.getString("Weapon Skill")) then
					skillcheckvalue = string.lower(LanguageManager.getString("Strength"));
				end
				
				-- attempt to locate the specified characteristic
				local characteristicnode = actionnode.getChild("..." .. skillcheckvalue .. ".current");
				if characteristicnode then
					addCharacteristicDice(characteristicnode, dice);
				end

			end
			
			-- if dice were added then add the difficulty dice
			if table.getn(dice) > 0 then
			
				-- if we have got this far, then we must determine the characters
				-- current stance in order to be able to add the appropriate difficulty
				local currentstance = nil;
				
				-- attempt to get the characters current stance
				local stancecurrentvalue = 0;
				local stancecurrentnode = actionnode.getChild("...stance.current");
				if stancecurrentnode then
					stancecurrentvalue = stancecurrentnode.getValue();
				end
				
				-- if the stance current value is not zero
				-- then apply the correct recharge value
				if stancecurrentvalue < 0 then
					currentstance = "conservative";
				elseif stancecurrentvalue > 0 then
					currentstance = "reckless";
				end
				
				-- if we have got this far, then either the character is in neutral stance
				-- or we are dealing with an npc
				-- we must therefore calculate the default stance for the character
				if not currentstance then
				
					local conservativestepsvalue = 0;
					local recklessstepsvalue = 0;
					
					-- attempt to get the current career
					local careernode = nil;
					local careersnode = actionnode.getChild("...careers");
					if careersnode then
						for k, n in pairs(careersnode.getChildren()) do
							if not careernode then
								local careercurrentnode = n.getChild("current");
								if careercurrentnode then
									if careercurrentnode.getValue() == 1 then
										careernode = n;
									end
								end
							end
						end
					end
					
					-- if we got the current career node, get the career stance values
					if careernode then
						local careerconservativenode = careernode.getChild("details.stance.conservative");
						if careerconservativenode then
							conservativestepsvalue = careerconservativenode.getValue();
						end
						local careerrecklessnode = careernode.getChild("details.stance.reckless");
						if careerrecklessnode then
							recklessstepsvalue = careerrecklessnode.getValue();
						end
					end
					
					-- get the purchased stance values
					local stanceconsvervativenode = actionnode.getChild("...stance.conservative");
					if stanceconsvervativenode then
						conservativestepsvalue = conservativestepsvalue + stanceconsvervativenode.getValue();
					end
					local stancerecklessnode = actionnode.getChild("...stance.reckless");
					if stancerecklessnode then
						recklessstepsvalue = recklessstepsvalue + stancerecklessnode.getValue();
					end
					
					-- choose the default stance based on which is greatest
					if conservativestepsvalue > recklessstepsvalue then
						currentstance = "conservative";
					elseif recklessstepsvalue > conservativestepsvalue then
						currentstance = "reckless";
					end
				end
				
				-- if we still do not have a stance value then
				-- we choose a default of conservative
				if not currentstance then
					currentstance = "conservative";
				end

				-- now that we know the characters stance, we can
				-- add all the corresponding difficulty dice and modifiers
			
				-- challenge
				local challengenode = actionnode.getChild(currentstance .. ".difficulty.challenge");
				if challengenode then
					local challengevalue = challengenode.getValue();
					if challengevalue > 0 then
						for i = 1, challengevalue do
							table.insert(dice, "dChallenge");
						end
					end
				end
				
				-- misfortune
				local misfortunenode = actionnode.getChild(currentstance .. ".difficulty.misfortune");
				if misfortunenode then
					local misfortunevalue = misfortunenode.getValue();
					if misfortunevalue > 0 then
						for i = 1, misfortunevalue do
							table.insert(dice, "dMisfortune");
						end
					end
				end
				
				-- fortune
				local fortunenode = actionnode.getChild(currentstance .. ".difficulty.fortune");
				if fortunenode then
					local fortunevalue = fortunenode.getValue();
					if fortunevalue > 0 then
						for i = 1, fortunevalue do
							table.insert(dice, "dFortune");
						end
					end
				end	

				-- expertise
				local expertisenode = actionnode.getChild(currentstance .. ".difficulty.expertise");
				if expertisenode then
					local expertisevalue = expertisenode.getValue();
					if expertisevalue > 0 then
						for i = 1, expertisevalue do
							table.insert(dice, "dExpertise");
						end
					end
				end						
				
				-- challenges
				local challengesnode = actionnode.getChild(currentstance .. ".modifiers.challenges");
				if challengesnode then
					local challengesvalue = challengesnode.getValue();
					if challengesvalue > 0 then
						for i = 1, challengesvalue do
							table.insert(dice, "mChallenge");
						end
					end
				end
				
				-- banes
				local banesnode = actionnode.getChild(currentstance .. ".modifiers.banes");
				if banesnode then
					local banesvalue = banesnode.getValue();
					if banesvalue > 0 then
						for i = 1, banesvalue do
							table.insert(dice, "mBane");
						end
					end
				end
				
				-- finally, if the action type is ranged, melee or contains 'Tgt Def' then
				-- we add a default challenge dice to the equation
				if type == "melee" or type == "ranged" or string.find(checkvalue, string.lower(LanguageManager.getString("Tgt Def")), 1, true) then
					table.insert(dice, "dChallenge");
				end
				
			end
		end
	end
end

--Added support for force rating dice - thanks to Archamus for this
function addForceDice(forcenode, dice)
	if forcenode then
		local forcetotal = forcenode.getChild("force.current");
		local forcevalue = forcetotal.getValue();
		if forcevalue > 0 then
			
		--my new code JL
		for i = 1, forcevalue do
			table.insert(dice, "dForce");
		end
			
		end
	end
end