local sourcenode = nil;
local sourcewidget = nil;

function onInit()
	if source then
		sourcenode = window.getDatabaseNode().createChild(source[1], "string");
		if sourcenode then
			sourcenode.onUpdate = onUpdate;
		end
	end
	onUpdate(sourcenode);
end

function onUpdate(source)
	if sourcenode then
	
		-- create the text widget if required
		if not sourcewidget then
			sourcewidget = addTextWidget("sheetext", "");
			sourcewidget.setPosition("left", 9, 0);					
		end
	
		-- update the icon and text
		local sourcevalue = sourcenode.getValue();
		if sourcevalue == "Fortune" then
			setIcon("dFortuneicon");
			sourcewidget.setText("+1");
			sourcewidget.setFont("sheetlabel");
		elseif sourcevalue == "Misfortune" then
			setIcon("dMisfortuneicon");
			sourcewidget.setText("-1");
			sourcewidget.setFont("sheetlabelwhite");			
		elseif sourcevalue == "Expertise" then
			setIcon("dExpertiseicon");
			sourcewidget.setText("+1");
			sourcewidget.setFont("sheetlabel");			
		elseif sourcevalue == "Challenge" then
			setIcon("dChallengeicon");
			sourcewidget.setText("-1");
			sourcewidget.setFont("sheetlabelwhite");			
		else
			setIcon("dEmptyicon");
			sourcewidget.setText("");			
		end
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if sourcenode and not sourcenode.isStatic() then
		local sourcevalue = sourcenode.getValue();
		if sourcevalue == "Fortune" then
			sourcenode.setValue("Misfortune");
		elseif sourcevalue == "Misfortune" then
			sourcenode.setValue("Expertise");
		elseif sourcevalue == "Expertise" then
			sourcenode.setValue("Challenge");
		elseif sourcevalue == "Challenge" then
			sourcenode.setValue("");
		else
			sourcenode.setValue("Fortune");
		end
	end
end