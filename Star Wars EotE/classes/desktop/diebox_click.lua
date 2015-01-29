control = nil;

function registerControl(ctrl)
	control = ctrl;
end

function addSkillDice(skilldescription, dice, sourcenode)
	if dice then
		control.resetAll();			
		control.setType("skill");
		control.setDescription(skilldescription);
		control.setSourcenode(sourcenode);
		for k, v in pairs(dice) do
			control.addDie(v);
		end
	end
end