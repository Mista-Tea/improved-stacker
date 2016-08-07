if ( SERVER ) then
	
	-- needed for custom vgui controls in the menu
	AddCSLuaFile( "vgui/stackercontrolpresets.lua" )
	AddCSLuaFile( "vgui/stackerdnumslider.lua" )
	AddCSLuaFile( "vgui/stackerpreseteditor.lua" )
	
	-- convenience modules
	AddCSLuaFile( "improvedstacker/improvedstacker.lua" )
	AddCSLuaFile( "improvedstacker/localify.lua" )
	
else

	-- needed for custom vgui controls in the menu
	include( "vgui/stackercontrolpresets.lua" )
	include( "vgui/stackerdnumslider.lua" )
	include( "vgui/stackerpreseteditor.lua" )

end