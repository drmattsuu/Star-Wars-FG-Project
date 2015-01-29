local dragging = false;

function onInit()
	--if User.isHost() then --make this usable by everyone, not just host.

		-- set the mouse to a hand when over this control
		setHoverCursor("hand");
		
		-- register menu items
		registerMenuItem("End of Turn Actions", "deletetoken", 4);
	--end
end

function onButtonPress()
	PartySheetManager.openPartySheet();
end				

function onDrop(x, y, draginfo)
	PartySheetManager.onDrop(x, y, draginfo);
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if User.isHost() then
		if not dragging then
			draginfo.setType("partyidentity");
			draginfo.setTokenData("ruleset/tokens/party.png");
			draginfo.setShortcutData("partysheet", "partysheet");
			draginfo.setDatabaseNode("partysheet");
			draginfo.setStringData(PartySheetManager.getPartySheetName());

			local base = draginfo.createBaseData();
			base.setType("token");
			base.setTokenData("ruleset/tokens/party.png");
			
			dragging = true;

			return true;
		end
	end	
end

function onDragEnd(draginfo)
	dragging = false;
end

function onMenuSelection(selection)
	if User.isHost() then
		if selection == 4 then
			PartySheetManager.endOfTurn();
		end
	end
end