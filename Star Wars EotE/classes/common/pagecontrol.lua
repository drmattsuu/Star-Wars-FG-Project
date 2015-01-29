local pageiconoff = "indicator_radiooff";
local pageiconon = "indicator_radioon";
local pageiconw = 12;
local pageiconh = 12;

local pageindex = 1;
local pageicons = {};

function onInit()
	if page then

		-- create and position the page icons to indicate which page is selected
		local xpos = (1 - table.getn(page)) * (pageiconw / 2);
		for k, v in ipairs(page) do
			pageicons[k] = addBitmapWidget(pageiconoff);
			pageicons[k].setPosition("", xpos, 0);
			xpos = xpos + pageiconw;
		end
	
		-- activate the correct page
		if activate then
			activatePage(activate[1]);
		else
			activatePage(1);
		end
	end
end

function activatePage(index)
	if page then
		pageicons[pageindex].setBitmap(pageiconoff);
		window[page[pageindex]].setVisible(false);
		pageindex = tonumber(index);
		if pageindex > table.getn(page) then
			pageindex = 1;
		end
		pageicons[pageindex].setBitmap(pageiconon);
		window[page[pageindex]].setVisible(true);
	end
end

function onClickDown(button, x, y)
	if page then
		local controlw, controlh = getSize();
		local iconwidth = table.getn(page) * pageiconw;
		if x >= (controlw - iconwidth) / 2 and x <= (controlw + iconwidth) / 2 and y >= (controlh - pageiconh) / 2 and y <= (controlh + pageiconh) / 2 then
			activatePage(pageindex + 1);
		end
	end
end

function onDoubleClick(x, y)
	onClickDown(1, x, y);
	return true;
end