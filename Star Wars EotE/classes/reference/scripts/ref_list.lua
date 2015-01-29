-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sFilter = "filter";

function onInit()
	if altfilter then
		sFilter = altfilter[1];
	end
end

function onFilter(w)
	local f = getFilter(w);
	if f == "" then
		setHeadersVisible(w, true);
		return true;
	end

	setHeadersVisible(w, false);
	
	if w.keywords then
		if string.find(string.lower(w.keywords.getValue()), f, 0, true) then
			setPathVisible(w);
			return true;
		end
	else
		if string.find(string.lower(w.name.getValue()), f, 0, true) then
			setPathVisible(w);
			return true;
		end
	end

	return false;
end

function setHeadersVisible(w, bShow)
	local vTop = w;
	while vTop.windowlist or vTop.parentcontrol do
		if vTop.windowlist then
			vTop = vTop.windowlist.window;
		else
			vTop = vTop.parentcontrol.window;
		end
		if vTop.showFullHeaders then
			vTop.showFullHeaders(bShow);
		end
	end
end

function setPathVisible(w)
	local vTop = w;
	while vTop.windowlist or vTop.parentcontrol do
		if vTop.windowlist then
			vTop.windowlist.setVisible(true);
			vTop = vTop.windowlist.window;
		else
			vTop.parentcontrol.setVisible(true);
			vTop = vTop.parentcontrol.window;
		end
	end
end

function getFilter(w)
	local vTop = w;
	while vTop.windowlist or vTop.parentcontrol do
		if vTop.windowlist then
			vTop = vTop.windowlist.window;
		else
			vTop = vTop.parentcontrol.window;
		end
	end
	if not vTop[sFilter] then
		return "";
	end

	return string.lower(vTop[sFilter].getValue());
end
