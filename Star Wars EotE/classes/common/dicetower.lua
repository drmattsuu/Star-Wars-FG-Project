local SPECIAL_MSGTYPE_DICETOWER = "dicetower";
local iconname = nil;

function onInit()
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_DICETOWER, processDiceTowerMessage);
	PreferenceManager.registerValueObserver("interface_showdicetower", onPreferenceChanged);
	setVisible(PreferenceManager.getValue("interface_showdicetower"));
end

function onClose()
	ChatManager.unregisterSpecialMessageHandler(SPECIAL_MSGTYPE_DICETOWER, processDiceTowerMessage);
	PreferenceManager.unregisterValueObserver("interface_showdicetower", onPreferenceChanged);
end

function onHover(state)
	if state then
		if iconhover then
			setIcon(iconhover[1]);
		end
	else
		if icon then
			setIcon(icon[1]);
		end
	end
end

function onPreferenceChanged(name, value)
	if name == "interface_showdicetower" then
		setVisible(value);
	end
end

function onDrop(x, y, draginfo)
	local dice = draginfo.getDieList();
	if dice then
	
		-- apply the modifier to the roll
		ModifierStack.applyModifierStackToRoll(draginfo);
	
		-- build a special message to send to the host
		local msgparams = {};
		msgparams[1] = draginfo.getType();
		msgparams[2] = draginfo.getDescription();
		msgparams[3] = draginfo.getNumberData();
		msgparams[4] = ""; -- sourcenode
		msgparams[5] = table.maxn(dice);
		
		-- source node name
		local sourcenode = draginfo.getDatabaseNode();
		if sourcenode then
			msgparams[4] = sourcenode.getNodeName();
		end
		
		-- dice
		for n = 1, msgparams[5] do
			msgparams[5 + n] = dice[n].type;
		end

		-- send the special message
		ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_DICETOWER, msgparams)
		
		-- and return
		return true;		
		
	end
end

function processDiceTowerMessage(msguser, msgidentity, msgparams)
	if User.isHost() then
	
		-- type
		local type = msgparams[1];
	
		-- description
		local description = msgparams[2];
	
		-- modifier
		local modifier = msgparams[3];
		
		-- source node name
		local sourcenodename = msgparams[4];
		
		-- gm only
		local gmonly = true;
		
		-- build the dice table
		local dice = {};
		for n = 1, msgparams[5] do
			table.insert(dice, msgparams[5 + n]);
		end
		
		-- verify the identity
		if msgidentity == "" then
			msgidentity = msguser;
		end
		
		-- throw the dice
		ChatManager.throwDice(type, dice, modifier, description, {sourcenodename, msgidentity, gmonly});
	
	end
end
