-- Provide slash handler functionality to set the TV size (horizontal dimension in inches)
-- Note: assumes 16:9 TV format.

function onInit()
	Debug.console("Registring tvsize slash handler");
	Comm.registerSlashHandler("tvsize", processTVSize);
end

function processTVSize(command, parameters)
	if User.isHost() then
		local tvSize, tvResolution = string.match(parameters, "(%d+)%s+(%d+)");

		--Debug.console("Processing TV size.  Command = " .. command .. ", Parameters = " .. parameters .. ", tvSize variable = " .. tvSize);
		
		if not tvSize and not tvResolution then
			-- Return the currently set size
			local tvSizeDBNode = DB.findNode("extension_data.tvsize");
			if tvSizeDBNode then
				local setTVResolution = 0;
				local setTVSize = tvSizeDBNode.getValue();
				local tvResolutionDBNode = DB.findNode("extension_data.tvresolution");
				if tvResolutionDBNode then
					setTVResolution = tvResolutionDBNode.getValue();
				end
				local msg = {};
				msg.font = "systemfont";
				msg.text = "TV size currently set to " .. setTVSize .. " inches, resolution = " .. setTVResolution;
				Comm.addChatMessage(msg);
				return;	
			else
				return;
			end
		end		

		Debug.console("Processing TV size.  Command = " .. command .. ", Parameters = " .. parameters .. ", tvSize variable = " .. tvSize .. ", Resolution = " .. tvResolution);		
		-- Create campaign database node used to store TV size database
		local extensionDBNode = DB.createNode("extension_data");
		extensionDBNode.setPublic(true);
		if extensionDBNode then
			local tvSizeDBNode = extensionDBNode.createChild("tvsize", "number");
			if tvSizeDBNode then
				tvSizeDBNode.setValue(tvSize);
			end
			local tvResolutionDBNode = extensionDBNode.createChild("tvresolution", "number");
			if tvResolutionDBNode then
				tvResolutionDBNode.setValue(tvResolution);
			end	
			local msg = {};
			msg.font = "systemfont";
			msg.text = "TV size set to " .. tvSize .. " inches, " .. tvResolution .. " resolution";
			Comm.addChatMessage(msg);
		end
	else
		return;
	end
end