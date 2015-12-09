local widgets = {};
local updating = false;

function update()
	if not updating then
		updating = true;
		
		for k, v in ipairs(widgets) do
			if v then
				v.destroy();
			end
		end
		
		local holders = window.getViewers();
		local p = 1;

		setAnchoredWidth(#holders * portraitspacing[1]);
		setAnchoredHeight(portraitspacing[1]);
		
		for i = 1, #holders do
			local identity = User.getCurrentIdentity(holders[i]);

			if identity then
				local bitmapname = "portrait_" .. identity .. "_" .. portraitset[1];

				widgets[i] = addBitmapWidget(bitmapname);
				widgets[i].setPosition("left", portraitspacing[1] * (p-0.5), 0);
				
				p = p + 1;
			end
		end
		
		updating = false;
	end
end

function onLogin(username, activated)
	update(monitornode);
end

function onInit()
	if User.isHost() then
		window.onViewersChanged = update;
		update();
	else
		setVisible(false);
	end
end