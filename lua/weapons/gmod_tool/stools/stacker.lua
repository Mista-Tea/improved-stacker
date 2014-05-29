--[[--------------------------------------------------------------------------
	Improved Stacker
	
	File name:
		stacker.lua
		
	Author:
		Original              - OverloadUT
		Updated for GMod 13   - Marii
		Cleaned and optimized - Mista Tea
		
	Changelog:
		- Added to GitHub May 27th, 2014
		- Added to Workshop May 28th, 2014
		
		Fixes:
			- Prevents crash from players using very high X/Y/Z offset values.
			- Prevents crash from players using very high P/Y/R rotate values.
			- Fixed the halo option for ghosted props not working.
		Tweaks:
			- Added convenience functions to retrieve the client convars.
			- Added option to enable/disable automatically applying materials to the stacked props.
			- Added option to enable/disable automatically applying colors to the stacked props.
			- Added console variables for server operators to limit various parts of stacker.
				> stacker_max_count
				> stacker_max_offsetx
				> stacker_max_offsety
				> stacker_max_offsetz
			- Added console commands for server admins to control the console variables that limit stacker.
				> stacker_set_maxcount #
				> stacker_set_maxoffset #
				> stacker_set_maxoffsetx #
				> stacker_set_maxoffsety #
				> stacker_set_maxoffsetz #

----------------------------------------------------------------------------]]

--[[--------------------------------------------------------------------------
-- Localized Functions & Variables
--------------------------------------------------------------------------]]--

-- localizing globals is an encouraged practice that inproves code efficiency,
-- accessing a local value is considerably faster than a global value
local net = net
local bit = bit
local util = util
local math = math
local undo = undo
local halo = halo
local game = game
local ents = ents
local pairs = pairs 
local table = table
local Angle = Angle
local Color = Color
local Vector = Vector
local IsValid = IsValid
local language = language
local tonumber = tonumber
local constraint = constraint
local concommand = concommand
local CreateConVar = CreateConVar
local GetConVarNumber = GetConVarNumber
local RunConsoleCommand = RunConsoleCommand

local MOVETYPE_NONE = MOVETYPE_NONE
local SOLID_VPHYSICS = SOLID_VPHYSICS
local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA

--[[--------------------------------------------------------------------------
-- Tool Settings
--------------------------------------------------------------------------]]--

TOOL.Category   = "Construction"
TOOL.Name       = "#Tool.stacker.name"
TOOL.Command    = nil
TOOL.ConfigName = ""

TOOL.ClientConVar[ "mode" ]      = "1"
TOOL.ClientConVar[ "dir" ]       = "1"
TOOL.ClientConVar[ "count" ]     = "1"
TOOL.ClientConVar[ "freeze" ]    = "1"
TOOL.ClientConVar[ "weld" ]      = "1"
TOOL.ClientConVar[ "nocollide" ] = "1"
TOOL.ClientConVar[ "ghostall" ]  = "1"
TOOL.ClientConVar[ "material" ]  = "1"
TOOL.ClientConVar[ "color" ]     = "1"
TOOL.ClientConVar[ "model" ]     = ""
TOOL.ClientConVar[ "offsetx" ]   = "0"
TOOL.ClientConVar[ "offsety" ]   = "0"
TOOL.ClientConVar[ "offsetz" ]   = "0"
TOOL.ClientConVar[ "rotp" ]      = "0"
TOOL.ClientConVar[ "roty" ]      = "0"
TOOL.ClientConVar[ "rotr" ]      = "0"
TOOL.ClientConVar[ "recalc" ]    = "0"
TOOL.ClientConVar[ "halo" ]      = "0"
TOOL.ClientConVar[ "halo_r" ]    = "0"
TOOL.ClientConVar[ "halo_g" ]    = "200"
TOOL.ClientConVar[ "halo_b" ]    = "190"
TOOL.ClientConVar[ "halo_a" ]    = "255"

if ( CLIENT ) then

	language.Add( "Tool.stacker.name", "Stacker" )
	language.Add( "Tool.stacker.desc", "Allows you to easily stack props" )
	language.Add( "Tool.stacker.0",    "Click to stack the prop you're pointing at." )
	language.Add( "Undone_stacker",    "Undone stacked prop(s)" )
	
end

--[[--------------------------------------------------------------------------
-- Enumerations
--------------------------------------------------------------------------]]--

local MODE_WORLD = 1 -- stacking relative to the world
local MODE_PROP  = 2 -- stacking relative to the prop

local DIRECTION_UP     = 1
local DIRECTION_DOWN   = 2
local DIRECTION_FRONT  = 3
local DIRECTION_BEHIND = 4
local DIRECTION_RIGHT  = 5
local DIRECTION_LEFT   = 6

--[[--------------------------------------------------------------------------
-- Console Variables
--------------------------------------------------------------------------]]--

CreateConVar( "stacker_max_count",    "30", bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ) ) -- defines the max amount of props that can be stacked at a time
CreateConVar( "stacker_max_offsetx", "500", bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ) ) -- defines the max distance on the x plane that stacked props can be offset (for individual control)
CreateConVar( "stacker_max_offsety", "500", bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ) ) -- defines the max distance on the y plane that stacked props can be offset (for individual control)
CreateConVar( "stacker_max_offsetz", "500", bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ) ) -- defines the max distance on the z plane that stacked props can be offset (for individual control)

--[[--------------------------------------------------------------------------
-- Console Commands
--------------------------------------------------------------------------]]--

if ( CLIENT ) then
	
	local function ResetOffsets( ply, command, arguments )
		-- Reset all of the offset options to 0
		LocalPlayer():ConCommand( "stacker_offsetx 0\n" )
		LocalPlayer():ConCommand( "stacker_offsety 0\n" )
		LocalPlayer():ConCommand( "stacker_offsetz 0\n" )
		LocalPlayer():ConCommand( "stacker_rotp 0\n" )
		LocalPlayer():ConCommand( "stacker_roty 0\n" )
		LocalPlayer():ConCommand( "stacker_rotr 0\n" )
		LocalPlayer():ConCommand( "stacker_recalc 1\n" )
		LocalPlayer():ConCommand( "stacker_ghostall 1\n" )
		LocalPlayer():ConCommand( "stacker_material 1\n" )
		LocalPlayer():ConCommand( "stacker_color 1\n" )
		LocalPlayer():ConCommand( "stacker_halo 1\n" )
	end
	concommand.Add( "stacker_resetoffsets", ResetOffsets )
	
elseif ( SERVER ) then

	local function ValidateCommand( ply, arg )
		if ( IsValid( ply ) and !ply:IsAdmin() ) then return false end
		local count = tonumber( arg )
		if ( !count or count < 0 ) then return false end
		return true
	end
	
	concommand.Add( "stacker_set_maxcount", function( ply, cmd, args )		
		if ( !ValidateCommand( ply, args[1] ) ) then return false end
		
		RunConsoleCommand( "stacker_max_count", args[1] )
	end )

	concommand.Add( "stacker_set_maxoffset", function( ply, cmd, args )
		if ( !ValidateCommand( ply, args[1] ) ) then return false end
		
		RunConsoleCommand( "stacker_max_offsetx", args[1] )
		RunConsoleCommand( "stacker_max_offsety", args[1] )
		RunConsoleCommand( "stacker_max_offsetz", args[1] )
	end )

	concommand.Add( "stacker_set_maxoffsetx", function( ply, cmd, args )
		if ( !ValidateCommand( ply, args[1] ) ) then return false end
		
		RunConsoleCommand( "stacker_max_offsetx", args[1] )
	end )

	concommand.Add( "stacker_set_maxoffsety", function( ply, cmd, args )
		if ( !ValidateCommand( ply, args[1] ) ) then return false end
		
		RunConsoleCommand( "stacker_max_offsety", args[1] )
	end )

	concommand.Add( "stacker_set_maxoffsetz", function( ply, cmd, args )
		if ( !ValidateCommand( ply, args[1] ) ) then return false end
		
		RunConsoleCommand( "stacker_max_offsetz", args[1] )
	end )
	
	concommand.Add( "test", function( ply, cmd, args )
		RunConsoleCommand( "stacker_max_offsetx", args[1] )
	end )
end

--[[--------------------------------------------------------------------------
-- Convenience Functions
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
-- 	TOOL:GetCount()
--
--	Gets the maximum amount of props that can be stacked at a time
--]]--
function TOOL:GetCount() 
	return math.Clamp( self:GetClientNumber( "count" ), 0, GetConVarNumber( "stacker_max_count" ) ) 
end

--[[--------------------------------------------------------------------------
-- 	TOOL:GetDirection()
--
--	Gets the direction to stack the props
--]]--
function TOOL:GetDirection() return self:GetClientNumber( "dir" ) end

--[[--------------------------------------------------------------------------
-- 	TOOL:GetStackerMode()
--
--	Gets the stacker mode (1 = MODE_WORLD, 2 = MODE_PROP)
--]]--
function TOOL:GetStackerMode() return self:GetClientNumber( "mode" ) end

--[[--------------------------------------------------------------------------
-- 	TOOL:GetOffsetX(), TOOL:GetOffsetY(), TOOL:GetOffsetZ(), TOOL:GetOffsetVector()
--
--	Gets the distance to offset the position of the stacked props.
--	These values are clamped to prevent server crashes from players
--	using very high offset values.
--]]--
function TOOL:GetOffsetX() return math.Clamp( self:GetClientNumber( "offsetx" ), - GetConVarNumber( "stacker_max_offsetx" ), GetConVarNumber( "stacker_max_offsetx" ) ) end
function TOOL:GetOffsetY() return math.Clamp( self:GetClientNumber( "offsety" ), - GetConVarNumber( "stacker_max_offsety" ), GetConVarNumber( "stacker_max_offsety" ) ) end
function TOOL:GetOffsetZ() return math.Clamp( self:GetClientNumber( "offsetz" ), - GetConVarNumber( "stacker_max_offsetz" ), GetConVarNumber( "stacker_max_offsetz" ) ) end

function TOOL:GetOffsetVector() return Vector( self:GetOffsetX(), self:GetOffsetY(), self:GetOffsetZ() ) end

--[[--------------------------------------------------------------------------
-- 	TOOL:GetRotateP(), TOOL:GetRotateY(), TOOL:GetRotateR(), TOOL:GetRotateAngle()
--
--	Gets the value to rotate the angle of the stacked props.
--	These values are clamped to prevent server crashes from players
--	using very high rotation values.
--]]--
function TOOL:GetRotateP() return math.Clamp( self:GetClientNumber( "rotp" ), -360, 360 ) end
function TOOL:GetRotateY() return math.Clamp( self:GetClientNumber( "roty" ), -360, 360 ) end
function TOOL:GetRotateR() return math.Clamp( self:GetClientNumber( "rotr" ), -360, 360 ) end

function TOOL:GetRotateAngle() return Angle( self:GetRotateP(), self:GetRotateY(), self:GetRotateR() ) end

--[[--------------------------------------------------------------------------
-- 	TOOL:GetGhostStack(), TOOL:SetGhostStack( table )
--
--	Gets and sets the table of ghosted props in the stack.
--]]--
function TOOL:GetGhostStack() return self.GhostStack end

function TOOL:SetGhostStack( tbl ) self.GhostStack = tbl end

--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldFreeze()
--
--	Returns true if the stacked props should be spawned frozen.
--]]--
function TOOL:ShouldFreeze() return self:GetClientNumber( "freeze" ) == 1 end
--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldWeld()
--
--	Returns true if the stacked props should be welded together.
--]]--
function TOOL:ShouldWeld() return self:GetClientNumber( "weld" ) == 1 end
--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldNoCollide()
--
--	Returns true if the stacked props should be nocollided with each other.
--]]--
function TOOL:ShouldNoCollide() return self:GetClientNumber( "nocollide" ) == 1 end
--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldStackRelative()
--
--	Returns true if the stacked props should be stacked relative to the new rotation.
--	Using this setting will allow you to create curved structures out of props.
--]]--
function TOOL:ShouldStackRelative() return self:GetClientNumber( "recalc" ) == 1 end
--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldGhostAll()
--
--	Returns true if the stacked props should all be ghosted or if only the 
--	first stacked prop should be ghosted.
--]]--
function TOOL:ShouldGhostAll() return self:GetClientNumber( "ghostall" ) == 1 end

--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldAddHalos(), TOOL:GetHaloR(), TOOL:GetHaloG(), TOOL:GetHaloB() TOOL:GetHaloA() TOOL:GetHaloColor()
--
--	Returns true if the stacked props should have halos drawn on them for added visibility.
--	Gets the RGBA values of the halo color.
--]]--
function TOOL:ShouldAddHalos() return self:GetClientNumber( "halo" ) == 1 end

function TOOL:GetHaloR() return math.Clamp( self:GetClientNumber( "halo_r" ), 0, 255 ) end
function TOOL:GetHaloG() return math.Clamp( self:GetClientNumber( "halo_g" ), 0, 255 ) end
function TOOL:GetHaloB() return math.Clamp( self:GetClientNumber( "halo_b" ), 0, 255 ) end
function TOOL:GetHaloA() return math.Clamp( self:GetClientNumber( "halo_a" ), 0, 255 ) end

function TOOL:GetHaloColor()
	return Color( self:GetHaloR(), self:GetHaloG(), self:GetHaloB(), self:GetHaloA() )
end

--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldApplyMaterial()
--
--	Returns true if the stacked props should have the original prop's material applied.
--]]--
function TOOL:ShouldApplyMaterial() return self:GetClientNumber( "material" ) == 1 end

--[[--------------------------------------------------------------------------
-- 	TOOL:ShouldApplyColor()
--
--	Returns true if the stacked props should have the original prop's color applied.
--]]--
function TOOL:ShouldApplyColor() return self:GetClientNumber( "color" ) == 1 end


--[[--------------------------------------------------------------------------
-- Tool Functions
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--
-- 	 TOOL:Holster()
--
--	Called when the player switches to a different weapon or tool.
--]]--
function TOOL:Holster()
	self:ReleaseGhostStack()
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL:Init()
--
--	Creates two net message receivers on the client that control the stack
--	of ghosted props.
--]]--
function TOOL:Init()
	if ( SERVER ) then	
		util.AddNetworkString( "Stacker.StackGhost" )
		util.AddNetworkString( "Stacker.UnstackGhost" )	
	elseif ( CLIENT ) then
		net.Receive( "Stacker.StackGhost", function( bits )
			self:SetGhostStack( net.ReadTable() )
		end )

		net.Receive( "Stacker.UnstackGhost", function( bits )
			if ( !self:GetGhostStack() ) then return end
			table.Empty( self:GetGhostStack() )
		end )		
	end
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL:LeftClick( table )
--
--	Attempts to create a stack of props relative to the entity being left clicked.
--]]--
function TOOL:LeftClick( trace )
	if ( !IsValid( trace.Entity ) or trace.Entity:GetClass() ~= "prop_physics" ) then return false end
	if ( CLIENT ) then return true end
	
	local count = self:GetCount()
	
	if ( count <= 0 ) then return false end

	local dir       = self:GetDirection()
	local mode      = self:GetStackerMode()
	local offset    = self:GetOffsetVector()
	local rotate    = self:GetRotateAngle()
	
	local applyFreeze    = self:ShouldFreeze()
	local applyWeld      = self:ShouldWeld()
	local applyNoCollide = self:ShouldNoCollide()
	local stackRelative  = self:ShouldStackRelative()
	
	local applyMaterial  = self:ShouldApplyMaterial()
	local applyColor     = self:ShouldApplyColor()

	local ply = self:GetOwner()
	local ent = trace.Entity

	local entPos  = ent:GetPos()
	local entAng  = ent:GetAngles()
	local entSkin = ent:GetSkin()
	local entMat  = ent:GetMaterial()
	local entCol  = ent:GetColor()
	
	local lastEnt = ent
	local newEnt
	
	undo.Create( "stacker" )
	
	for i = 1, count, 1 do
		if ( !self:GetSWEP():CheckLimit( "props" ) ) then break end

		if ( i == 1 or ( mode == MODE_PROP and stackRelative ) ) then
			stackdir, height, thisoffset = self:StackerCalcPos( lastEnt, mode, dir, offset )
		end
		
		entPos = entPos + stackdir * height + thisoffset
		entAng = entAng + rotate

		newEnt = ents.Create( "prop_physics" )
		
		newEnt["IsFromStacker"] = true -- this is for external prop protections or anti-spam addons
		
		newEnt:SetModel( ent:GetModel() )
		newEnt:SetPos( entPos )
		newEnt:SetAngles( entAng )
		newEnt:SetSkin( entSkin )
		if ( applyMaterial ) then newEnt:SetMaterial( entMat ) end
		if ( applyColor )    then newEnt:SetColor( entCol )    end
		newEnt:Spawn()
		
		if ( applyFreeze ) then
			--ply:AddFrozenPhysicsObject( newEnt, newEnt:GetPhysicsObject() ) -- fix so you can mass-unfreeze
			newEnt:GetPhysicsObject():EnableMotion( false )
		else
			newEnt:GetPhysicsObject():Wake()
		end

		if ( applyWeld )      then undo.AddEntity( constraint.Weld( lastEnt, newEnt, 0, 0, 0 ) ) end
		if ( applyNoCollide ) then undo.AddEntity( constraint.NoCollide( lastEnt, newEnt, 0, 0 ) ) end
		
		lastEnt = newEnt
		
		undo.AddEntity( newEnt )
		ply:AddCount( "props", newEnt )
		ply:AddCleanup( "props", newEnt )
	end
	
	undo.SetPlayer( ply )
	undo.Finish()

	return true
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL:StackerCalcPos( entity, number, number, number )
--
--	Calculates the positions and angles of the entity being created in the stack.
--	This function uses a lookup table for added optimization as opposed to an if-else block.
--]]--
local CALC_POS = {
	[MODE_WORLD] = {
		[DIRECTION_UP]     = function( forward, upper, lower ) return forward:Up(),           math.abs( upper.z - lower.z ) end,
		[DIRECTION_DOWN]   = function( forward, upper, lower ) return forward:Up() * -1,      math.abs( upper.z - lower.z ) end,
		[DIRECTION_FRONT]  = function( forward, upper, lower ) return forward:Forward(),      math.abs( upper.x - lower.x ) end,
		[DIRECTION_BEHIND] = function( forward, upper, lower ) return forward:Forward() * -1, math.abs( upper.x - lower.x ) end,
		[DIRECTION_RIGHT]  = function( forward, upper, lower ) return forward:Right(),        math.abs( upper.y - lower.y ) end,
		[DIRECTION_LEFT]   = function( forward, upper, lower ) return forward:Right() * -1,   math.abs( upper.y - lower.y ) end,
	},
	
	[MODE_PROP] = {
		[DIRECTION_UP]     = function( forward, offset, gupper, glower ) return forward:Up(),           math.abs( gupper.z - glower.z ), forward:Up() * offset.X + forward:Forward() * -1 * offset.Z + forward:Right() * offset.Y      end,
		[DIRECTION_DOWN]   = function( forward, offset, gupper, glower ) return forward:Up() * -1,      math.abs( gupper.z - glower.z ), forward:Up() * -1 * offset.X + forward:Forward() * offset.Z + forward:Right() * offset.Y      end,
		[DIRECTION_FRONT]  = function( forward, offset, gupper, glower ) return forward:Forward(),      math.abs( gupper.x - glower.x ), forward:Forward() * offset.X + forward:Up() * offset.Z + forward:Right() * offset.Y           end,
		[DIRECTION_BEHIND] = function( forward, offset, gupper, glower ) return forward:Forward() * -1, math.abs( gupper.x - glower.x ), forward:Forward() * -1 * offset.X + forward:Up() * offset.Z + forward:Right() * -1 * offset.Y end,
		[DIRECTION_RIGHT]  = function( forward, offset, gupper, glower ) return forward:Right(),        math.abs( gupper.y - glower.y ), forward:Right() * offset.X + forward:Up() * offset.Z + forward:Forward() * -1 * offset.Y      end,
		[DIRECTION_LEFT]   = function( forward, offset, gupper, glower ) return forward:Right() * -1,   math.abs( gupper.y - glower.y ), forward:Right() * -1 * offset.X + forward:Up() * offset.Z + forward:Forward() * offset.Y      end,
	},
}

local VECX = Vector( 1, 0, 0 )
local VECZ = Vector( 0, 0, 1 )

function TOOL:StackerCalcPos( ent, mode, dir, offset )
	local forward = VECX:Angle()
	local entAng = ent:GetAngles()

	local lower  = ent:WorldSpaceAABB()
	local upper  = ent:WorldSpaceAABB()
	local glower = ent:OBBMins()
	local gupper = ent:OBBMaxs()
	
	local stackdir = VECZ
	local height = math.abs( upper.z - lower.z )
	
	if ( mode == MODE_WORLD ) then -- get the position relative to the world's directions
	
		stackdir, height = CALC_POS[ mode ][ dir ]( forward, upper, lower )
		
	elseif ( mode == MODE_PROP ) then -- get the position relative to the prop's directions
	
		stackdir, height, offset = CALC_POS[ mode ][ dir ]( entAng, offset, gupper, glower )
		
	end
	
	return stackdir, height, offset
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL:UpdateGhostStack( entity )
--
--	Attempts to update the positions and angles of all ghosted props in the stack.
--]]--
function TOOL:UpdateGhostStack( ent )
	if ( !IsValid( ent ) or !self:CheckGhostStack() ) then return end
	
	local count 	= self:GetCount()
	local mode	= self:GetStackerMode()
	local dir	= self:GetDirection()
	local offset	= self:GetOffsetVector()
	local rotate	= self:GetRotateAngle()
	local recalc	= self:ShouldStackRelative()

	local newEnt = ent
	local entPos = newEnt:GetPos()
	local entAng = newEnt:GetAngles()
	
	local stackdir, height, thisoffset
	
	for k,v in pairs( self:GetGhostStack() ) do
		if ( k == 1 or ( mode == MODE_PROP and recalc ) ) then
			stackdir, height, thisoffset = self:StackerCalcPos( newEnt, mode, dir, offset )
		end

		entPos = entPos + stackdir * height + thisoffset
		entAng = entAng + rotate

		v:SetAngles( entAng )
		v:SetPos( entPos )
		v:SetNoDraw( false )
		newEnt = v
	end
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL:CheckGhostStack()
--
--	Attempts to validate the status of the ghosted props in the stack.
--]]--
function TOOL:CheckGhostStack()
	local ghoststack = self:GetGhostStack()
	if ( !ghoststack ) then return false end
	
	local count = self:GetCount()
	local ghostAll = self:ShouldGhostAll()
	
	for k, v in pairs( ghoststack ) do
		if ( !IsValid( v ) ) then
			return false
		end
	end
	
	if     ( #ghoststack ~= count and ghostAll )  then return false
	elseif ( #ghoststack ~= 1     and !ghostAll ) then return false end
	return true
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL:CreateGhostStack( entity, vector, angle )
--
--	Attempts to create a stack of ghosted props on the prop the player is currently
--	looking at before they actually left click to create the stack. This acts
--	as a visual aid for the player so they can see the results without actually creating
--	the entities yet (if in multiplayer).
--]]--
local TRANSPARENT = Color( 255, 255, 255, 150 )

function TOOL:CreateGhostStack( ent, pos, ang )
	if ( self:GetGhostStack() ) then self:ReleaseGhostStack() end
	local ghoststack = {}

	if ( SERVER and !game.SinglePlayer() ) then return false; end
	if ( CLIENT and game.SinglePlayer() )  then return false; end
	
	local count         = self:GetCount()
	local addHalos      = self:ShouldAddHalos()
	local ghostAll      = self:ShouldGhostAll()
	
	local applyMaterial = self:ShouldApplyMaterial()
	local applyColor    = self:ShouldApplyColor()
	
	local entMod  = ent:GetModel()
	local entSkin = ent:GetSkin()
	local entMat  = ent:GetMaterial() or ""
	local entCol  = ent:GetColor() or TRANSPARENT
	
	entCol.a = 150
	
	if ( !ghostAll and count ~= 0 ) then
		count = 1
	end

	for i = 1, count, 1 do
		local ghost

		if ( CLIENT ) then ghost = ents.CreateClientProp( entMod )
		else               ghost = ents.Create( "prop_physics" ) end
		
		if ( !IsValid( ghost ) ) then ghost = nil continue end

		ghost:SetModel( entMod )
		ghost:SetPos( pos )
		ghost:SetAngles( ang )
		ghost:Spawn()

		ghost:SetSolid( SOLID_VPHYSICS )
		ghost:SetMoveType( MOVETYPE_NONE )
		ghost:SetRenderMode( RENDERMODE_TRANSALPHA )
		ghost:SetNotSolid( true )
		ghost:SetSkin( entSkin )
		ghost:SetMaterial( ( applyMaterial and entMat ) or "" )
		ghost:SetColor( ( applyColor and entCol ) or TRANSPARENT )
		
		table.insert( ghoststack, ghost )
	end
	
	if ( SERVER and addHalos ) then
		net.Start( "Stacker.StackGhost" )
			net.WriteTable( ghoststack )
		net.Send( self:GetOwner() )
	end
	
	self:SetGhostStack( ghoststack )
	
	return true
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL:ReleaseGhostStack()
--	
--	Attempts to remove all ghosted props in the stack on the server (if singleplayer)
--	or on the client (in multiplayer). This occurs when the player stops looking at
--	a prop with the stacker tool equipped.
--]]--
function TOOL:ReleaseGhostStack()
	local ghoststack = self:GetGhostStack()
	if ( !ghoststack ) then return end
	
	for k,v in pairs( ghoststack ) do
		if ( !IsValid( v ) ) then continue end
		v:Remove()
	end
	
	if ( SERVER ) then 
		net.Start( "Stacker.UnstackGhost" )
		net.Send( self:GetOwner() )
	end
	
	table.Empty( ghoststack )
end

--[[--------------------------------------------------------------------------
--
--	TOOL:Think()
--
--	While the stacker tool is equipped, this function will check to see if
--	the player is looking at any props and attempt to create the stack of
--	ghosted props before the players actually left clicks.
--]]--
local VEC = Vector( 0, 0, 0 )
local ANG =  Angle( 0, 0, 0 )
local HaloColor = Color( 181, 0, 217 )

function TOOL:Think()
	local ply        = self:GetOwner()
	local trace      = ply:GetEyeTrace()
	local traceValid = IsValid( trace.Entity )
	
	if ( traceValid and trace.Entity:GetClass() == "prop_physics" ) then
		self.NewEnt = trace.Entity

		if ( self.NewEnt ~= self.LastEnt ) then
			if ( self:CreateGhostStack( self.NewEnt, VEC, ANG ) ) then self.LastEnt = self.NewEnt end
		end
		if ( !self:CheckGhostStack() ) then
			self:ReleaseGhostStack()
			self.LastEnt = nil
		end
	else
		self:ReleaseGhostStack()
		self.LastEnt = nil
	end
	
	if ( IsValid( self.LastEnt ) ) then
		self:UpdateGhostStack( self.LastEnt )
	end
	
	if ( CLIENT ) then
		if ( !self:ShouldAddHalos() ) then return end
		
		local ghoststack = self:GetGhostStack()
		if ( !ghoststack or #ghoststack <= 0 ) then return end

		halo.Add( ghoststack, self:GetHaloColor() )
	end
end

--[[--------------------------------------------------------------------------
--
-- 	TOOL.BuildCPanel( panel )
--
--	Builds the control panel menu that can be seen when holding Q and accessing
--	the stacker menu.
--]]--
function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", { Text = "#Tool.stacker.name", Description	= "#Tool.stacker.desc" } )
	
	CPanel:AddControl( "Checkbox", { Label = "Freeze Props",     Command = "stacker_freeze" } )
	CPanel:AddControl( "Checkbox", { Label = "Weld Props",       Command = "stacker_weld" } )
	CPanel:AddControl( "Checkbox", { Label = "No Collide Props", Command = "stacker_nocollide" } )

	local params = { Label = "Relative To:", MenuButton = "0", Options = {} }
	params.Options[ "World" ] = { stacker_mode = "1" }
	params.Options[ "Prop" ]  = { stacker_mode = "2" }
	CPanel:AddControl( "ComboBox", params )

	local params = { Label = "Stack Direction", MenuButton = "0", Options = {} }
	params.Options[ "Up" ]     = { stacker_dir = "1" }
	params.Options[ "Down" ]   = { stacker_dir = "2" }
	params.Options[ "Front" ]  = { stacker_dir = "3" }
	params.Options[ "Behind" ] = { stacker_dir = "4" }
	params.Options[ "Right" ]  = { stacker_dir = "5" }
	params.Options[ "Left" ]   = { stacker_dir = "6" }
	CPanel:AddControl( "ComboBox", params )

	CPanel:AddControl( "Slider", { Label = "Count",Type = "Integer", Min = 1, Max = GetConVarNumber( "stacker_max_count" ), Command = "stacker_count", Description = "How many props to stack." } )

	CPanel:AddControl( "Header", { Text = "Advanced Options", Description = "These options are for advanced users. Leave them all default ( 0 ) if you don't understand what they do." }  )
	CPanel:AddControl( "Button", { Label = "Reset Advanced Options", Command = "stacker_resetoffsets", Text = "Reset" } )
	
	CPanel:AddControl( "Slider", { Label = "Offset X ( forward/back )", Type = "Float", Min = - GetConVarNumber( "stacker_max_offsetx" ), Max = GetConVarNumber( "stacker_max_offsetx" ), Value = 0, Command = "stacker_offsetx" } )
	CPanel:AddControl( "Slider", { Label = "Offset Y ( right/left )",   Type = "Float", Min = - GetConVarNumber( "stacker_max_offsety" ), Max = GetConVarNumber( "stacker_max_offsety" ), Value = 0, Command = "stacker_offsety" } )
	CPanel:AddControl( "Slider", { Label = "Offset Z ( up/down )",      Type = "Float", Min = - GetConVarNumber( "stacker_max_offsetz" ), Max = GetConVarNumber( "stacker_max_offsetz" ), Value = 0, Command = "stacker_offsetz" } )
	CPanel:AddControl( "Slider", { Label = "Rotate Pitch",              Type = "Float", Min = -360,  Max = 360,  Value = 0, Command = "stacker_rotp" } )
	CPanel:AddControl( "Slider", { Label = "Rotate Yaw",                Type = "Float", Min = -360,  Max = 360,  Value = 0, Command = "stacker_roty" } )
	CPanel:AddControl( "Slider", { Label = "Rotate Roll",               Type = "Float", Min = -360,  Max = 360,  Value = 0, Command = "stacker_rotr" } )
	
	CPanel:AddControl( "Checkbox", { Label = "Stack props relative to new rotation", Command = "stacker_recalc",    Description = "If this is checked, each item in the stack will be stacked relative to the previous item in the stack. This allows you to create curved stacks." } )
	CPanel:AddControl( "Checkbox", { Label = "Ghost all of the props in the stack",  Command = "stacker_ghostall",  Description = "Creates every ghost prop in the stack instead of just the first ghost prop" } )
	CPanel:AddControl( "Checkbox", { Label = "Apply material to the stacked props",  Command = "stacker_material",  Description = "Applies the material of the original prop to all stacked props" } )
	CPanel:AddControl( "Checkbox", { Label = "Apply color to the stacked props",     Command = "stacker_color",     Description = "Applies the color of the original prop to all stacked props" } )
	CPanel:AddControl( "Checkbox", { Label = "Add halos to the ghost props",         Command = "stacker_halo",      Description = "Give the ghost a halo" } )
	CPanel:AddControl( "Color", { Label = "Halo color", Red = "stacker_halo_r", Green = "stacker_halo_g", Blue = "stacker_halo_b", Alpha = "stacker_halo_a" } )
end
