control = nil;

function registerControl(ctrl)
	control = ctrl;
end

function addSkillDice(skilldescription, dice, sourcenode)
	if dice then
		if PreferenceManager.getValue("interface_cleardicepoolondrag") then
			control.resetAll();	
		end				
		control.setType("skill");
		control.setDescription(skilldescription);
		control.setSourcenode(sourcenode);
		for k, v in pairs(dice) do
			control.addDie(v);
		end
	end
end