--[[--------------------------------------------------------------------------
	Localify Module
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (MIT)

		Copyright (c) 2015 Mista-Tea

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

--[[--------------------------------------------------------------------------
-- 	Namespace Tables
--------------------------------------------------------------------------]]--

module( "localify", package.seeall )

languages = {
	bg        = "Bulgarian",
	cs        = "Czech",
	da        = "Danish",
	de        = "German",
	el        = "Greek",
	["en-pt"] = "Pirate",
	en        = "English",
	es        = "Spanish",
	et        = "Estonian",
	fi        = "Finnish",
	fr        = "French",
	he        = "Hebrew",
	hr        = "Croatian",
	hu        = "Hungarian",
	it        = "Italian",
	ja        = "Japanese",
	ko        = "Korean",
	lt        = "Lithuanian",
	nl        = "Dutch",
	no        = "Norwegian",
	pl        = "Polish",
	["pt-br"] = "Brazilian Portuguese",
	["pt-pt"] = "Portuguese",
	ru        = "Russian",
	sk        = "Slovak",
	["sv-se"] = "Swedish",
	th        = "Thai",
	tr        = "Turkish",
	uk        = "Ukranian",
	vi        = "Vietnamese",
	["zh-cn"] = "Simplified Chinese",
	["zh-tw"] = "Traditional Chinese",
}

localizations = localizations or {
	bg        = {},
	cs        = {},
	da        = {},
	de        = {},
	el        = {},
	["en-pt"] = {},
	en        = {},
	es        = {},
	et        = {},
	fi        = {},
	fr        = {},
	he        = {},
	hr        = {},
	hu        = {},
	it        = {},
	ja        = {},
	ko        = {},
	lt        = {},
	nl        = {},
	no        = {},
	pl        = {},
	["pt-br"] = {},
	["pt-pt"] = {},
	ru        = {},
	sk        = {},
	["sv-se"] = {},
	th        = {},
	tr        = {},
	uk        = {},
	vi        = {},
	["zh-cn"] = {},
	["zh-tw"] = {},
}

--[[--------------------------------------------------------------------------
-- 	Localized Functions & Variables
--------------------------------------------------------------------------]]--

local error = error
local include = include
local tostring = tostring
local GetConVar = GetConVar
local AddCSLuaFile = AddCSLuaFile

FALLBACK = FALLBACK or "en"

--[[--------------------------------------------------------------------------
--	Namespace Functions
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
-- 	localify.Bind( string, string, string )
--
--	Binds the token <key> and localized phrase <value> to the given language <lang>.
--
--	Example: localify.Bind( "en", "#Hello", "Hello" )
--	Example: localify.Bind( "es", "#Hello", "Hola" )
--	Example: localify.Bind( "fr", "#Hello", "Bonjour" )
--]]--
function Bind( lang, key, value )
	if ( not IsValidLanguage( lang ) ) then error( "Invalid language provided ('"..tostring(lang).."')" ) return end
	
	localizations[ lang:lower() ][ key ] = value
end

--[[--------------------------------------------------------------------------
-- 	localify.Localize( string, string, boolean [optional] )
--
--	Returns the localized phrase associated with the token <key>.
--
--	If a language <lang> is provided, the phrase bound to that language will be returned.
--	If no language is provided, the language will default to the client or server's locale.
--	If a localized phrase is not found and (returnKey) is truthsy, the key will be returned.
--	If a localized phrase is not found and (returnKey) is falsey, the phrase associated with the fallback language (en' by default) will be returned, if any.
--	Otherwise, nil will be returned if no binding exists.
--
--	Example: local str = localify.Localize( "#Hello" )             -- Returns either the locale's binding or the default binding (if any)
--	Example: local str = localify.Localize( "#Hello", "es" )       -- Returns either a Spanish binding, the locale's binding, or the default binding (if any)
--	Example: local str = localify.Localize( "#Hello", "fr" )       -- Returns either a French  binding, the locale's binding, or the default binding (if any)
--	Example: local str = localify.Localize( "#Hello", "de", true ) -- Returns either a German  binding, the locale's binding, or the key
--	Example: local str = localify.Localize( "#Hello",  nil, true ) -- Returns either the locale's binding or the key
--]]--
function Localize( key, lang, returnKey )
	-- If for some reason the given language isn't valid (e.g. user set it themselves), show an
	-- error in console letting them know and try to use the fallback language.
	if ( lang and not IsValidLanguage( lang ) ) then
		ErrorNoHalt( "Invalid localify_language provided ('"..tostring(lang).."')\n" )
		lang = FALLBACK
	end
	
	local tbl = localizations[ (lang and lang:lower()) or GetLocale() ]

	return ( tbl and tbl[ key ] )                                             -- If there is a bind, return it
		or ( returnKey and key )                                              -- If there is no bind and we want to return the key on failure, return the key
		or ( localizations[ FALLBACK ] and localizations[ FALLBACK ][ key ] ) -- If there is a bind in the fallback language, return it
		or nil                                                                -- Otherwise return nil
end



--[[--------------------------------------------------------------------------
-- 	localify.AddLanguage( string, string )
--
--	Adds a non-GMod language <lang> with the given <name> to the table of valid languages.
--
--	Example: localify.AddLanguage( "zom", "Zombie" )
--	Example: localify.AddLanguage( "fil", "Filipino" )
--]]--
function AddLanguage( lang, name )
	if ( IsValidLanguage( lang ) ) then return end
	
	    languages[ lang:lower() ] = name
	localizations[ lang:lower() ] = {}
end

--[[--------------------------------------------------------------------------
-- 	localify.RemoveLanguage( string )
--
--	Removes a language <lang> from the table of valid languages.
--	If the removed language was the fallback language, "en" (English) will be
--	set as the new fallback language automatically.
--
--	Example: localify.RemoveLanguage( "zom" )
--	Example: localify.RemoveLanguage( "fil" )
--]]--
function RemoveLanguage( lang )
	if ( not IsValidLanguage( lang ) ) then return end
	
	    languages[ lang:lower() ] = nil
	localizations[ lang:lower() ] = nil
	
	if ( lang:lower() == FALLBACK ) then FALLBACK = "en" end
end

--[[--------------------------------------------------------------------------
-- 	localify.IsValidLanguage( string )
--
--	Checks if the language <lang> has been added to Localify.
--	Returns true if valid, false if invalid.
--
--	Example: localify.IsValidLanguage( "vi" ) -- Vietnamese is supported by default, so this is true
--	Example: localify.IsValidLanguage( "zz" ) -- false by default, unless manually added
--]]--
function IsValidLanguage( lang )
	return lang and languages[ lang:lower() ]
end

--[[--------------------------------------------------------------------------
-- 	localify.SetFallbackLanguage( string )
--
--	Sets the fallback language <lang> to use when a localized phrase is unavailable.
--	This is set to "en" (English) by default.
--
--	Example: localify.SetFallbackLanguage( "de" ) -- fallback language is now German
--]]--
function SetFallbackLanguage( lang )
	if ( not IsValidLanguage( lang ) ) then error( "Invalid language provided ('"..tostring(lang).."')" ) return end
	
	FALLBACK = lang:lower()
end



--[[--------------------------------------------------------------------------
-- 	localify.GetLocale( player [optional] )
--
--	If used clientside, this will return the passed player's <ply> Localify language setting.
--	If used serverside, this will return the client's Localify language setting.
--
--	Returns the fallback language if the cvar is empty.
--	The cvar holding this value is "gmod_language".
--]]--
function GetLocale( ply )
	return ( SERVER and ply and ply:GetInfo( "localify_language" ):lower() )
	    or ( GetConVarString( "localify_language" ) == "" and FALLBACK or GetConVarString( "localify_language" ):lower() )
end

--[[--------------------------------------------------------------------------
-- 	localify.GetLanguages()
--
--	Returns the table of valid languages and their associated names.
--]]--
function GetLanguages()
	return languages
end

--[[--------------------------------------------------------------------------
-- 	localify.GetLocalizations( string )
--
--	Gets the table of all phrases that have been bound to the passed language <lang>.
--
--	Returns the table of ALL phrases (indexed by language token) if no language <lang> is passed.
--  Returns an empty table if the language is valid but doesn't contain any bound phrases.
--	Returns nil if the language has not been added to Localify.
--
--	Example: localify.GetLocalizations()       -- returns bindings for every language
--	Example: localify.GetLocalizations( "en" ) -- returns all English bindings
--	Example: localify.GetLocalizations( "zz" ) -- returns nil by default
--]]--
function GetLocalizations( lang )
	return ( not lang and localizations ) or ( lang and localizations[ lang:lower() ] ) or nil
end

--[[--------------------------------------------------------------------------
-- 	localify.GetFallbackLanguage()
--
--	Returns the current fallback language ("en" by default).
--]]--
function GetFallbackLanguage()
	return FALLBACK
end



--[[--------------------------------------------------------------------------
-- 	localify.LoadSharedFile( string )
--
--	Loads a file <path> containing localization phrases onto the server and for connecting clients.
--]]--
function LoadSharedFile( path )
	include( path )
	if ( SERVER ) then AddCSLuaFile( path ) end
end

--[[--------------------------------------------------------------------------
-- 	localify.LoadServerFile( string )
--
--	Loads a file <path> containing localization phrases onto the server.
--]]--
function LoadServerFile( path )
	if ( CLIENT ) then return end
	include( path )
end

--[[--------------------------------------------------------------------------
-- 	localify.LoadClientFile( string )
--
--	Loads a file <path> containing localization phrases onto connecting clients.
--]]--
function LoadClientFile( path )
	if ( SERVER ) then AddCSLuaFile( path ) return end
	include( path )
end



if ( CLIENT ) then

	-- Create a client cvar that copies the gmod_language cvar so that we can retrieve it from
	-- the server with ply:GetInfo( "localify_language" )
	CreateClientConVar( "localify_language", GetConVarString( "gmod_language" ), false, true )

	-- Check for changes to the gmod_language cvar and replicate them to localify_language
	cvars.AddChangeCallback( "gmod_language", function( name, old, new )
		if ( not IsValidLanguage( new ) ) then return end
		
		RunConsoleCommand( "localify_language", new )
	end, "localify" )

end
