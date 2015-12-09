-- MOD: Trenloe November 2013.  Added onLogin handler.

local dragging = false;

local removingchit = "false";  --Flag used to stop removelightsidechit from occurring twice.

local lightsidechitwindow = nil;
local darksidechitwindow = nil;

SPECIAL_MSGTYPE_REFRESHDESTINYCHITS = "refreshdestinychits";
SPECIAL_MSGTYPE_REMOVELIGHTSIDECHIT = "removelightsidechit";

function onInit()
	setHoverCursor("hand");
	
	if chit then
		setIcon(chit[1] .. "chit");
	end
	
	if window.getClass() == "lightsidechit" or window.getClass() == "darksidechit" then
		if User.isHost() then	
			-- subscribe to the login events so that client side chits can be updated when the player logs in.
			User.onLogin = onLogin;	
			-- set up the right-click chit menus - GM only
			registerMenuItem("Clear Pile", "deletealltokens", 1);
			registerMenuItem("Update Player Chits", "broadcast", 7);		
		end
		
		-- Register lightsidechit window instance for use later in GM forced update.
		if window.getClass() == "lightsidechit" then	
			lightsidechitwindow = window;
		end
		
		-- Register darksidechit window instance for use later in GM forced update.
		if window.getClass() == "darksidechit" then	
			darksidechitwindow = window;
		end	
		
		-- register special messages
		ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_REFRESHDESTINYCHITS, handleRefreshdestinyChits);	
		ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_REMOVELIGHTSIDECHIT, handleRemoveLightsideChits);
		
		if User.isHost() then
			if chit then			
				--Set the destiny chits to the current value in the database
				refreshDestinyChits();
			end
		end	
	end
	
	if window.getClass() == "woundchit" then
		registerMenuItem("Reset to 1", "erase", 1);
		registerMenuItem("Assign 2 chits", "num2", 2);
	end
end

function refreshDestinyChits()
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_REFRESHDESTINYCHITS, {});
end

function handleRefreshdestinyChits(msguser, msgidentity, msgparams)
	local lightsidenode = nil;
	local darksidenode = nil;
	
	Debug.console("chit.lua: handleRefreshdestinyChits()  window.getClass() = " .. window.getClass());

	if window.getClass() == "lightsidechit" then
		-- ensure that we have the light side chit node - create it if it does not exist (e.g. for a new campaign)
		if User.isHost() then
			-- If we are the GM this may be a new campaign, need to create the node if not already there.
			if not lightsidenode then
				lightsidenode = DB.createNode("lightsidechit.chits","number");
			end		
		end
		
		-- If we don't have the lightsidechit node at this point, find it.
		if not lightsidenode then
			lightsidenode = DB.findNode("lightsidechit.chits");
		end
		
		--Debug.console("chit.lua: handleRefreshdestinyChits() lightsidenode.getValue = " .. lightsidenode.getValue());
		
		if lightsidenode then		
			-- refresh chits here
			if lightsidenode.getValue()<=0 then
				setIcon("lightsidechit0");
			elseif lightsidenode.getValue()<8 then
				setIcon("lightsidechit" .. lightsidenode.getValue());
			else
				setIcon("lightsidechit8more");
			end
		end		
	end
	
	if window.getClass() == "darksidechit" then
		-- ensure that we have the light side chit node, create it if it does not exist (e.g. for a new campaign)
		if not darksidenode then
			darksidenode = DB.createNode("darksidechit.chits","number");
		end
		-- refresh chits here
		if darksidenode then		
			if darksidenode.getValue()<=0 then
				setIcon("darksidechit0");
			elseif darksidenode.getValue()<8 then
				setIcon("darksidechit" .. darksidenode.getValue());
			else
				setIcon("darksidechit8more");
			end
		end
	end	
end

function removeLightsideChits()
	local msgparams = {};
	msgparams[1] = "true";		--Used as the removingchit flag to ensure that the OOB process only fires once on the GM side.	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_REMOVELIGHTSIDECHIT, msgparams);
end

function handleRemoveLightsideChits(msguser, msgidentity, msgparams)
	-- Can onlt adjust the database as the host
	removingchit = msgparams[1];
	if User.isHost() and  removingchit == "true" then
		local msg = {};
		msg.font = "msgfont";	
		
		-- create  new lightside force node, or find it if it already exists
		lightsidenode = DB.createNode("lightsidechit.chits", "number");
		if lightsidenode then
			-- Only remove a chit if there are actually any there to remove
			if lightsidenode.getValue() > 0 then
				-- decrease the lightside count
				lightsidenode.setValue(lightsidenode.getValue() - 1);
				--Debug.console("Lightside use.");
				--msg.text = "Lightside destiny has been decremented to " ..  lightsidenode.getValue();
				if msgidentity == "" then
					msg.text = "A lightside destiny chit has been used by  " .. msguser;
				elseif msgidentity == "GM" then
					msg.text = "A lightside destiny chit has been played by the GM on behalf of the players.";
				else
					msg.text = "A lightside destiny chit has been used by  " .. msguser .. ", for character " .. msgidentity;
				end
				ChatManager.deliverMessage(msg);
				
				-- create new darkside force node, or find it if it already exists
				darksidenode = DB.createNode("darksidechit.chits", "number");
				if darksidenode then
					-- increase the darkside count
					darksidenode.setValue(darksidenode.getValue() + 1);
					--msg.text = "Darkside destiny has been incremented to " ..  darksidenode.getValue();
					--ChatManager.deliverMessage(msg);	
				end
				-- Reset flag to stop further processing of this function until another drag event occurs.
				removingchit = "false";
				msgparams[1] = "false";  --Needed to reset removing chit properly when this function fires again.
				-- Refresh the chits.
				refreshDestinyChits();	
			end
		end
	end
end

function onLogin(username, activated)
	if User.isHost() and activated then
		--Add the player as a holder to the destiny chits nodes - this is needed to avoid an error accessing the nodes when a user connects to a campaign DB for the first time.
		--local lightsidenode = DB.findNode("lightsidechit");		
		--if not lightsidenode then
		--	lightsidenode.addHolder(username);
		--end

		--local darksidenode = DB.findNode("darksidechit");
		--if not darksidenode then
			--darksidenode.addHolder(username);	
		--end
		
		--Refresh the client side chit icons
		refreshDestinyChits();
	end
end

function onMenuSelection(selection)
	if chit then
		if window.getClass() == "lightsidechit" or window.getClass() == "darksidechit" then
			if selection == 1 then
				-- Reset both chit piles to 0
				local msg = {};
				msg.font = "msgfont";	
					
				if window.getClass() == "lightsidechit" then									
					-- create new lightside force node, or find it if it already exists
					lightsidenode = DB.createNode("lightsidechit.chits", "number");
					if lightsidenode then
						-- remove all the lightside 
						lightsidenode.setValue(0);
						msg.text = "Lightside destiny has been decremented to " ..  lightsidenode.getValue();
						ChatManager.deliverMessage(msg);
						refreshDestinyChits();								
					end
				end
				
				if window.getClass() == "darksidechit" then
					darksidenode = DB.createNode("darksidechit.chits", "number");
					if darksidenode then
						-- remove all the darkside 
						darksidenode.setValue(0);
						msg.text = "Darkside destiny has been decremented to " ..  darksidenode.getValue();
						ChatManager.deliverMessage(msg);				
						refreshDestinyChits();				
					end
				end		
			elseif selection == 7 then
				-- Synchronise the chit piles with the connected players - added for the rare occasion where the client does not synch properly on login
				refreshDestinyChits();
			end			
		end
		
		if window.getClass() == "woundchit" then
			if selection == 1 then
			
			elseif selection == 2 then
			
			end
		end
	end
end

function onDragStart(button, x, y, draginfo)
	if window.getClass() == "lightsidechit" or window.getClass() == "darksidechit" then
		-- Allow all users to drag lightside destiny chits
		if window.getClass() == "lightsidechit" then	
			dragging = false;
			return onDrag(button, x, y, draginfo);
			
		--Allow GM to drag both lightside and darkside
		elseif User.isHost() then
			dragging = false;
			return onDrag(button, x, y, draginfo);		
		end
	else
		dragging = false;
		return onDrag(button, x, y, draginfo);
	end
end

function onDrag(button, x, y, draginfo)
	if chit and not dragging then
		draginfo.setType("chit");
		draginfo.setDescription(chit[1]);
		draginfo.setIcon(chit[1] .. "chit");
		draginfo.setCustomData(chit[1]);
		dragging = true;
		return true;
	end
end

function onDragEnd(draginfo)
	dragging = false;
	if chit then		
		local msg = {};
		msg.font = "msgfont";										
		
		if window.getClass() == "lightsidechit" then
			removeLightsideChits();
		end
		
		if window.getClass() == "darksidechit" then
			darksidenode = DB.createNode("darksidechit.chits", "number");
			if darksidenode then
				-- Only remove a chit if there are actually any there to remove
				if darksidenode.getValue() > 0 then
					-- decrease the darkside count
					darksidenode.setValue(darksidenode.getValue() - 1);
					--msg.text = "Darkside destiny has been decremented to " ..  darksidenode.getValue();
					msg.text = "A darkside destiny chit has been used by the GM";
					ChatManager.deliverMessage(msg);
					-- create  new lightside force node, or find it if it already exists
					lightsidenode = DB.createNode("lightsidechit.chits", "number");
					if lightsidenode then
						-- increase the lightside count
						lightsidenode.setValue(lightsidenode.getValue() + 1);
						--msg.text = "Lightside destiny has been incremented to " ..  lightsidenode.getValue();
						--ChatManager.deliverMessage(msg);
					end
					refreshDestinyChits();
				end
			end
		end
	end
end

function onDoubleClick(x, y)
	--Only process if the user is the GM
	if chit and User.isHost() then		
		local msg = {};
		msg.font = "msgfont";										
		
		if window.getClass() == "lightsidechit" then
			-- create  new lightside force node, or find it if it already exists
			lightsidenode = DB.findNode("lightsidechit.chits", "number");
			if not lightsidenode then
				lightsidenode = DB.createNode("lightsidechit.chits", "number");
			end
			if lightsidenode then
				-- increase the lightside count
				lightsidenode.setValue(lightsidenode.getValue() + 1);
				--msg.text = "Lightside destiny has been increased to " ..  lightsidenode.getValue();
				--ChatManager.deliverMessage(msg);				
			end	
			-- Initiate special message functionality to refresh chits on clients.
			refreshDestinyChits();
		end	
		
		if window.getClass() == "darksidechit" then
			-- create  new darkside force node, or find it if it already exists
			lightsidenode = DB.createNode("lightsidechit.chits", "number");
			darksidenode = DB.createNode("darksidechit.chits", "number");
			if darksidenode then
				-- increase the darkside count
				darksidenode.setValue(darksidenode.getValue() + 1);
				--msg.text = "Darkside destiny has been increased to " ..  darksidenode.getValue();			
				--ChatManager.deliverMessage(msg);				
			end	
			-- Initiate special message functionality to refresh chits on clients.				
			refreshDestinyChits();
		end		
		
		return true;
	end
end