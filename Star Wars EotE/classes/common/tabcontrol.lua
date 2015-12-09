local topWidget = nil;
local tabIndex = 1;
local tabWidgets = {};

function onInit()

	-- Create a helper graphic widget to indicate that the selected tab is on top
	topWidget = addBitmapWidget("tabtop");
	topWidget.setVisible(false);

	-- Deactivate all labels	
	for n, v in ipairs(tab) do
		tabWidgets[n] = addBitmapWidget(v.icon[1]);
		tabWidgets[n].setPosition("topleft", 7, 67*(n-1)+41);
		tabWidgets[n].setColor("80ffffff");
	end
	
	-- Reactivate existing tab
	local windowclass = window.getClass();
	local windownode = window.getDatabaseNode();
	local windownodename = "";
	if windownode then
		windownodename = windownode.getNodeName();
	end
	if CampaignRegistry.tabs and CampaignRegistry.tabs[windowclass] and CampaignRegistry.tabs[windowclass][windownodename] then
		activateTab(CampaignRegistry.tabs[windowclass][windownodename]);
	elseif activate then
		activateTab(activate[1]);
	else
		activateTab(1);
	end
	
end

function onClose()
	local windowclass = window.getClass();
	local windownode = window.getDatabaseNode();
	local windownodename = "";
	if windownode then
		windownodename = windownode.getNodeName();
	end
	if not CampaignRegistry.tabs then
		CampaignRegistry.tabs = {};
	end
	if not CampaignRegistry.tabs[windowclass] then
		CampaignRegistry.tabs[windowclass] = {};
	end	
	CampaignRegistry.tabs[windowclass][windownodename] = tabIndex;
end

function activateTab(index)

	-- Hide active tab, fade text labels
	tabWidgets[tabIndex].setColor("80ffffff");
	window[tab[tabIndex].subwindow[1]].setVisible(false);
	if tab[tabIndex].scroller then
		window[tab[tabIndex].scroller[1]].setVisible(false);
	end

	-- Set new index
	tabIndex = tonumber(index);
--LOBOSOLO BEGIN updating the taptop widget position original ("topleft, 5, 67*(tabIndex-1)+7)
	-- Move helper graphic into position
	topWidget.setPosition("topleft", 8, 67*(tabIndex-1)+40);
	if tabIndex == 1 then
		topWidget.setVisible(true);
	else
		topWidget.setVisible(true);
	end
--LOBOSOLO END also changed tab 1 to true
	
	-- Activate text label and subwindow
	tabWidgets[tabIndex].setColor("ffffffff");

	window[tab[tabIndex].subwindow[1]].setVisible(true);
	if tab[tabIndex].scroller then
		window[tab[tabIndex].scroller[1]].setVisible(true);
	end
end

function onClickDown(button, x, y)
	local i = math.ceil(y/67);
	
	-- Make sure index is in range and activate selected
	if i > 0 and i < #tab+1 then
		activateTab(i);
	end
end

function onDoubleClick(x, y)
	-- Emulate single click
	onClickDown(1, x, y);
end
