-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local winParentBar = nil;
local sButtonID = "";

local sButtonHighlightColor = "FFFFFFFF";
local sButtonNormalColor = "60A0A0A0";

function onButtonPress()
	if winParentBar and winParentBar.onButtonPress then
		winParentBar.onButtonPress(sButtonID);
	end
end

function configure(win, sID, sIcon, sTooltip, bToggle)
	winParentBar = win;
	sButtonID = sID;

	if bToggle then
		setStateIcons(0, sIcon);
		setStateColor(0, sButtonNormalColor);
		setStateIcons(1, sIcon);
	else
		setIcons(sIcon);
	end
	
	setTooltipText(sTooltip);
end
