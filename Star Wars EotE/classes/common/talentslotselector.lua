local alignvalue = "center";

local updating = false;

local sourcenode = nil;
local sourcelabel = nil;
local sourcetalents = {};

function onInit()

	-- get the source node
	local sourcenodename;
	if sourcename then
		sourcenodename = sourcename[1];
	else
		sourcenodename = getName();
	end
	if window.getDatabaseNode().isOwner() then
		sourcenode = window.getDatabaseNode().createChild(sourcenodename, "string");
	else
		sourcenode = window.getDatabaseNode().getChild(sourcenodename);
	end
	
	-- if the source node exists
	if sourcenode then
	
		-- get the default align values
		if align then
			alignvalue = align[1];
		end
		
		-- get the available talents
		local talentsvalue = "Any,Faith,Focus,Insanity,Oath,Order,Reputation,Tactic";
		if talents then
			talentsvalue = talents[1];
		end
		sourcetalents = split(talentsvalue, ",");
	
		-- subscribe to the sourcenode update event
		sourcenode.onUpdate = onUpdate;
		
		-- and trigger an update
		update();
	end

end

function onUpdate(source)
	update();
end

function update()
	DebugManager.logMessage("talentslotselector.update");
	if sourcenode then

		-- get the source value
		local sourcevalue = sourcenode.getValue();

		-- create the source label if required
		if not sourcelabel then
			sourcelabel = addTextWidget("sheetlabel", "");
		end

		-- set the source label
		if sourcevalue == "Any" then
			sourcelabel.setText("An");
		elseif sourcevalue == "Faith" then
			sourcelabel.setText("Fa");
		elseif sourcevalue == "Focus" then
			sourcelabel.setText("Fo");
		elseif sourcevalue == "Insanity" then
			sourcelabel.setText("In");
		elseif sourcevalue == "Oath" then
			sourcelabel.setText("Oa");
		elseif sourcevalue == "Order" then
			sourcelabel.setText("Or");
		elseif sourcevalue == "Reputation" then
			sourcelabel.setText("Rp");
		elseif sourcevalue == "Tactic" then
			sourcelabel.setText("Ta");
		elseif sourcevalue == "Trick" then
			sourcelabel.setText("Tr");
		else
			sourcelabel.setText("-");
		end

		-- set the label colour
		if sourcevalue == "" then
			sourcelabel.setFont("sheetlabeldisabled");
		else
			sourcelabel.setFont("sheetlabel");
		end

		-- get the control size
		local controlw, controlh = sourcelabel.getSize();

		-- position the label
		if string.lower(alignvalue) == "left" then
			sourcelabel.setPosition("left", (controlw/2), 0);
		elseif string.lower(alignvalue) == "right" then
			sourcelabel.setPosition("right", -(controlw/2), 0);
		else
			sourcelabel.setPosition("",0,0);			
		end
	end
end

function onClickDown(button, x, y)
	if not disabled then
		if sourcenode then
			if not sourcenode.isStatic() and sourcenode.isOwner() then
			
				-- get the source values
				local sourcevalue = sourcenode.getValue();
				local sourceindex = nil;
				
				-- locate the index of the current slot
				for i, v in ipairs(sourcetalents) do
					if sourcevalue == v then
						sourceindex = i;
					end
				end				
				
				-- take action based on the new source index
				if sourceindex then
					if sourceindex == table.getn(sourcetalents) then
						sourcenode.setValue("");
					else
						sourcenode.setValue(sourcetalents[sourceindex + 1]);
					end
				else
					sourcenode.setValue(sourcetalents[1]);
				end

			end
		end
	end
end

function split(value, delimiter)
  local result = { }
  local from = 1
  local delim_from, delim_to = string.find( value, delimiter, from )
  while delim_from do
    table.insert( result, string.sub( value, from , delim_from-1 ) )
    from = delim_to + 1
    delim_from, delim_to = string.find( value, delimiter, from )
  end
  table.insert( result, string.sub( value, from ) )
  return result
end