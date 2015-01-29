function onInit()
	Input.onAlt = update;
	Input.onShift = update;
	Input.onControl = update;
end

function update()
	local state = 0;
	if Input.isControlPressed() then
		state = state + 1;
	end
	if Input.isShiftPressed() then
		state = state + 2;
	end
	if Input.isAltPressed() then
		state = state + 4;
	end
	if state == 1 then
		if User.isHost() then
			setIcon("chat_story");
		else
			setIcon("chat_action");
		end
	elseif state == 3 then
		setIcon("chat_emote");
	elseif state >=4 and state <=7 then
		setIcon("chat_ooc");	
	else
		setIcon("chat_speak");
	end
end
