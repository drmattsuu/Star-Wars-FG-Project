function onDrop(actionnode, x, y, draginfo)

	-- Chits
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "recharge" then
			return addRecharge(actionnode);
		end		
	end
end

function addRecharge(actionnode)
	if actionnode.isOwner() and not actionnode.isStatic() then
	
		-- get the current recharge node
		local rechargenode = actionnode.createChild("currentrecharge", "number");
		if rechargenode then
		
			-- increase the recharge value
			rechargenode.setValue(rechargenode.getValue() + 1);
			
			-- and return
			return true;
		end
	end
end
