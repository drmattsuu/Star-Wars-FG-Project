-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sFocus = "name";

function onInit()
	if newfocus then
		sFocus = newfocus[1];
	end
end

function onListChanged()
	update();
end

function update()
	local sEdit = getName() .. "_iedit";
	if window[sEdit] then
		local bEdit = (window[sEdit].getValue() == 1);
		for _,w in ipairs(getWindows()) do
			w.idelete.setVisibility(bEdit);
		end
	end
end

function onClickDown(button, x, y)
	if not isReadOnly() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if not isReadOnly() then
		if getWindowCount() == 0 then
			addEntry(true);
		end
		return true;
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if bFocus then
		w[sFocus].setFocus();
	end
	return w;
end
