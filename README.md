# Improved Stacker

### Note:
	Please DO NOT reupload this tool (verbatim or small tweaks) to the workshop or other public file-sharing websites.
	I actively maintain this tool, so reuploading it may lead to people using outdated, buggy, or malicious copies.
	If there is an issue with the tool, LET ME KNOW via one of the following pages:
	
	- GitHub:    https://github.com/Mista-Tea/improved-stacker
	- Workshop:  http://steamcommunity.com/sharedfiles/filedetails/?id=264467687
	- Facepunch: https://facepunch.com/showthread.php?t=1399120

### Author:
	- Original            :: OverloadUT (STEAM_0:1:5250809)
	- Updated for GMod 13 :: Marii      (STEAM_0:1:16015332)
	- Rewritten           :: Mista Tea  (STEAM_0:0:27507323)
	
### Changelog:
	- May 27th, 2014 :: Added to GitHub 
	- May 28th, 2014 :: Added to Workshop 
	- Jun 5th,  2014 :: Massive overhaul 
	- Jul 24th, 2014 :: Large update 
	- Aug 12th, 2014 :: Optimizations 
	- Jun 30th, 2015 :: Bug fixes/features 
	- Jul 11th, 2015 :: Bug fixes 
	- Oct 26th, 2015 :: Bug fixes
	- Aug 3rd,  2016 :: Bug fixes
	- Aug 31st, 2016 :: Bug fixes
	- Sep 2nd,  2016 :: Added Bulgarian language support
	- Sep 26th, 2017 :: Added ability to toggle use of SHIFT key with LMB/RMB
	- Oct 27th, 2017 :: Small client optimization, reverted nocollide implementation back to original
	- Apr 14th, 2018 :: Added French language support

### Fixes:
	- Prevented crash from players using very high X/Y/Z offset values.
	- Prevented crash from players using very high P/Y/R rotate values.
	- Prevented crash from very specific constraint settings.
	- Fixed the halo option for ghosted props not working.
	- Fixed massive FPS drop from halos being rendered in a Think hook instead of a PreDrawHalos hook.
	- Fixed materials and color saving when duping stacked props.
	- Fixed incorrect stack angles when trying to create a stack on an existing stack.
	
### Tweaks:
	- Added convenience functions to retrieve the client convars.
	- Added option to enable/disable automatically applying materials to the stacked props.
	- Added option to enable/disable automatically applying colors to the stacked props.
	- Added option to enable/disable automatically applying physical properties (gravity, physics material, weight) to the stacked props.
	- Added support for props with multiple skins.
	- Added support for external prop protections/anti-spam addons with the StackerEntity hook.
	- Modified NoCollide to actually no-collide each stacker prop with every other prop in the stack.
	
	- Added console variables for server operators to limit various parts of stacker.
		> stacker_improved_max_per_player         <-inf/inf> (less than 0 == no limit)
		> stacker_improved_max_per_stack          <-inf/inf> (less than 0 == no limit)
		> stacker_improved_max_offsetx            <-inf/inf>
		> stacker_improved_max_offsety            <-inf/inf>
		> stacker_improved_max_offsetz            <-inf/inf>
		> stacker_improved_force_stayinworld         <0/1>
		> stacker_improved_force_weld                <0/1>
		> stacker_improved_force_freeze              <0/1>
		> stacker_improved_force_nocollide           <0/1>
		> stacker_improved_force_nocollide_all       <0/1>
		> stacker_improved_delay                     <0/inf>

	- Added console commands for server admins to control the console variables that limit stacker.
		> stacker_improved_set_max_per_player     <-inf/inf> (less than 0 == no limit)
		> stacker_improved_set_max_per_stack      <-inf/inf> (less than 0 == no limit)
		> stacker_improved_set_maxoffset          <-inf/inf>
		> stacker_improved_set_maxoffsetx         <-inf/inf>
		> stacker_improved_set_maxoffsety         <-inf/inf>
		> stacker_improved_set_maxoffsetz         <-inf/inf>
		> stacker_improved_set_force_stayinworld     <0/1>
		> stacker_improved_set_weld                  <0/1>
		> stacker_improved_set_freeze                <0/1>
		> stacker_improved_set_nocollide             <0/1>
		> stacker_improved_set_nocollide_all         <0/1>
		> stacker_improved_set_delay                 <0/inf>
