local linknode = nil;

function onInit()
	if link then
		linknode = window.getDatabaseNode().getChild(link[1]);
		if linknode then
			linknode.onUpdate = onUpdate;
		end
	end
	onUpdate(linknode);	
end

function onUpdate(source)
	local sourcevalue = source.getValue();
	if string.find(string.lower(sourcevalue), "dwar", 1, true) then
		setIcon("racedwarf");
	elseif string.find(string.lower(sourcevalue), "high", 1, true) then
		setIcon("racehighelf");
	elseif string.find(string.lower(sourcevalue), "wood", 1, true) then
		setIcon("racewoodelf");
	elseif string.find(string.lower(sourcevalue), "ogre", 1, trye) then
		setIcon("raceogre");
	elseif string.find(string.lower(sourcevalue), "half", 1, trye) then		
		setIcon("racehalfling");	
	else
		setIcon("racehuman");
	end
end