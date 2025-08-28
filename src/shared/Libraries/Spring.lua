local Spring = {}
Spring.__index = Spring

function Spring.new(initial)
	return setmetatable({
		Position = initial or 0,
		Velocity = 0,
		Target = initial or 0,
		Frequency = 5,
		DampingRatio = 1,
		MaxDt = 1 / 30,
	}, Spring)
end

function Spring:Update(dt)
	local delta = dt
	if delta <= 0 then
		return self.Position
	end
	if delta > self.MaxDt then
		delta = self.MaxDt
	end

	local f = self.Frequency * 2 * math.pi
	local d = 2 * self.DampingRatio * f
	local k = f * f
	local x = self.Position - self.Target

	local accel = -k * x - d * self.Velocity
	self.Velocity = self.Velocity + accel * delta
	self.Position = self.Position + self.Velocity * delta
	return self.Position
end

return Spring
