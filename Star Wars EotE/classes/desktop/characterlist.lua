function findControlForIdentity(identity)
	return self["ctrl_" .. identity];
end

function controlSortCmp(t1, t2)
	return t1.name < t2.name;
end

function layoutControls()
	local identitylist = {};
	
	-- build the character list
	for key, val in pairs(User.getAllActiveIdentities()) do
		Debug.console("layoutControls - identity = " .. val);
		table.insert(identitylist, { name = val, control = findControlForIdentity(val) });
	end
	
	-- sort the identities	
	table.sort(identitylist, controlSortCmp);

	-- layout the identities
	local xpos = 13;
	for key, val in pairs(identitylist) do
		val.control.setStaticBounds(xpos, 0, 66, 96);
		xpos = xpos + 79;
	end
end

function onLogin(username, activated)

end

function onUserStateChange(username, statename, state)
	if username ~= "" and User.getCurrentIdentity(username) then
		local ctrl = findControlForIdentity(User.getCurrentIdentity(username));
		if ctrl then
			ctrl.stateChange(statename, state);
		end
	end
end

function onIdentityActivation(identity, username, activated)
	if activated then
		do
			if not findControlForIdentity(identity) then
				createControl("characterlistentry", "ctrl_" .. identity);
				
				userctrl = findControlForIdentity(identity);
				userctrl.createWidgets(identity);
				
				layoutControls();
			end
		end
	else
		Debug.console("onIdentityActivation - identity being destroyed = " .. identity);
		findControlForIdentity(identity).destroy();
		layoutControls();
	end
end

function onIdentityStateChange(identity, username, statename, state)
	local ctrl = findControlForIdentity(identity);
	if ctrl then
		ctrl.stateChange(statename, state);
	end
end

function onInit()
	User.onLogin = onLogin;
	User.onUserStateChange = onUserStateChange;
	User.onIdentityActivation = onIdentityActivation;
	User.onIdentityStateChange = onIdentityStateChange;
end
