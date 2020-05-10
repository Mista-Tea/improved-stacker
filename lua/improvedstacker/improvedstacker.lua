--[[--------------------------------------------------------------------------
	Improved Stacker Module
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (MIT)

		Copyright (c) 2014-2020 Mista-Tea

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
			
	Changelog:
----------------------------------------------------------------------------]]

local math = math
local hook = hook
local Angle = Angle
local Vector = Vector
local GetConVar = GetConVar
local duplicator = duplicator
local CreateConVar = CreateConVar

--[[--------------------------------------------------------------------------
-- 	Namespace Tables
--------------------------------------------------------------------------]]--

module( "improvedstacker", package.seeall )

--[[--------------------------------------------------------------------------
-- 	Localized Functions & Variables
--------------------------------------------------------------------------]]--

-- enums for determining stack relativity
MODE_WORLD = 1 -- stacking relative to the world
MODE_PROP  = 2 -- stacking relative to the prop

-- lookup table for validating relative values
Modes = {
	[MODE_WORLD] = true,
	[MODE_PROP]  = true,
}

-- enums for determining the direction to stack props
DIRECTION_FRONT = 1
DIRECTION_BACK  = 2
DIRECTION_RIGHT = 3
DIRECTION_LEFT  = 4
DIRECTION_UP    = 5
DIRECTION_DOWN  = 6

-- lookup table for validating direction values
Directions = {
	[DIRECTION_FRONT] = true,
	[DIRECTION_BACK]  = true,
	[DIRECTION_RIGHT] = true,
	[DIRECTION_LEFT]  = true,
	[DIRECTION_UP]    = true,
	[DIRECTION_DOWN]  = true,
}

-- constants used for when stacking relative to the World
ANGLE_ZERO   =  Angle( 0, 0, 0 )
VECTOR_FRONT  = ANGLE_ZERO:Forward()
VECTOR_RIGHT  = ANGLE_ZERO:Right()
VECTOR_UP     = ANGLE_ZERO:Up()
VECTOR_BACK   = -VECTOR_FRONT
VECTOR_LEFT   = -VECTOR_RIGHT
VECTOR_DOWN   = -VECTOR_UP

-- there has been a longstanding problem where stacked entities were an inch apart (figuratively), causing gaps everywhere.
-- as it turns out, fixing this issue is as easy as subtracting 0.5 from the forward component of the offset vector.
MAGIC_OFFSET = -0.5

--[[--------------------------------------------------------------------------
--	Namespace Functions
--------------------------------------------------------------------------]]--

if ( SERVER ) then
	
	-- the tables below are used internally and should only generally be interfaced with
	-- via the functions declared afterward.
	-- basically treat them as private, since they are only public for auto-refresh compatibility
	
	-- holds the current stacked entity count for every player
	m_EntCount  = m_EntCount  or {}
	-- holds the last stacker usage for every player
	m_StackTime = m_StackTime or {}
	-- holds every stacker entity created
	m_Ents      = m_Ents      or {}
		
	--[[--------------------------------------------------------------------------
	-- 	GetEntCount( player, number )
	--]]--
	function GetEntCount( ply, default )
		return m_EntCount[ ply:SteamID() ] or default
	end
	--[[--------------------------------------------------------------------------
	-- 	SetEntCount( player, number )
	--]]--
	function SetEntCount( ply, num )
		m_EntCount[ ply:SteamID() ] = num
	end
	--[[--------------------------------------------------------------------------
	-- 	IncrementEntCount( player, number )
	--]]--
	function IncrementEntCount( ply, num )
		m_EntCount[ ply:SteamID() ] = GetEntCount( ply, 0 ) + (num or 1)
	end
	--[[--------------------------------------------------------------------------
	-- 	DecrementEntCount( player, number )
	--]]--
	function DecrementEntCount( ply, num )
		m_EntCount[ ply:SteamID() ] = ( m_EntCount[ ply:SteamID() ] and m_EntCount[ ply:SteamID() ] - (num or 1) ) or 0
	end
	
	--[[--------------------------------------------------------------------------
	-- 	SetLastStackTime( player, number )
	--]]--
	function SetLastStackTime( ply, num )
		m_StackTime[ ply:SteamID() ] = num
	end
	--[[--------------------------------------------------------------------------
	-- 	GetLastStackTime( player, number )
	--]]--
	function GetLastStackTime( ply, default )
		return m_StackTime[ ply:SteamID() ] or default
	end
	
	--[[--------------------------------------------------------------------------
	--	Initialize( string )
	--
	--	This should be called immediately after including this file so that the follow
	--	variables/functions can use the stacker tool's mode (i.e., the name of the file itself
	--	and what is subsequently used in all of the cvars).
	--]]--
	function Initialize( mode )
		mode = mode or "stacker_improved"
		
		--[[--------------------------------------------------------------------------
		--  Hook :: PlayerInitialSpawn
		
		--	Sets the newly connected player's total stacker ents to 0.
		--	See TOOL:IsExceedingMax() for more details
		--]]--
		hook.Add( "PlayerInitialSpawn", mode.."_set_ent_count", function( ply )
			m_EntCount[ ply:SteamID() ] = 0
		end )
		--[[--------------------------------------------------------------------------
		--  Hook :: PlayerDisconnected
		--
		--	Removes the player from the table when they disconnect (for sanitation).
		--]]--
		hook.Add( "PlayerDisconnected", mode.."_remove_ent_count", function( ply )
			m_EntCount[ ply:SteamID() ] = nil
		end )
		
		--[[--------------------------------------------------------------------------
		-- 	MarkEntity( player, entity, table )
		--
		--	Marks the entity as a stacker entity. This allows the entity to be 
		--	collision-checked in GM.ShouldCollide.
		--]]--
		function MarkEntity( ply, ent, data )
			m_Ents[ ent ] = true
			duplicator.StoreEntityModifier( ent, mode, { StackerEnt = true } )
			ent:SetCustomCollisionCheck( true )
			
			-- when the entity is removed, sanitize our internal m_Ents array
			ent:CallOnRemove( mode, function( ent )
				ClearEntity( ent )
			end )
		end
		--duplicator.RegisterEntityModifier( mode, MarkEntity )
		--[[--------------------------------------------------------------------------
		-- 	ClearEntity( entity )
		--
		--	Removes the entity from the internal m_Ents array for sanitation purposes.
		--	This is called when an entity is just about to be removed.
		--]]--
		function ClearEntity( ent )
			if ( m_Ents[ ent ] ) then m_Ents[ ent ] = nil end
		end
		
		--[[--------------------------------------------------------------------------
		-- 	CanUnfreeze( player, entity, physObject )
		--]]--
		function CanUnfreeze( ply, ent, phys )
			if ( m_Ents[ ent ] ) then print("nope") return false end
		end
		--hook.Add( "CanPlayerUnfreeze", mode, CanUnfreeze )
		--hook.Add( "PhysgunPickup",     mode, CanUnfreeze )
		--hook.Remove( "CanPlayerUnfreeze", mode )
		--hook.Remove( "PhysgunPickup",     mode )
		
		local cvarNoCollideAll
		local cvarNoCollide
		--[[--------------------------------------------------------------------------
		-- 	ShouldCollide( entity, entity )
		--]]--
		function ShouldCollide( a, b )
			if ( not cvarNoCollideAll ) then cvarNoCollideAll = GetConVar( mode.."_force_nocollide_all" ) end
			if ( not cvarNoCollide )    then cvarNoCollide    = GetConVar( mode.."_force_nocollide" )     end
			
			if ( cvarNoCollideAll:GetBool() ) then
				if ( m_Ents[ a ] ) then
					if not ( b:IsPlayer() or b:IsWorld() or b:IsNPC() or b:IsVehicle() ) then return false end
				elseif ( m_Ents[ b ] ) then
					if not ( a:IsPlayer() or a:IsWorld() or b:IsNPC() or b:IsVehicle() ) then return false end
				end
			elseif ( cvarNoCollide:GetBool() ) then
				if ( m_Ents[ a ] and m_Ents[ b ] ) then return false end
			end
		end
		--hook.Add( "ShouldCollide", mode, ShouldCollide )
		--hook.Remove( "ShouldCollide", mode )
	end
	
elseif ( CLIENT ) then
	
	-- the table below is used internally and should only generally be interfaced with
	-- via the functions declared afterward.
	-- basically treat it as private, since it is only public for auto-refresh compatibility
	
	m_Ghosts    = m_Ghosts    or {}
	m_LookingAt = m_LookingAt or nil
	m_LookedAt  = m_LookedAt  or nil
	
	--[[--------------------------------------------------------------------------
	-- 	GetGhosts()
	--]]--
	function GetGhosts()
		return m_Ghosts
	end
	--[[--------------------------------------------------------------------------
	-- 	SetGhosts( table )
	--]]--
	function SetGhosts( tbl )
		m_Ghosts = tbl
	end
	
	--[[--------------------------------------------------------------------------
	-- 	GetLookingAt()
	--]]--
	function GetLookingAt()
		return m_LookingAt
	end
	--[[--------------------------------------------------------------------------
	-- 	SetLookingAt( entity )
	--]]--
	function SetLookingAt( ent )
		m_LookingAt = ent
	end
	
	--[[--------------------------------------------------------------------------
	-- 	GetLookedAt()
	--]]--
	function GetLookedAt()
		return m_LookedAt
	end
	--[[--------------------------------------------------------------------------
	-- 	SetLookedAt( entity )
	--]]--
	function SetLookedAt( ent )
		m_LookedAt = ent
	end
	
	--[[--------------------------------------------------------------------------
	-- 	ReleaseGhosts()
	--	
	--	Attempts to remove all ghosted props in the stack. 
	--	This occurs when the player stops looking at a prop with the stacker tool equipped.
	--]]--
	function ReleaseGhosts()
		if ( #m_Ghosts == 0 ) then return end
		
		for i = 1, #m_Ghosts do
			if ( not IsValid( m_Ghosts[ i ] ) ) then continue end
			SafeRemoveEntityDelayed( m_Ghosts[ i ], 0 )
			m_Ghosts[ i ] = nil
		end
	end
	
	--[[--------------------------------------------------------------------------
	--	Initialize( string )
	--
	--	This should be called immediately after including this file so that the follow
	--	variables/functions can use the stacker tool's mode (i.e., the name of the file itself
	--	and what is subsequently used in all of the cvars).
	--]]--
	function Initialize( mode )
		mode = mode or "stacker_improved"
		
		SETTINGS_DEFAULT = {
			[mode.."_set_max_per_player"]    = "-1",
			[mode.."_set_max_per_stack"]     = "15",
			[mode.."_set_delay"]             = "0.5",
			[mode.."_set_max_offsetx"]       = "200",
			[mode.."_set_max_offsety"]       = "200",
			[mode.."_set_max_offsetz"]       = "200",
			[mode.."_set_force_freeze"]      = "0",
			[mode.."_set_force_weld"]        = "0",
			[mode.."_set_force_nocollide"]   = "0",
			[mode.."_set_force_stayinworld"] = "1",
		}
		
		SETTINGS_SANDBOX = {
			[mode.."_set_max_per_player"]    = "-1",
			[mode.."_set_max_per_stack"]     = "30",
			[mode.."_set_delay"]             = "0.5",
			[mode.."_set_max_offsetx"]       = "1000",
			[mode.."_set_max_offsety"]       = "1000",
			[mode.."_set_max_offsetz"]       = "1000",
			[mode.."_set_force_freeze"]      = "0",
			[mode.."_set_force_weld"]        = "0",
			[mode.."_set_force_nocollide"]   = "0",
			[mode.."_set_force_stayinworld"] = "0",
		}
		
		SETTINGS_DARKRP = {
			[mode.."_set_max_per_player"]    = "50",
			[mode.."_set_max_per_stack"]     = "5",
			[mode.."_set_delay"]             = "1",
			[mode.."_set_max_offsetx"]       = "200",
			[mode.."_set_max_offsety"]       = "200",
			[mode.."_set_max_offsetz"]       = "200",
			[mode.."_set_force_freeze"]      = "1",
			[mode.."_set_force_weld"]        = "0",
			[mode.."_set_force_nocollide"]   = "1",
			[mode.."_set_force_stayinworld"] = "1",
		}
		
		SETTINGS_SINGLEPLAYER = {
			[mode.."_set_max_per_player"]    = "-1",
			[mode.."_set_max_per_stack"]     = "100",
			[mode.."_set_delay"]             = "0",
			[mode.."_set_max_offsetx"]       = "10000",
			[mode.."_set_max_offsety"]       = "10000",
			[mode.."_set_max_offsetz"]       = "10000",
			[mode.."_set_force_freeze"]      = "0",
			[mode.."_set_force_weld"]        = "0",
			[mode.."_set_force_nocollide"]   = "0",
			[mode.."_set_force_stayinworld"] = "0",
		}
	end
	
end

--
-- The functions below are used both serverside and clientside for properly orienting
-- and spacing props in a stack
--

-- Lookup table that holds functions related to determining the direction of a stack
DirectionFunctions = {
	[MODE_WORLD] = {
		[DIRECTION_FRONT] = function() return VECTOR_FRONT end,
		[DIRECTION_BACK]  = function() return VECTOR_BACK  end,
		[DIRECTION_RIGHT] = function() return VECTOR_RIGHT end,
		[DIRECTION_LEFT]  = function() return VECTOR_LEFT  end,
		[DIRECTION_UP]    = function() return VECTOR_UP    end,
		[DIRECTION_DOWN]  = function() return VECTOR_DOWN  end,
	},
	
	[MODE_PROP]  = {
		[DIRECTION_FRONT] = function( angle ) return  angle:Forward() end,
		[DIRECTION_BACK]  = function( angle ) return -angle:Forward() end,
		[DIRECTION_RIGHT] = function( angle ) return  angle:Right()   end,
		[DIRECTION_LEFT]  = function( angle ) return -angle:Right()   end,
		[DIRECTION_UP]    = function( angle ) return  angle:Up()      end,
		[DIRECTION_DOWN]  = function( angle ) return -angle:Up()      end,
	}
}

-- Lookup table that holds functions related to determining the distance to offset each prop in a stack
-- before applying the client's actual x/y/z offset values
DistanceFunctions = {
	[DIRECTION_FRONT] = function( min, max ) return math.abs(max.x - min.x) end,
	[DIRECTION_BACK]  = function( min, max ) return math.abs(max.x - min.x) end,
	[DIRECTION_RIGHT] = function( min, max ) return math.abs(max.y - min.y) end,
	[DIRECTION_LEFT]  = function( min, max ) return math.abs(max.y - min.y) end,
	[DIRECTION_UP]    = function( min, max ) return math.abs(max.z - min.z) end,
	[DIRECTION_DOWN]  = function( min, max ) return math.abs(max.z - min.z) end,
}

-- Lookup table that holds functions related to determining the distance to offset each prop in a stack
-- based on the client's x/y/z offset values
OffsetFunctions = {
	[DIRECTION_FRONT] = function( angle, offset ) return ( angle:Forward() * offset.x) + ( angle:Up()      * offset.z) + ( angle:Right()   * offset.y) end,
	[DIRECTION_BACK]  = function( angle, offset ) return (-angle:Forward() * offset.x) + ( angle:Up()      * offset.z) + (-angle:Right()   * offset.y) end,
	[DIRECTION_RIGHT] = function( angle, offset ) return ( angle:Right()   * offset.x) + ( angle:Up()      * offset.z) + (-angle:Forward() * offset.y) end,
	[DIRECTION_LEFT]  = function( angle, offset ) return (-angle:Right()   * offset.x) + ( angle:Up()      * offset.z) + ( angle:Forward() * offset.y) end,
	[DIRECTION_UP]    = function( angle, offset ) return ( angle:Up()      * offset.x) + (-angle:Forward() * offset.z) + ( angle:Right()   * offset.y) end,
	[DIRECTION_DOWN]  = function( angle, offset ) return (-angle:Up()      * offset.x) + ( angle:Forward() * offset.z) + ( angle:Right()   * offset.y) end,
}

RotationFunctions = {
	[DIRECTION_FRONT] = function( angle ) return  angle:Right(),   angle:Up(),       angle:Forward() end,
	[DIRECTION_BACK]  = function( angle ) return -angle:Right(),   angle:Up(),      -angle:Forward() end,
	[DIRECTION_RIGHT] = function( angle ) return -angle:Forward(), angle:Up(),       angle:Right()   end,
	[DIRECTION_LEFT]  = function( angle ) return  angle:Forward(), angle:Up(),      -angle:Right()   end,
	[DIRECTION_UP]    = function( angle ) return -angle:Right(),   angle:Forward(),  angle:Up()      end,
	[DIRECTION_DOWN]  = function( angle ) return  angle:Right(),   angle:Forward(), -angle:Up()      end,
}

--[[--------------------------------------------------------------------------
-- 	GetDirection( number, number, angle )
--
--	Calculates the direction to point the entity to by depending on whether the stack is
--	created relative to the world or the original prop, and the direction to stack in.
--]]--
function GetDirection( stackMode, stackDir, angle )
	return DirectionFunctions[ stackMode ][ stackDir ]( angle )
end

--[[--------------------------------------------------------------------------
-- 	GetDistance( number, number, entity )
--
--	Calculates the space occupied by the entity depending on the stack direction.
--	This represents the number of units to offset the stack entities so they appear
--	directly in front of the previous entity (depending on direction).
--]]--
function GetDistance( stackMode, stackDir, ent )
	if ( stackMode == MODE_WORLD ) then
		return DistanceFunctions[ stackDir ]( ent:WorldSpaceAABB() )
	elseif ( stackMode == MODE_PROP ) then
		return DistanceFunctions[ stackDir ]( ent:OBBMins(), ent:OBBMaxs() )
	end
end

--[[--------------------------------------------------------------------------
-- 	GetOffset( number, number, angle, vector )
--
--	Calculates a direction vector used for offsetting a stacked entity based on the facing angle of the previous entity.
--	This function uses a lookup table for added optimization as opposed to an if-else block.
--]]--
function GetOffset( stackMode, stackDir, angle, offset )
	-- if stacking relative to the world, apply the magic offset fix to the correct direction
	if ( stackMode == MODE_WORLD ) then
		local direction = DirectionFunctions[ stackMode ][ stackDir ]()
			  direction = direction * MAGIC_OFFSET
		return offset + direction
	-- if stacking relative to the prop, apply the magic offset only to the forward (x) component of the vector
	elseif ( stackMode == MODE_PROP ) then
		local trueOffset = Vector()
		      trueOffset:Set( offset )
			  trueOffset.x = trueOffset.x + MAGIC_OFFSET
		return OffsetFunctions[ stackDir ]( angle, trueOffset )
	end
end

--[[--------------------------------------------------------------------------
-- 	RotateAngle( angle, angle )
--
--	Rotates the first angle by the second angle. This ensures proper rotation
--	along all three axes and prevents various problems related to simply adding
--	two angles together. The first angle is modified directly by refence, so this does not
--	return anything.
--]]--
function RotateAngle( stackMode, stackDir, angle, rotation )
	local axisPitch, axisYaw, axisRoll = RotationFunctions[ stackDir ]( angle )

	angle:RotateAroundAxis( axisPitch,  rotation.p )
	angle:RotateAroundAxis( axisYaw,   -rotation.y )
	angle:RotateAroundAxis( axisRoll,   rotation.r )
end