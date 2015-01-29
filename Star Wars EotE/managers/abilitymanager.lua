function onDrop(abilitynode, x, y, draginfo)

	-- Chits
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "recharge" then
			return addRecharge(abilitynode);
		end		
	end
end

function addRecharge(abilitynode)
	if abilitynode.isOwner() then
		local socketednode = abilitynode.getChild("socketed");
		if socketednode and socketednode.getValue() ~= 0 then
		
			-- attempt to get the parent character slots node
			local characterslotsnode = abilitynode.getParent().getParent().getChild("slots");
			if characterslotsnode then
				for k, v in pairs(characterslotsnode.getChildren()) do
					local recordnamenode = v.getChild("recordname");
					if recordnamenode then
						local recordname = recordnamenode.getValue();
						if recordname == abilitynode.getNodeName() then
							local rechargenode = v.createChild("currentrecharge", "number");
							if rechargenode and rechargenode.isOwner() then
								rechargenode.setValue(rechargenode.getValue() + 1);
								return true;
							end
						end
					end
				end		
			end
			
			-- if we got this far, then the ability must be socketed to the party sheet
			local partyslotsnode = DB.findNode("partysheet.slots");
			if partyslotsnode then
				for k, v in pairs(partyslotsnode.getChildren()) do
					local recordnamenode = v.getChild("recordname");
					if recordnamenode then
						local recordname = recordnamenode.getValue();
						if recordname == abilitynode.getNodeName() then
							local rechargenode = v.createChild("currentrecharge", "number");
							if rechargenode and rechargenode.isOwner() then
								rechargenode.setValue(rechargenode.getValue() + 1);
								return true;
							end
						end
					end
				end	
			end
			
		end
	end
end
