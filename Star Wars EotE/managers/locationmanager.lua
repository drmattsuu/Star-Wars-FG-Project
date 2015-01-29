function onInit()
	if User.isHost() then
	
		-- subscribe to user login events
		User.onLogin = onLogin;
		
		-- subscribe to module changes
		Module.onModuleAdded = onModuleAdded;
		Module.onModuleUpdated = onModuleUpdated;		
		
	end
end

function onLogin(username, activated)
	if User.isHost() then
		if activated then
		
			-- add the user as a holder of the campaign locations
			DB.createNode("locations").addHolder(username, true);
			
			-- add the user as a holder of any module locations
			local modules = Module.getModules();
			for k, v in ipairs(modules) do
				local modulenode = DB.findNode("locations@" .. v)
				if modulenode then
					modulenode.addHolder(username, true);
				end
			end			
			
		end
	end
end

function onModuleAdded(name)
	if User.isHost() then
		local modulenode = DB.findNode("locations@" .. name);
		if modulenode then
			for k, v in ipairs(UserManager.getCurrentUsers()) do
				modulenode.addHolder(v);
			end			
		end	
	end
end

function onModuleUpdated(name)
	onModuleAdded(name);
end

function openLocation(locationnode)
	local locationwindowreference = Interface.findWindow("location", locationnode.getNodeName());
	if not locationwindowreference then
		Interface.openWindow("location", locationnode);
	else
		locationwindowreference.close();
	end
end