local skillsnode = nil;
local updating = false;

function onInit()
	local windownode = window.getDatabaseNode();
	if windownode then
		skillsnode = windownode.getChild("skills");
		if skillsnode then
			skillsnode.onChildUpdate = onChildUpdate;
			update();
		end
	end
end

function onClose()
	if skillsnode then
		skillsnode.onChildUpdate = function() end;
	end
end

function onChildUpdate(source)
	update();
end

function update()
	if skillsnode and not updating then
		updating = true;
		
		-- get the existing windows
		local existing = {};
		for i, w in ipairs(getWindows()) do
			local nodename = w.getDatabaseNode().getNodeName();
			if not existing[nodename] then
				existing[nodename] = nodename;
			end
		end
		
		-- add any new windows
		local sortrequired = false;
		for k1, n1 in pairs(skillsnode.getChildren()) do
			local specialisationsnode = n1.getChild("specialisations");
			if specialisationsnode then
				for k2, n2 in pairs(specialisationsnode.getChildren()) do
					local nodename = n2.getNodeName();
					if not existing[nodename] then
						createWindowWithClass("specialisationsmall", n2);
						sortrequired = true;
					end
				end
			end
		end
		
		-- apply sort if any new items were added
		if sortrequired then
			applySort();
		end
		
		updating = false;
	end
end

function onSortCompare(w1, w2)
	if w1.name.getValue() == "" then
		return true;
	elseif w2.name.getValue() == "" then
		return false;
	end
	return w1.name.getValue() > w2.name.getValue();
end
