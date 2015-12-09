local dragging = false;

function onInit()

	-- determine if node is static
	if window.getDatabaseNode().isStatic() then
		setVisible(false);
		return
	end
	
	-- set the hover cursor
	setHoverCursor("hand");	
	
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not dragging then
		local sourcenode = window.getDatabaseNode();
		
		local skillsnode = window.getDatabaseNode().getChild("skills");
		local initskillnode = nil;
		local initskillname = "";
		--Debug.console("Skills node = " .. skillsnode.getNodeName());
		if self.getName() == "combat_init_cool_btn" then	
			initskillname = "Cool (Pr)";
		elseif self.getName() == "combat_init_vigilance_btn" then
			initskillname = "Vigilance (Will)";
		end

		for k,v in pairs(skillsnode.getChildren()) do
			--Debug.console("Looking at current child: " .. k);
			if v.getChild("name").getValue() == initskillname then
				--Debug.console("Have the " .. initskillname .. " db node = " .. v.getNodeName());
				initskillnode = v;
				break;
			end
		end
		
		-- Try secondary skills of "Cool" or "Vigilance" (named without the characterstic)
		if not initskillnode then
			if self.getName() == "combat_init_cool_btn" then	
				initskillname = "Cool";
			elseif self.getName() == "combat_init_vigilance_btn" then
				initskillname = "Vigilance";
			end

			for k,v in pairs(skillsnode.getChildren()) do
				--Debug.console("Looking at current child: " .. k);
				if v.getChild("name").getValue() == initskillname then
					--Debug.console("Have the " .. initskillname .. " db node = " .. v.getNodeName());
					initskillnode = v;
					break;
				end
			end		
		end
		
		-- TODO: Need to code for no match in skills - i.e. use characteristic score only.
		
		local dice = {};
		DicePoolManager.addSkillDice(initskillnode, dice);
		if table.getn(dice) > 0 then
			draginfo.setType("skill");
			if initskillnode.getChild("name") then
				draginfo.setDescription(initskillnode.getChild("name").getValue()  .. " [INIT]");
			end
			draginfo.setDieList(dice);
			draginfo.setDatabaseNode(initskillnode);
			dragging = true;
			return true;								
		end		
	end
	return false;
end

function onDragEnd(draginfo)
	dragging = false;
end

-- Allows population of the dice pool by a double-click on the dice button by the skill
function onDoubleClick()

	Debug.console("initdicepool.lua - onDoubleClick");
	--local sourcenode = window.getDatabaseNode();
	local skillsnode = window.getDatabaseNode().getChild("skills");
	if not skillsnode then
		return;
	end
	local initskillnode = nil;
	local initskillname = "";
	--Debug.console("Skills node = " .. skillsnode.getNodeName());
	if self.getName() == "combat_init_cool_btn" then	
		initskillname = "Cool (Pr)";
	elseif self.getName() == "combat_init_vigilance_btn" then
		initskillname = "Vigilance (Will)";
	end

	for k,v in pairs(skillsnode.getChildren()) do
		--Debug.console("Looking at current child: " .. k);
		if v.getChild("name").getValue() == initskillname then
			--Debug.console("Have the " .. initskillname .. " db node = " .. v.getNodeName());
			initskillnode = v;
			break;
		end
	end
	
	-- Try secondary skills of "Cool" or "Vigilance" (named without the characterstic)
	if not initskillnode then
		if self.getName() == "combat_init_cool_btn" then	
			initskillname = "Cool";
		elseif self.getName() == "combat_init_vigilance_btn" then
			initskillname = "Vigilance";
		end
		for k,v in pairs(skillsnode.getChildren()) do
			Debug.console("Looking at current child: " .. k);
			if v.getChild("name").getValue() == initskillname then
				initskillnode = v;
				break;
			end
		end		
	end
	
	-- TODO: Need to code for no match in skills - i.e. use characteristic score only.	
	
	local dice = {};
	local skilldescription;
	local msgidentity = DB.getValue(initskillnode, "...name", "");
	DicePoolManager.addSkillDice(initskillnode, dice);
	if table.getn(dice) > 0 then
		if initskillnode.getChild("name") then
			skilldescription = initskillnode.getChild("name").getValue() .. " [INIT]";		
		end
		DieBoxManager.addSkillDice(skilldescription, dice, initskillnode, msgidentity);
	end
end