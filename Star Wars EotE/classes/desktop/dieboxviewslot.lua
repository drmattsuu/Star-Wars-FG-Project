local control = nil;

function onInit()
	Debug.console("dieboxviewslot.lua: onInit()");
	control = self;
end

function setIdentityName(name)
	dieboxviewslotname.setValue(name);
end

function getIdentityName()
	return dieboxviewslotname.getValue();
end