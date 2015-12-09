SPECIAL_MSGTYPE_UPDATENONOWNEDDB = "updatenonowneddb";
SPECIAL_MSGTYPE_CREATENONOWNEDDB = "createnonowneddb";
SPECIAL_MSGTYPE_CREATECHILDNONOWNEDDB = "createchildnonowneddb";
SPECIAL_MSGTYPE_CRITICALNOWNEDDB = "createcriticalnonowneddb";


function onInit()
	-- Register special message handler to allow players to update database entries they normally can't update.
	-- i.e. Pass the request to the GM via special messages (OOB messages) and let the GM side do the update.
	
	-- Used to update already created fields.
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_UPDATENONOWNEDDB, handleUpdateNonOwnedDB);
	
	-- Used to create new fields.
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_CREATENONOWNEDDB, handleCreateNonOwnedDB);
	
	-- Used to create a new child record - only works if the child record is named.  Doesn't support id-XXXXX child records.
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_CREATECHILDNONOWNEDDB, handleCreateChildNonOwnedDB);
	
	-- Used to create a new critical inury record
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_CRITICALNOWNEDDB, handleCreateCriticalNonOwnedDB);	
end

function updateNonOwnedDB(nodeRecord, dbFieldName, value)
	-- Called when the player needs to update info in the database, but they don't own the record so FG blocks the change.
	-- Need to pass the info to the GM for the GM to update.
	Debug.console("PlayerDBManager: updateNonOwnedDB()");
	local msgparams = {};
	-- Only the GM can create the list of logged in users.
	msgparams[1] = nodeRecord.getNodeName();	
	msgparams[2] = dbFieldName;
	msgparams[3] = value;
	--msgparams[4] = User.getCurrentIdentity();
	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_UPDATENONOWNEDDB, msgparams);		
		
end

function handleUpdateNonOwnedDB(msguser, msgidentity, msgparams)
	Debug.console("PlayerDBManager: handleUpdateNonOwnedDB()");
	if User.isHost() then 
		local nodeRecordName = msgparams[1];
		local dbFieldName = msgparams[2];
		local value = msgparams[3];
		nodeRecord = DB.findNode(nodeRecordName);
		if nodeRecord then
			Debug.console("handleUpdateNonOwnedDB().  " .. nodeRecord.getNodeName() .. ", DB field = " .. dbFieldName .. ", value to set = " .. value);
			-- set the value
			nodeRecord.getChild(dbFieldName).setValue(value);
		end	
	end
end

function createNonOwnedDB(nodeRecord, dbFieldName, dbFieldType, value)
	-- Called when the player needs to create new fields in the database, but they don't own the record so FG blocks the change.
	-- Need to pass the info to the GM for the GM to update.
	Debug.console("PlayerDBManager: createNonOwnedDB()");
	local msgparams = {};
	-- Only the GM can create the list of logged in users.
	msgparams[1] = nodeRecord.getNodeName();	
	msgparams[2] = dbFieldName;
	msgparams[3] = dbFieldType;
	msgparams[4] = value;	
	--msgparams[4] = User.getCurrentIdentity();
	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_CREATENONOWNEDDB, msgparams);		
		
end

function handleCreateNonOwnedDB(msguser, msgidentity, msgparams)
	Debug.console("PlayerDBManager: handleCreateNonOwnedDB()");
	if User.isHost() then 
		local nodeRecordName = msgparams[1];
		local dbFieldName = msgparams[2];
		local dbFieldType = msgparams[3];		
		local value = msgparams[4];
		nodeRecord = DB.findNode(nodeRecordName);
		if nodeRecord then
			Debug.console("handleCreateNonOwnedDB().  " .. nodeRecord.getNodeName() .. ", DB field = " .. dbFieldName .. ", field type = " .. dbFieldType .. ", value to set = " .. value);
			-- set the value
			nodeRecord.createChild(dbFieldName, dbFieldType).setValue(value);
		end	
	end
end

function createChildNonOwnedDB(nodeRecord, dbChildName)
	-- Called when the player needs to create a new child record in the database, but they don't own the record so FG blocks the change.
	-- Need to pass the info to the GM for the GM to update.
	Debug.console("PlayerDBManager: createChildNonOwnedDB()");
	local msgparams = {};
	-- Only the GM can create the list of logged in users.
	msgparams[1] = nodeRecord.getNodeName();	
	msgparams[2] = dbChildName;
	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_CREATECHILDNONOWNEDDB, msgparams);		
		
end

function handleCreateChildNonOwnedDB(msguser, msgidentity, msgparams)
	Debug.console("PlayerDBManager: handleCreateChildNonOwnedDB()");
	if User.isHost() then 
		local nodeRecordName = msgparams[1];
		local dbChildName = msgparams[2];
		nodeRecord = DB.findNode(nodeRecordName);
		if nodeRecord then
			Debug.console("handleCreateChildNonOwnedDB().  " .. nodeRecord.getNodeName() .. ", DB child name = " .. dbChildName);
			if dbChildName == "" then
				-- create the child with an ID index (id-XXXXX).
				nodeRecord.createChild();
				-- NOTE: This won't work from a OOB messaging perspective - the player side won't know the name of the newly created id-XXXXX node.
			else
				-- create the child with a name
				nodeRecord.createChild(dbChildName);
			end
		end	
	end
end

function createCriticalNonOwnedDB(nodeRecord, name, description, severity)
	-- Called when the player needs to create a new child record in the database, but they don't own the record so FG blocks the change.
	-- Need to pass the info to the GM for the GM to update.
	Debug.console("PlayerDBManager: createCriticalNonOwnedDB()");
	local msgparams = {};
	-- Only the GM can create the list of logged in users.
	msgparams[1] = nodeRecord.getNodeName();	
	msgparams[2] = name;
	msgparams[3] = description;
	msgparams[4] = severity;	
	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_CRITICALNOWNEDDB, msgparams);		
		
end

function handleCreateCriticalNonOwnedDB(msguser, msgidentity, msgparams)
	Debug.console("PlayerDBManager: handleCreateCriticalNonOwnedDB()");
	if User.isHost() then 
		local nodeRecordName = msgparams[1];
		local name = msgparams[2];
		local description = msgparams[3];
		local severity = msgparams[4];
		nodeRecord = DB.findNode(nodeRecordName);
		if nodeRecord then
			Debug.console("handleCreateCriticalNonOwnedDB().  " .. nodeRecord.getNodeName() .. ", critical name = " .. name);
			-- get the criticals node
			if string.find(nodeRecord.getNodeName(), "vehicle") then
				-- We are adding a vehicle critical - handle slightly differently
				criticalsnode = nodeRecord.createChild("shipcriticals");				
			else
				criticalsnode = nodeRecord.createChild("criticals");			
			end			

			-- Create the new critical info		
			if criticalsnode then		
					-- create the child node for the new critical details
					critnode = criticalsnode.createChild();
					
					critnode.createChild("name","string").setValue(name);					
					critnode.createChild("description","formattedtext").setValue(description);
					critnode.createChild("severity","number").setValue(severity);						
			end		
		end	
	end
end
