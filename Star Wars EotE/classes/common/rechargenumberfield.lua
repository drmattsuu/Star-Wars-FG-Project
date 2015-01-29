function onInit()
	super.onInit();
end

function onClickDown(button, x, y)
	if button == 2 then
		local sourcenode = getDatabaseNode();
		if not sourcenode.isStatic() then
		
			-- if a recharge value is specified, then use that
			if rechargevalue then
				setValue(tonumber(rechargevalue[1]));
				return true;
			end

			-- get the conservative recharge value for an action
			local conservativerechargevalue = 0;
			local conservativerechargenode = sourcenode.getChild("..conservative.recharge");
			if conservativerechargenode then
				conservativerechargevalue = conservativerechargenode.getValue();
			end
			
			-- get the reckless recharge value for an action
			local recklessrechargevalue = 0;
			local recklessrechargenode = sourcenode.getChild("..reckless.recharge");
			if recklessrechargenode then
				recklessrechargevalue = recklessrechargenode.getValue();
			end
			
			-- if both values are zero, then there is nothing to do
			if conservativerechargevalue == 0 and recklessrechargevalue == 0 then
				return true;
			end
			
			-- if both values are the same, then simply set to the conservative value
			if conservativerechargevalue == recklessrechargevalue then
				setValue(conservativerechargevalue);
				return true;
			end
			
			-- attempt to get the characters current stance
			local stancecurrentvalue = 0;
			local stancecurrentnode = sourcenode.getChild("....stance.current");
			if stancecurrentnode then
				stancecurrentvalue = stancecurrentnode.getValue();
			end
			
			-- if the stance current value is not zero
			-- then apply the correct recharge value
			if stancecurrentvalue < 0 then
				setValue(conservativerechargevalue);
				return true;
			end
			if stancecurrentvalue > 0 then
				setValue(recklessrechargevalue);
				return true;
			end
			
			-- if we have got this far, then either the character is in neutral stance
			-- or we are dealing with an npc
			-- we must therefore calculate the default stance for the character
			local conservativestepsvalue = 0;
			local recklessstepsvalue = 0;
			
			-- attempt to get the current career
			local careernode = nil;
			local careersnode = sourcenode.getChild("....careers");
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
			local stanceconsvervativenode = sourcenode.getChild("....stance.conservative");
			if stanceconsvervativenode then
				conservativestepsvalue = conservativestepsvalue + stanceconsvervativenode.getValue();
			end
			local stancerecklessnode = sourcenode.getChild("....stance.reckless");
			if stancerecklessnode then
				recklessstepsvalue = recklessstepsvalue + stancerecklessnode.getValue();
			end
			
			-- choose the default stance based on which is greatest
			if conservativestepsvalue > recklessstepsvalue then
				setValue(conservativerechargevalue);
				return true;
			end
			if recklessstepsvalue > conservativestepsvalue then
				setValue(recklessrechargevalue);
				return true;
			end
			
			-- if we have got this far then the character is in neutral stance
			-- and they have equal conservative and reckless stance steps
			-- normally, then player would define their default stance
			-- but for now, we choose a default of conservative
			-- which matches the default for the dice pool builder
			setValue(conservativerechargevalue);
			
		end
	end
end