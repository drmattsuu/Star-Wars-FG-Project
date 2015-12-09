local sourcenode = nil;
local thresholdnode = nil;
local indicatorwidget = nil;

function onInit()

	-- initialize the base class
	super.onInit();
	
	-- get the source node
	sourcenode = getDatabaseNode();
	
	--Debug.console("woundnumberfield.  Node = " .. getDatabaseNode().getNodeName());
	
	if sourcenode then
	
		-- get the threshold node
		thresholdnode = sourcenode.getChild("..threshold");
		if thresholdnode then
			thresholdnode.onUpdate = onUpdate;
		end
		
		-- create the indicator widget
		indicatorwidget = addBitmapWidget("indicator_wound");
		indicatorwidget.setPosition("bottomleft", 0, -4);
	
		-- force an update now
		update();
	
	end

end

function onUpdate(source)
	update();
end

function onValueChanged()
	super.onValueChanged();
	update();
end

function update()
	--Debug.console("Running woundnumberfield update().  Value = " .. sourcenode.getValue());
	
	if sourcenode then
	
		-- Handle minion damage and members remaining calculations.
	
		--Debug.console("Charsheet or NPC? " .. sourcenode.getNodeName())
		if User.isHost() then
			if sourcenode.getChild("...npc_category") then
				local category = sourcenode.getChild("...npc_category").getValue();
				--Debug.console("Charsheet or NPC? " .. classname);
				if category then
					if string.lower(category) == "minion" then
						local newWoundValue = sourcenode.getValue();
						local minionWoundsPerMember = sourcenode.getChild("...minion.wounds_per_minion").getValue();
						if newWoundValue <= minionWoundsPerMember then
							sourcenode.getChild("...minion.minions_remaining").setValue(sourcenode.getChild("...minion.number_in_group").getValue());
						else
							local membersRemoved = math.floor((newWoundValue - 1) / minionWoundsPerMember);
							sourcenode.getChild("...minion.minions_remaining").setValue(sourcenode.getChild("...minion.number_in_group").getValue() - membersRemoved);
						end
					end
				end
			end	
		end
	

		local thresholdvalue = nil;
		if thresholdnode then
			thresholdvalue = thresholdnode.getValue();
		end
		if not thresholdvalue or thresholdvalue >= getValue() then
			indicatorwidget.setVisible(false);
		else
			indicatorwidget.setVisible(true);
		end
	end
end