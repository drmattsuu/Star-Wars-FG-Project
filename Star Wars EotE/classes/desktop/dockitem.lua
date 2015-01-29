local classnamevalue = nil;
local recordnamevalue = nil;

function setValue(classname, recordname)
	classnamevalue = classname;
	recordnamevalue = recordname;
end

function onButtonPress()
	DesktopManager.openDesktopWindow(classnamevalue, recordnamevalue);
end

