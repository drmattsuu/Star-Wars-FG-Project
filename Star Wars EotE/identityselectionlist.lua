function clearSelection()
	for k, w in ipairs(getWindows()) do
		w.base.setFrame(nil);
	end
end

function addIdentity(id, label, localdatabasenode)

	--Debug.console("identityselectionlist.lua - addIdentity - id = " .. id .. ", label = " .. label);

	for k, v in ipairs(activeidentities) do
		if v == id then
			return;
		end
	end

	win = createWindow();
	win.setId(id);
	win.label.setValue(label);

	win.setLocalNode(localdatabasenode);

	if id then
		win.portrait.setIcon("portrait_" .. id .. "_charlist");
	end
end

function onInit()
	activeidentities = User.getAllActiveIdentities();

	getWindows()[1].close();
	createWindowWithClass("identityselection_newentry");

	localIdentities = User.getLocalIdentities();
	for n, v in ipairs(localIdentities) do
		local localnode = v.databasenode;
		local labelnode = v.databasenode.createChild("name", "string");
		addIdentity(v.id, labelnode.getValue(), localnode);
	end

	User.getRemoteIdentities("charsheet", "name", addIdentity);
end

