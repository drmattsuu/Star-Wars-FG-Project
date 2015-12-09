function updateSkills(npcNode)

	--Debug.console("Running MinionManager.updateSkills.  Node = " .. npcNode.getNodeName());
	
	if User.isHost() then
	
		local minionsRemaining = npcNode.getValue();
		
		local skillsNode = npcNode.getChild("...skills");
		if skillsNode then
			local aSkills = skillsNode.getChildren();

			for k,v in pairs(aSkills) do
				if v.getChild(".skillcheck").getValue() == 1 then
					v.getChild(".advances").setValue(minionsRemaining - 1);
				end
			end
		end
	
	end

end

function updateSkill(skillNode)

	--Debug.console("Running MinionManager.updateSkills.  Node = " .. skillNode.getNodeName());
	if skillNode then
		if skillNode.getChild(".skillcheck").getValue() == 1 then
			local minionsRemaining = skillNode.getChild("...minion.minions_remaining").getValue();
			skillNode.getChild(".advances").setValue(minionsRemaining - 1);
		else
			skillNode.getChild(".advances").setValue(0);
		end
	end
	
--	local skillsNode = npcNode.getChild("...skills");
--	if skillsNode then
--		local aSkills = skillsNode.getChildren();

		--for k,v in pairs(aSkills) do
			--if v.getChild(".skillcheck").getValue() == 1 then
				--v.getChild(".advances").setValue(minionsRemaining - 1);
			--end
		--end
	--end

end