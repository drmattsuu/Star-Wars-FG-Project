function onPreferenceChanged(valuename, value)
	if isAllowed() then
		setVisible(value);
	else
		setVisible(false);
	end
end

function onInit()
	PreferenceManager.registerValueObserver("interface_closebutton", onPreferenceChanged);
	if isAllowed() then
		setVisible(PreferenceManager.getValue("interface_closebutton"));
	else
		setVisible(false);
	end
end

function onClose()
	PreferenceManager.unregisterValueObserver("interface_closebutton", onPreferenceChanged);
end

function onButtonPress()
	if isAllowed() then
		window.close();
	end
end

function isAllowed()
	if User.isHost() or not window.isShared() or window.playercontrol then
		return true;
	end

	return false;
end
