function onDrop(conditionnode, x, y, draginfo)

	-- Chits
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "recharge" then
			return addRecharge(conditionnode);
		end		
	end
end

function addRecharge(conditionnode)
	if conditionnode.isOwner() then
	
		-- get the current recharge node
		local rechargenode = conditionnode.getChild("currentrecharge", "number");
		if rechargenode then
		
			-- increase the recharge value
			rechargenode.setValue(rechargenode.getValue() + 1);
			
			-- and return
			return true;
		end
	end
end
