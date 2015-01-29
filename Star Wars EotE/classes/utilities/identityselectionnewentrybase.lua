function onDoubleClick(x, y)
	if not User.isLocal() then
		if not bRequested then
			User.requestIdentity(nil, "charsheet", "name", nil, window.requestResponse);
			bRequested = true;
		end	
		--User.requestIdentity(nil, "charsheet", "name", nil, window.requestResponse);
	else
		local identity = User.createLocalIdentity();
		Interface.openWindow("charsheet", identity);
		window.windowlist.window.close();
	end
	return true;
end

function onClickDown(button, x, y)
	window.windowlist.clearSelection();
	setFrame("sheetfocus", -2, -2, -1, -1);
	return true;
end
