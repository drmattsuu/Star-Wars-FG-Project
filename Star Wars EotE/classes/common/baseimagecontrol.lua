local tokenclassname = nil;
local tokenrecordname = nil;

function onInit()

	PreferenceManager.registerValueObserver("images_hexgrid", gridPrefTypeChanged);
	if PreferenceManager.getValue("images_hexgrid") then
		setGridToolType("hex");
	end

	if User.isHost() then
		local type = getGridType();
		if not type or type == "square" then
			setTokenOrientationCount(8);
		else
			setTokenOrientationCount(12);
		end
	end
end

function onClose()
	PreferenceManager.unregisterValueObserver("images_hexgrid", gridPrefTypeChanged);
	TokenManager.cleanTokens(getDatabaseNode(), getTokens());	
end

function gridPrefTypeChanged(valuename, value)
	if valuename == "images_hexgrid" then
		if value then
			setGridToolType("hex");
		else
			setGridToolType("square");
		end
	end
end

function onGridStateChanged(type)
	if User.isHost() then
		if not type or type == "square" then
			setTokenOrientationCount(8);
		else
			setTokenOrientationCount(12);
		end
	end
end

function onTokenSnap(token, x, y)
	if hasGrid() and PreferenceManager.getValue("images_snaptogrid") then
		return getClosestSnapPoint(x, y);
	else
		return x, y;
	end
end

function onPointerSnap(startx, starty, endx, endy, type)
	local newstartx = startx;
	local newstarty = starty;
	local newendx = endx;
	local newendy = endy;

	if hasGrid() and PreferenceManager.getValue("images_snaptogrid") then
		newstartx, newstarty = getClosestSnapPoint(startx, starty);
		newendx, newendy = getClosestSnapPoint(endx, endy);
	end

	return newstartx, newstarty, newendx, newendy;
end

function onMeasurePointer(length)
	if hasGrid() and PreferenceManager.getValue("images_snaptogrid") then
		return math.floor(length / getGridSize() * 5) .. "\'";
	else
		return "";
	end
end

function onMeasureVector(token, vector)
	if hasGrid() and PreferenceManager.getValue("images_snaptogrid") then
		local type = getGridType();
		
		if type == "square" then
			local diagonals = 0;
			local straights = 0;
			local gridsize = getGridSize();
		
			for i = 1, #vector do
				local gx = math.abs(math.floor(vector[i].x / gridsize));
				local gy = math.abs(math.floor(vector[i].y / gridsize));
				
				if gx > gy then
					diagonals = diagonals + gy;
					straights = straights + gx - gy;
				else
					diagonals = diagonals + gx;
					straights = straights + gy - gx;
				end
			end
			
			local squares = math.floor(diagonals * 1.5) + straights;
			local feet = squares * 5;
			
			return feet .. "\'";
		else
			local pixels = 0;

			for i = 1, #vector do
				pixels = pixels + math.floor(math.sqrt(vector[i].x*vector[i].x + vector[i].y*vector[i].y));
			end
			
			local units = math.floor(pixels / getGridSize());
			local feet = units * 5;
			
			return feet .. "\'";
		end
	else
		return "";
	end
end

function getClosestSnapPoint(x, y)
	if not hasGrid() then
		return x, y;
	end
	
	local type = getGridType();
	local size = getGridSize();
	
	if type == "square" then
		local ox, oy = getGridOffset();
		
		local centerx = math.floor((x - ox)/size)*size + size/2 + ox + 1;
		local centery = math.floor((y - oy)/size)*size + size/2 + oy + 1;
		
		local centerxdist = x - centerx;
		local centerydist = y - centery;
	
		local cornerx = math.floor((x - ox + size/2)/size)*size + ox + 1;
		local cornery = math.floor((y - oy + size/2)/size)*size + oy + 1;
		
		local cornerxdist = x - cornerx;
		local cornerydist = y - cornery;
	
		local cornerlimit = size / 4;
		
		if math.abs(cornerxdist) <=cornerlimit and math.abs(cornerydist) <=cornerlimit and 
		   centerxdist*centerxdist+centerydist*centerydist > cornerxdist*cornerxdist+cornerydist*cornerydist then
			return cornerx, cornery;
		else
			return centerx, centery;
		end
	else
		local qw, hh = getGridHexElementDimensions();
		local ox, oy = getGridOffset();
		
		-- The hex grid separates into a non-square grid of elements sized qw*hh, the location in which dictates corner points
		if type == "hexcolumn" then
			local col = math.floor((x - ox) / qw);
			local row = math.floor((y - oy) * 2 / size);
			
			local evencol = col % 2 == 0;
			local evenrow = row % 2 == 0;

			local lx = (x - ox) % qw;
			local ly = (y - oy) % hh;
			
			if (evenrow and evencol) or (not evenrow and not evencol) then
				-- snap to lower right and upper left
				if lx + ly * (qw/hh) < qw then
					return ox + col*qw, oy + math.floor(row*size/2);
				else
					return ox + (col+1)*qw, oy + math.floor((row+1)*size/2);
				end
			else
				-- snap to lower left and upper right
				if (qw-lx) + ly * (qw/hh) < qw then
					return ox + (col+1)*qw, oy + math.floor(row*size/2);
				else
					return ox + col*qw, oy + math.floor((row+1)*size/2);
				end
			end
		else -- "hexrow"
			local col = math.floor((x - ox) * 2 / size);
			local row = math.floor((y - oy) / qw);
			
			local evencol = col % 2 == 0;
			local evenrow = row % 2 == 0;

			local lx = (x - ox) % hh;
			local ly = (y - oy) % qw;
			
			if (evenrow and evencol) or (not evenrow and not evencol) then
				-- snap to lower right and upper left
				if lx * (qw/hh) + ly < qw then
					return ox + math.floor(col*size/2), oy + row*qw;
				else
					return ox + math.floor((col+1)*size/2), oy + (row+1)*qw;
				end
			else
				-- snap to lower left and upper right
				if (hh-lx) * (qw/hh) + ly < qw then
					return ox + math.floor((col+1)*size/2), oy + row*qw;
				else
					return ox + math.floor(col*size/2), oy + (row+1)*qw;
				end
			end
		end
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("playercharacter") or draginfo.isType("partyidentity") or draginfo.isType("npc") or draginfo.isType("location") or draginfo.isType("pet") or draginfo.isType("horse") or draginfo.isType("retainer") then
		tokenclassname, tokenrecordname = draginfo.getShortcutData();
	end
end

function onTokenAdded(token)

	-- inform the host of the token addition
	if tokenclassname and tokenrecordname then
	
		-- inform the token manager that a token has been added
		TokenManager.addToken(token, tokenclassname, tokenrecordname);
		
		-- attempt to get the record node
		local tokenrecordnode = DB.findNode(tokenrecordname);
		if tokenrecordnode then
			local tokennamenode = tokenrecordnode.getChild("name");
			if tokennamenode then
				token.setName(tokennamenode.getValue());
			end
		end
	end
		
	-- subscribe to the token events
	token.onClickDown = onTokenClickDown;
	token.onClickRelease = onTokenClickRelease;
	token.onDrop = onTokenDrop;	
	token.onWheel = onTokenWheel;

	-- clear the old token information	
	tokenclassname = nil;
	tokerecordname = nil;
	
end

function onTokenClickDown(token, button)
	return true;
end

function onTokenClickRelease(token, button)
	if button == 1 then
		if Input.isControlPressed() then
			return TokenManager.targetToken(token);		
		else
			return TokenManager.openTokenSheet(token);
		end
	elseif button == 2 then
		return TokenManager.targetToken(token);	
	end
end

function onTokenDrop(token, draginfo)
	return TokenManager.onDrop(token, draginfo);
end

function onTokenWheel(token, notches)
	return TokenManager.onWheel(token, notches)
end