local Spring = {}
Spring.__index = Spring

function Spring.new(initial: number)
	return setmetatable({
		Position = initial or 0;
		Velocity = 0;
		Target = initial or 0;
		Damping = 0.8;
		Speed = 20;
	}, Spring)
end

function Spring:Update(deltaTime: number)
	local displacement = self.Target - self.Position
	local accel = displacement * self.Speed
	self.Velocity = (self.Velocity + accel * deltaTime) * self.Damping
	self.Position = self.Position + self.Velocity * deltaTime
	return self.Position
end

return Spring