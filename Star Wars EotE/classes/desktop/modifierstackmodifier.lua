function onGainFocus()
	ModifierStack.setAdjustmentEdit(true);
end

function onLoseFocus()
	ModifierStack.setAdjustmentEdit(false);
end

function onWheel(notches)
	if not hasFocus() then
		ModifierStack.adjustFreeAdjustment(notches);
	end

	return true;
end

function onValueChanged()
	if hasFocus() then
		ModifierStack.setFreeAdjustment(getValue());
	end
end

function onClickDown(button, x, y)
	if button == 2 then
		ModifierStack.reset();
		return true;
	end
end

function onDrop(x, y, draginfo)
	return window.base.onDrop(x, y, draginfo);
end

function onDragStart(button, x, y, draginfo)
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)

	-- Create a composite drag type so that a simple drag into the chat window won't use the modifiers twice
	draginfo.setType("modifierstack");
	draginfo.setNumberData(ModifierStack.getSum());

	local basedata = draginfo.createBaseData("number");
	basedata.setDescription(ModifierStack.getDescription());
	basedata.setNumberData(ModifierStack.getSum());
	return true;
end

function onDragEnd(draginfo)
	if PreferenceManager.getValue("interface_resetmodifierstack") then
		ModifierStack.reset();
	end
end
