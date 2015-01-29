local activewidget = nil;
local activenode = nil;

function onInit()

	-- create the active indicator widget
	activewidget = addBitmapWidget(activeicon[1]);
	activewidget.setVisible(false);
	
	-- get the active node
	if User.isHost() then
		activenode = window.getDatabaseNode().createChild("actor.active", "number");
		if activenode then
			if activenode.getValue() ~= 1 then
				activenode.setValue(0);
			end
		end
	else
		Debug.console("actoractiveindicator.lua: onInit() - window.getDatabaseNode().getNodeName() = " .. window.getDatabaseNode().getNodeName());
		--activenode = window.getDatabaseNode().createChild("actor.active");
		activenode = DB.findNode(window.getDatabaseNode().getNodeName() .. ".actor.active");
		--Debug.console("actoractiveindicator.lua: onInit() - activenode.getNodeName() = " .. activenode.getNodeName());
	end
	activenode.onUpdate = onUpdate;
	onUpdate(activenode);
end

function onUpdate(source)
	if activenode then
		if activenode.getValue() == 1 then
			activewidget.setVisible(true);
		else
			activewidget.setVisible(false);
		end
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	return InitiativeManager.activateActor(window.getDatabaseNode());
end