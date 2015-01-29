function onDrop(x, y, draginfo)
	if draginfo.isType("token") then
		local prototype = draginfo.getTokenData();

		-- Check for duplicates
		for k,v in ipairs(getWindows()) do
			if v.token.getPrototype() == prototype then
				return true;
			end
		end
		
		local w = createWindow();
		w.token.setPrototype(prototype);
		
		return true;
	end
end