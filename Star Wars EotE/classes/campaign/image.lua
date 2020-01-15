-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("image_menu_size"), "restorewindow", 3);
	registerMenuItem(Interface.getString("image_menu_sizeoriginal"), "maximizewindow", 3, 2);
	registerMenuItem(Interface.getString("image_menu_sizevertical"), "rotatecw", 3, 4);
	registerMenuItem(Interface.getString("image_menu_sizehorizontal"), "rotateccw", 3, 5);
	registerMenuItem(Interface.getString("resize_to_grid"), "pointer_square", 3, 8)
	
end

function onMenuSelection(item, subitem)
	if item == 3 then
		if subitem == 2 then
			local iw, ih = image.getImageSize();
			local w = iw + image.marginx[1];
			local h = ih + image.marginy[1];
			setSize(w, h);
			image.setViewpoint(0,0,1);
		elseif subitem == 4 then
			local iw, ih = image.getImageSize();
			local cw, ch = image.getSize();
			local w = cw + image.marginx[1];
			local h = ((ih/iw)*cw) + image.marginy[1];
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		elseif subitem == 5 then
			local iw, ih = image.getImageSize();
			local cw, ch = image.getSize();
			local w = ((iw/ih)*ch) + image.marginx[1];
			local h = ch + image.marginy[1];
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		elseif subitem == 8 then
			resizeToGrid();
		end			
	end
end

-- Player Image Auto Size code
function resizeToGrid()
	Debug.console("image.lua:resizeToGrid.")
	local iX, iY = image.getImageSize();
	local imageGridSize = image.getGridSize();
	if imageGridSize == 0 then
		local msg = {sender = "", font = "chatbolditalicfont", icon=""};
		msg.text = "Resize Grid: No grid set.  Please set a grid before trying to size to grid."
		Comm.deliverChatMessage(msg);		
		return;
	end
	local XInches = iX / imageGridSize;
	local YInches = iY / imageGridSize;
	Debug.console("Image grid = " .. imageGridSize .. "pixels.  Dimension in inches = " ..  XInches .. ", " .. YInches);
	
	-- Get TV size from DB
	local setTVSize = 0;
	local tvSizeDBNode = DB.findNode("extension_data.tvsize");
	if tvSizeDBNode then
		setTVSize = tvSizeDBNode.getValue();
	else
		local msg = {};
		msg.font = "systemfont";
		msg.text = "Cannot find TV size set in database.  Please set TV size through the chat window using: /tvsize [TV size in inches] [TV height (Y) resolution in pixels]";
		Comm.addChatMessage(msg);
		return;
	end
	
	-- Get TV size from DB
	local tvResolution = 0;
	local tvResolutionDBNode = DB.findNode("extension_data.tvresolution");
	if tvResolutionDBNode then
		tvResolution = tvResolutionDBNode.getValue();
	else
		local msg = {};
		msg.font = "systemfont";
		msg.text = "Cannot find TV resolution set in database.  Please set TV size through the chat window using: /tvsize [TV size in inches] [TV height (Y) resolution in pixels]";
		Comm.addChatMessage(msg);
		return;
	end
	
	-- Calculate the TV width and height - based off a 16:9 format TV.
	local tvWidth = setTVSize * 0.87157552765421;
	local tvHeight = setTVSize * 0.490261259680549;
	
	local tvPixelsPerInch = tvResolution / tvHeight;
	Debug.console("TV dimensions in inches for " .. setTVSize .. " inches = " .. tvWidth .. ", " .. tvHeight .. ". At " .. tvPixelsPerInch .. " Pixels per inch.");
	
	-- Setting total window size based off image control bounds of 21,58,-27,-29
	local wX = iX + 48;
	local wY = iY + 87;
	
	-- Window reported size
	local wrX, wrY = getSize();
	Debug.console("imagewindow.lua: Window reported size = " .. wrX .. ", " .. wrY .. ".  Calculated from image = " .. wX .. ", " .. wY .. ".");
	
	-- Calculate scale factor - only need to do this in one dimension.  We'll use Y (height) si we can set the TV resolution using standard 1080, 720, etc. notation.
	local scaleFactor = tvPixelsPerInch / imageGridSize;
	
--	local newWX = math.floor(wX * scaleFactor);
--	local newWY = math.floor(wY * scaleFactor);
	
	local newWX = math.floor(iX * scaleFactor + 48);
	local newWY = math.floor(iY * scaleFactor + 87);
	
	
	-- Set the image size - need to do this before setting the scale factor.  What if image size is larger than before?
	Debug.console("Setting new size = " .. newWX .. ", " .. newWY);
	setSize(newWX, newWY);	
	
	-- Set the image zoom factor
	Debug.console("Setting new scale = " .. scaleFactor);
	image.setViewpoint(1, 1, scaleFactor);
	
	--Debug.console("Setting new size = " .. newWX .. ", " .. newWY);
	--setSize(newWX, newWY);
	
	-- Set the newly resized window position to be top left of the desktop
	setPosition(1, 1);

end

