function onInit()
	if User.isHost() then
		registerMenuItem("Clear slot", "erase", 4);	
	end
end

function onMenuSelection(...)
	NpcGroupManager.removeAbility(getDatabaseNode().getParent());
end

function onDrop(x, y, draginfo)
	if User.isHost() then

		-- Shortcuts
		if draginfo.isType("shortcut") then
			local class, recordname = draginfo.getShortcutData();
			
			-- Faith
			if class == "faith" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end
			
			-- Faith
			if class == "focus" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end
			
			-- Invention
			if class == "invention" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end		
			
			-- Oath
			if class == "oath" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end		
			
			-- Order
			if class == "order" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end		
			
			-- Reputation
			if class == "reputation" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end		
			
			-- Tactic
			if class == "tactic" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end
			
			-- Talent
			if class == "talent" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end			
			
			-- Trick
			if class == "trick" then
				local recordnode = DB.findNode(recordname);
				if recordnode then
					return NpcGroupManager.addAbility(getDatabaseNode().getParent(), recordnode);
				end
			end
		end
	end
end