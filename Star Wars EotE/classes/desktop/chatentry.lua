function onDeliverMessage(messagedata, mode)
	if User.isHost() then
		gmid, isgm = GmIdentityManager.getCurrent();

		if messagedata.hasdice then
			messagedata.sender = gmid;
			messagedata.font = "systemfont";
		elseif mode == "chat" then
			messagedata.sender = gmid;
			
			if isgm then
				messagedata.font = "gmfont";
			else
				messagedata.font = "npcchatfont";
			end
		elseif mode == "story" then
			messagedata.sender = "";
			messagedata.font = "narratorfont";
		elseif mode == "emote" then
			messagedata.text = gmid .. " " .. messagedata.text;
			messagedata.sender = "";
			messagedata.font = "emotefont";
		end
	end
	
	return messagedata;
end

function onTab()
	ChatManager.doAutocomplete();
end

function onInit()
	ChatManager.registerEntryControl(self);
end
