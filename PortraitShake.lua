local shakers = {};
local MAX_AMPLITUDE = 5.0;

local function randomDir()
    local theta = math.random() * math.pi * 2.0;
    return {x=math.cos(theta), y=math.sin(theta)};
end

local Shaker = {};
local function newShaker(widget)
    return setmetatable({
        widget = widget,
        anchor = {widget:GetPoint()},
        t = 0.0,
        shakeDir = {x=0, y=1},
        amplitude = 0.0
    }, {__index = Shaker});
end
function Shaker:shake(importance)
    self.t = 0.0; -- Reset t to immediately bring cos(t*k) to max
    self.amplitude = min(self.amplitude + importance * MAX_AMPLITUDE, MAX_AMPLITUDE);
    self.shakeDir = randomDir();
end
function Shaker:update(elapsed)
    if ( self.amplitude > 0.0 ) then
        local p, r, rp, x, y = unpack(self.anchor);
        local phase = self.t * math.pi * 8.0;
        local mag = math.cos(phase) * self.amplitude;
        self.widget:SetPoint(p, r, rp, x + self.shakeDir.x * mag, y + self.shakeDir.y * mag);
        self.amplitude = max(0, self.amplitude - elapsed * MAX_AMPLITUDE);
        self.t = self.t + elapsed;
    end
end

function PortraitShake_OnLoad()
    shakers = {
        target = newShaker(TargetPortrait),
        player = newShaker(PlayerPortrait),
        pet = newShaker(PetPortrait),
        party1 = newShaker(PartyMemberFrame1Portrait),
        party2 = newShaker(PartyMemberFrame2Portrait),
        party3 = newShaker(PartyMemberFrame3Portrait),
        party4 = newShaker(PartyMemberFrame4Portrait),
        partypet1 = newShaker(PartyMemberFrame1PetFramePortrait),
        partypet2 = newShaker(PartyMemberFrame2PetFramePortrait),
        partypet3 = newShaker(PartyMemberFrame3PetFramePortrait),
        partypet4 = newShaker(PartyMemberFrame4PetFramePortrait)
    };
	this:RegisterEvent("UNIT_COMBAT");
	this:RegisterEvent("PLAYER_TARGET_CHANGED");
end

function PortraitShake_OnEvent(event)
    if ( event == "UNIT_COMBAT" ) then
        local unit, evt, flags, amount, type = arg1, arg2, arg3, arg4, arg5;
        --REPL_Log(unit, evt, flags, amount, type);
        -- evt one of [IMMUNE, WOUND, BLOCK, HEAL, ENERGIZE, MISS, ??]
        -- flags one of [CRITICAL, CRUSHING, GLANCING, ABSORB, BLOCK, RESIST, ??]
        if ( evt == "WOUND" and amount ~= 0 ) then
            local importance = min(1.0, amount / UnitHealthMax(unit) / 0.05); -- 5% of health for peak importance
            for unitId, shaker in pairs(shakers) do
                if ( UnitIsUnit(unit, unitId) ) then
                    shaker:shake(importance);
                end
            end
        end
    elseif ( event == "PLAYER_TARGET_CHANGED" ) then
        -- Target changed, so update TargetPortrait shaking
        -- If the new target is a party member, inherit their amplitude
        local amplitude = 0; -- If not a party member, reset shaking
        for unitId, shaker in pairs(shakers) do
            if ( unitId ~= "target" and UnitIsUnit(unitId, "target") ) then
                amplitude = shaker.amplitude;
            end
        end
        -- Minimum of 0.001 to force at least one position update
        shakers.target.amplitude = max(0.001, amplitude);
        shakers.target.t = 0.0;
    end
end

function PortraitShake_OnUpdate(elapsed)
    for unitId in shakers do
        shakers[unitId]:update(elapsed);
    end
end
