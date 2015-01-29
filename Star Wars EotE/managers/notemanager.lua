function onInit()
	if User.isHost() then
		User.onLogin = onLogin;
	end
end

function onLogin(username, activated)
	if activated then
		local node = DB.createNode("notes." .. UserManager.getUserCode(username));
		node.addHolder(username, true);
	end
end
