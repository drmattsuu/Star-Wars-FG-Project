local control = nil;

function onInit()
	Debug.console("dieboxviewslot.lua: onInit()");
	control = self;
end

function setIdentityName(name)
	dieboxviewslotname.setValue(name);
	Debug.console("dieboxviewslot.lua - identity name: " .. name);
	if User.getIdentityLabel(name) == "" or name == "GM" or User.getIdentityLabel(User.getCurrentIdentity(name)) == nil or User.getIdentityLabel(User.getCurrentIdentity(name)) == User.getIdentityLabel(User.getCurrentIdentity()) then
		Debug.console("dieboxviewslot.lua - setting dieboxviewplayername to identity name: " .. name);
		dieboxviewplayername.setValue(name);
	else
		Debug.console("dieboxviewslot.lua - setting dieboxviewplayername to identity label: " .. User.getIdentityLabel(User.getCurrentIdentity(name)) .. ", based off identity name = " .. name);
		dieboxviewplayername.setValue(User.getIdentityLabel(User.getCurrentIdentity(name)));
	end
end

function getIdentityName()
	return dieboxviewslotname.getValue();
end