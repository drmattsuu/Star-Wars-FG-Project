-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sName;

function onInit()
	sName = getName();
end

function onEnter()
	if not isReadOnly() and window.windowlist.addEntry then
		window.windowlist.addEntry(true);
	end
	return true;
end

function onNavigateDown()
	local winNext = window.windowlist.getNextWindow(window);
	if winNext and winNext[sName] then
		winNext[sName].setFocus();
		winNext[sName].setCursorPosition(1);
		winNext[sName].setSelectionPosition(1);
	end
	return winNext;
end

function onNavigateUp()
	local winPrev = window.windowlist.getPrevWindow(window);
	if winPrev and winPrev[sName] then
		winPrev[sName].setFocus();
		winPrev[sName].setCursorPosition(#winPrev[sName].getValue()+1);
		winPrev[sName].setSelectionPosition(#winPrev[sName].getValue()+1);
	end
	return winPrev;
end

function onNavigateRight()
	local sNext = getTabTarget(true);
	while sNext ~= "" do
		local target = window[sNext];
		if not target or (type(target) ~= "stringcontrol") then
			return;
		end
		if target.isVisible() then
			target.setFocus();
			target.setCursorPosition(1);
			target.setSelectionPosition(1);
			return;
		end
		sNext = target.getTabTarget(true);
	end
end

function onNavigateLeft()
	local sPrev = getTabTarget(false);
	while sPrev ~= "" do
		local target = window[sPrev];
		if not target or (type(target) ~= "stringcontrol") then
			return;
		end
		if target.isVisible() then
			target.setFocus();
			target.setCursorPosition(#target.getValue()+1);
			target.setSelectionPosition(#target.getValue()+1);
			return;
		end
		sPrev = target.getTabTarget(false);
	end
end

function onDeleteUp()
	if isReadOnly() then
		return;
	end
	
	if nodelete then
		onNavigateUp();
		return;
	end
	
	local win = onNavigateUp();
	if not win then
		win = onNavigateDown();
	end
	if win and isEmpty() then
		delete();
	end
end

function onDeleteDown()
	if isReadOnly() then
		return;
	end
	
	if nodelete then
		onNavigationDown();
		return;
	end
	
	local win = onNavigateDown();
	if not win then
		win = onNavigateUp();
	end
	if win and isEmpty() then
		delete();
	end
end

function delete()
	if nodeletelast and #(window.windowlist.getWindows()) == 1 then
		return;
	end
		
	local nodeWin = window.getDatabaseNode();
	if nodeWin then
		nodeWin.delete();
	else
		window.close();
	end
end

function onGainFocus()
	if nohighlight then
		return;
	end
	window.setFrame("rowshade");
end

function onLoseFocus()
	if nohighlight then
		return;
	end
	window.setFrame(nil);
end
