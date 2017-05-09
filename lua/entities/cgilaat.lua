ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "LAAT/i"
ENT.Author = "Liam / Cody"
ENT.Category = "Clone Wars"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/props/laat/laat.mdl"
ENT.Vehicle = "CGILAAT"
ENT.StartHealth = 4000;
ENT.Allegiance = "Republic";

if SERVER then

ENT.FireSound = Sound("weapons/xwing_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("cgilaat");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetForward()*360+self:GetUp()*25+self:GetRight()*38,
		Left = self:GetPos()+self:GetForward()*360+self:GetUp()*25+self:GetRight()*-38,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1000;
	self.ForwardSpeed = 1000;
	self.UpSpeed = 500;
	self.AccelSpeed = 7;
	self.CanBack = false;
    self.CanRoll = false;
    self.CanStrafe = true;
	self.CanShoot = true;
	self.AlternateFire = true;
	self.FireGroup = {"Right","Left"}
	self.HasWings = true;
	self.Cooldown = 2;
	self.Overheat = 0;
	self.Overheated = false;
	
	self.Bullet = CreateBulletStructure(70,"blue");
	self.FireDelay = 0.15;
	
	self.SeatPos = {
	
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5,self:GetAngles()+Angle(0,180,0)},
		
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5+self:GetForward()*-20, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5+self:GetForward()*-20, self:GetAngles()+Angle(0,180,0)},
		
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5+self:GetForward()*-40, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5+self:GetForward()*-40, self:GetAngles()+Angle(0,180,0)},
		
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5+self:GetForward()*-60, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5+self:GetForward()*-60, self:GetAngles()+Angle(0,180,0)},
		
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5+self:GetForward()*-80, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5+self:GetForward()*-80, self:GetAngles()+Angle(0,180,0)},
		
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5+self:GetForward()*20, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5+self:GetForward()*20, self:GetAngles()+Angle(0,180,0)},
		
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5+self:GetForward()*40, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5+self:GetForward()*40, self:GetAngles()+Angle(0,180,0)},
		
		{self:GetPos()+self:GetUp()*1+self:GetRight()*-17.5+self:GetForward()*60, self:GetAngles()},
		{self:GetPos()+self:GetUp()*1+self:GetRight()*17.5+self:GetForward()*60, self:GetAngles()+Angle(0,180,0)},
		
	};
	
	self:SpawnSeats();
	self.ExitModifier = {x=0,y=87.5,z=20};

	self.PilotVisible = true;
	self.PilotPosition = {x=0,y=192,z=123};

	self.HasLookaround = true;
	self.BaseClass.Initialize(self);
end


function ENT:SpawnSeats()
	self.Seats = {};
	for k,v in pairs(self.SeatPos) do
		local e = ents.Create("prop_vehicle_prisoner_pod");
		e:SetPos(v[1]);
		e:SetAngles(v[2]);
		e:SetParent(self);		
		e:SetModel("models/nova/airboat_seat.mdl");
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetColor(Color(255,255,255,0));	
		e:Spawn();
		e:Activate();
		e:SetVehicleClass("sypha_seat");
		e:SetUseType(USE_OFF);
		e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		//e:GetPhysicsObject():EnableCollisions(false);
		e.IsCGILAATSeat = true;
		e.CGILAAT = self;
		
		if(k % 2 > 0) then
			e.RightSide = true;
		else
			e.LeftSide = true;
		end
		
		self.Seats[k] = e;
	end

end

hook.Add("PlayerEnteredVehicle","CGILAATSeatEnter", function(p,v)
	if(IsValid(v) and IsValid(p)) then
		if(v.IsCGILAATSeat) then
			p:SetNetworkedEntity("CGILAATSeat",v);
			p:SetNetworkedEntity("CGILAAT",v:GetParent());
			p:SetNetworkedBool("CGILAATPassenger",true);
		end
	end
end);

hook.Add("PlayerLeaveVehicle", "CGILAATSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsCGILAATSeat) then
			local e = v.CGILAAT;
			if(IsValid(e)) then
				if(v.LeftSide) then
					p:SetPos(e:GetPos()+e:GetRight()*125+e:GetUp()*20+e:GetForward()*(-40+math.random(-50,50)));
				elseif(v.RightSide) then
					p:SetPos(e:GetPos()+e:GetRight()*-125+e:GetUp()*20+e:GetForward()*(-40+math.random(-50,50)));
				end
			end
			p:SetNetworkedEntity("CGILAATSeat",NULL);
			p:SetNetworkedEntity("CGILAAT",NULL);
			p:SetNetworkedBool("CGILAATPassenger",false);			
		end
	end
end);

function ENT:Passenger(p)
	if(self.NextUse.Use > CurTime()) then return end;
	for k,v in pairs(self.Seats) do
		if(v:GetPassenger(1) == NULL) then
			p:EnterVehicle(v);
			p:SetAllowWeaponsInVehicle( true )
			return;
		end
	end
end
 
function ENT:Use(p)
   if(not self.Inflight) then
       if(!p:KeyDown(IN_WALK)) then
           self:Enter(p);
       else
           self:Passenger(p);
       end
   else
       if(p != self.Pilot) then
           self:Passenger(p);
       end
   end
end

function ENT:ToggleWings()
 
    if(self.NextUse.Wings < CurTime()) then
        if(self.Wings) then
            self:SetBodygroup(1,0);
            self.Wings = false;
        else
            self:SetBodygroup(1,1);
            self.Wings = true;
        end
        self.NextUse.Wings = CurTime() + 1;
    end
end

end

if CLIENT then

	function ENT:Draw() self:DrawModel() end
	
	ENT.EnginePos = {}
	ENT.Sounds={
		//Engine=Sound("ambient/atmosphere/ambience_base.wav"),
		Engine=Sound("vehicles/laat/laat_fly2.wav"),
	}
	ENT.CanFPV = false;

	hook.Add("ScoreboardShow","CGILAATScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingCGILAAT");
		if(Flying) then
			return false;
		end
	end)
	
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local IsFlying = p:GetNWEntity("CGILAAT");
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		
		if(Flying) then
			self:FlightEffects();
			Health = self:GetNWInt("Health")
		end
		
	end
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingCGILAAT");
		local Sitting = p:GetNWBool("CGILAATPassenger");
		local pos, face;
		local self = p:GetNWEntity("CGILAAT");
	
		
		if(Flying) then
			if(IsValid(self)) then
				local fpvPos = self:GetPos()+self:GetUp()*155+self:GetForward()*210;
				View = SWVehicleView(self,950,400,fpvPos,true);		
				return View;
			end
		elseif(Sitting) then
			local v = p:GetNWEntity("CGILAATSeat");	
			if(IsValid(v)) then
				if(v:GetThirdPersonMode()) then
					View = SWVehicleView(self,800,350,fpvPos);		
					return View;
				end
			end
		end
		
	end
	hook.Add("CalcView", "CGILAATView", CalcView)
	
	hook.Add( "ShouldDrawLocalPlayer", "CGILAATDrawPlayerModel", function( p )
		local self = p:GetNWEntity("CGILAAT", NULL);
		local PassengerSeat = p:GetNWEntity("CGILAATSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward();
		local id = self:EntIndex();
		
		self.EnginePos = {
			self:GetPos()+self:GetUp()*85+self:GetRight()*0+self:GetForward()*-10,
			
			self:GetPos()+self:GetUp()*85+self:GetRight()*0+self:GetForward()*-80,
		}
		for k,v in pairs(self.EnginePos) do
				
			local blue = self.FXEmitter:Add("sprites/bluecore",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.025)
			blue:SetStartAlpha(1)
			blue:SetEndAlpha(0)
			blue:SetStartSize(3)
			blue:SetEndSize(1)
			blue:SetRoll(roll)
			blue:SetColor(255,0,0)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v;
			dynlight.Brightness = 6;
			dynlight.Size = 90;
			dynlight.Decay = 1024;
			dynlight.R = 255;
			dynlight.G = 20;
			dynlight.B = 20;
			dynlight.DieTime = CurTime()+1;
			
		end
	
	end

	function CGILAATReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingCGILAAT");
		local self = p:GetNWEntity("CGILAAT");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(4000);
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			
			local pos = self:GetPos()+self:GetForward()*240+self:GetUp()*147.5;
			local x,y = SW_XYIn3D(pos);
			
			SW_HUD_Compass(self,x,y);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "CGILAATReticle", CGILAATReticle)

end