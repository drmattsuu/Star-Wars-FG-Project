local currentusers = {};

function onInit()
	if User.isHost() or User.isLocal() then
		User.onLogin = onLogin;
	end
end

function onLogin(username, activated)
	if User.isHost() or User.isLocal() and activated then
		table.insert(currentusers, username);
	end
end

function getCurrentUsers()
	return currentusers;
end

function getUserCode(username)
	return string.gsub(username, "([^/A-Za-z0-9_])" , "_");
end