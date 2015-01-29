SPECIAL_MSGTYPE_ADDTOKEN = "addtoken";

function onInit()

	-- if the user is the host
	if User.isHost() then
	
		-- create the token node
		local tokensnode = DB.createNode("tokens");
		
		-- clean the current tokens
		cleanTokens();		
		
		-- subscrive to the user login event
		--User.onLogin = onLogin;
	end

	-- register special messages
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_ADDTOKEN, handleAddToken);
		
end

function onLogin(username, activated)
	if User.isHost() and activated then
		DB.findNode("tokens").addHolder(username);	
	end
end

function cleanTokens(containernode, tokens)
	if User.isHost() then
		local tokensnode = DB.findNode("tokens");
		for k1, v1 in pairs(tokensnode.getChildren()) do
			local currentcontainernode = DB.findNode(v1.getChild("container").getValue());
			if currentcontainernode then
				if containernode and containernode.getNodeName() == currentcontainernode.getNodeName() and tokens then
					local exists = false;
					for k2, v2 in ipairs(tokens) do
						if v2.getId() == v1.getChild("id").getValue() then
							exists = true;
						end
					end
					if not exists then
						v1.delete();
					end
				end
			else
				v1.delete();
			end
		end
	end
end

function addToken(token, classname, recordname)
	return ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_ADDTOKEN, {token.getContainerNode().getNodeName(), token.getId(), classname, recordname});
end

function handleAddToken(msguser, msgidentity, msgparams)
	if User.isHost() then
	
		-- get the tokens node
		local tokensnode = DB.findNode("tokens");
	
		-- get the message parameters
		local containername = msgparams[1];
		local tokenid = tonumber(msgparams[2]);
		local classname = msgparams[3];
		local recordname = msgparams[4];
		
		-- determine if node already exists for this token
		local tokennode = nil;
		for k, v in pairs(tokensnode.getChildren()) do
			if v.getChild("container").getValue() == containername and v.getChild("id").getValue == tokenid then
				tokennode = v;
			end
		end
		
		-- create the token node if required
		if not tokennode then
			tokennode = tokensnode.createChild();
			tokennode.createChild("container", "string").setValue(containername);
			tokennode.createChild("id", "number").setValue(tokenid);
		end
		
		-- update the token details
		tokennode.createChild("classname", "string").setValue(classname);
		tokennode.createChild("recordname", "string").setValue(recordname);	
		
		-- make the token targetable
		local containernode = DB.findNode(containername);
		if containernode then
			local windownode = containernode.getParent();
			if windownode then
				local imagewindow = Interface.findWindow("image", windownode);
				if imagewindow then
					local tokens = imagewindow.image.getTokens();
					if tokens then
						for k, v in pairs(tokens) do					
							if v.getId() == tokenid then
								if not v.isTargetable() then
									v.setTargetable(true);
								end
							end
						end
					end
					local viewers = imagewindow.getViewers();
					if viewers then
						for k, v in pairs(viewers) do
							imagewindow.share(v);
						end
					end
				end
			end
		end

	end
	return true;
end

function getTokenNode(token)
	local tokensnode = DB.findNode("tokens");
	for k, v in pairs(tokensnode.getChildren()) do
		local container = v.getChild("container").getValue();
		local id = v.getChild("id").getValue();
		if token.getContainerNode().getNodeName() == container and token.getId() == id then
			return v;
		end
	end
end

function openTokenSheet(token)
	local tokennode = getTokenNode(token);
	if tokennode then
		local classname = tokennode.getChild("classname").getValue();
		local recordnode = DB.findNode(tokennode.getChild("recordname").getValue());
		if recordnode then
			if classname == "charsheet" then
				CharacterManager.openCharacterSheet(recordnode);
			elseif classname == "npc" then
				NpcManager.openNpcSheet(recordnode);
			elseif classname == "partysheet" then
				PartySheetManager.openPartySheet();
			elseif classname == "location" then
				LocationManager.openLocation(recordnode);
			elseif classname == "pet" then
				PetManager.openPetSheet(recordnode);
			elseif classname == "horse" then
				HorseManager.openHorseSheet(recordnode);
			elseif classname == "retainer" then
				RetainerManager.openRetainerSheet(recordnode);
			end
		end
		return true;
	end
end

function onDrop(token, draginfo)
	local tokennode = getTokenNode(token);
	Debug.console("tokenmanager.lua: on Drop.  Drop type = " .. draginfo.getType());
	if tokennode then
		local classname = tokennode.getChild("classname").getValue();
		local recordnode = DB.findNode(tokennode.getChild("recordname").getValue());
		--Debug.console("tokenmanager.lua: on Drop.  classname = " .. classname);
		if recordnode then
			if classname == "charsheet" then
				return CharacterManager.onDrop(recordnode, 0, 0, draginfo);
			elseif classname == "npc" then
				return NpcManager.onDrop(recordnode, 0, 0, draginfo);
			elseif classname == "partysheet" then
				return PartySheetManager.onDrop(0, 0, draginfo);
			end
		end
	end
end

function onWheel(token, notches)
	if Input.isControlPressed() then
		if not token then
			return ;
		end
		local scale = token.getScale();
		if Input.isShiftPressed() then
			scale = math.floor(scale + notches);
			if scale < 1 then
				scale = 1;
			end
		else
			scale = scale + (notches * 0.1);
			if scale < 0.1 then
				scale = 0.1;
			end
		end	
		token.setScale(scale);		
		return true;
	end
end

function targetToken(token)
	if not User.isHost() and User.getCurrentIdentity() then
		token.setTarget(not token.isTargetedByIdentity());
	end
	return true;
end