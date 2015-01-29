identities = {};
currentidentity = nil;

function registerIdentityList(list)
	-- Store a reference to the list window
	identitylist = list;
	
	local gmidname = CampaignRegistry.gmidentity or "GM";
	
	addIdentity(gmidname, true);
end

function setCurrent(name)
	if identitylist then
		identitylist.setCurrent(name);
	end
	
	currentidentity = name;
end

function getCurrent()
	if currentidentity then
		return currentidentity, identities[currentidentity];
	end

	return nil, nil;
end

function addIdentity(name, isgm)
	if not identities[name] and identitylist then
		identitylist.addIdentity(name, isgm);
	end
	
	identities[name] = isgm;

	setCurrent(name);
end

function removeIdentity(name)
	-- Preserve the first entry
	if identities[name] then
		return;
	end

	-- In case the identity being deleted is active, activate the root identity
	if currentidentity == name then
		setCurrent(next(identities));
	end

	-- Remove from list	
	if identitylist then
		identitylist.removeIdentity(name);
	end

	-- Remove from table
	identities[name] = nil;
end

function slashCommandHandlerId(command, params)
	addIdentity(params, false);
end

function setGmIdentity(newid)
	for k,v in pairs(identities) do
		if v then
			identities[k] = nil;
		end
	end

	identities[newid] = true;
	if identitylist then
		identitylist.renameGmIdentity(newid);
	end
	
	setCurrent(newid);

	CampaignRegistry.gmidentity = newid;
end

function slashCommandHandlerGmId(command, params)
	setGmIdentity(params);
end

function preferenceGmIdHandler(valuename, value)
	if valuename == "user_gmidentity" then
		setGmIdentity(value);
	end
end

function onInit()
	ChatManager.registerSlashHandler("identity", slashCommandHandlerId);
	ChatManager.registerSlashHandler("gmid", slashCommandHandlerGmId);
	PreferenceManager.registerValueObserver("user_gmidentity", preferenceGmIdHandler);
end

function onClose()
	PreferenceManager.unregisterValueObserver("user_gmidentity", preferenceGmIdHandler);
end
