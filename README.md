#Improved Stacker

###Author:
	Original              - OverloadUT
	Updated for GMod 13   - Marii
	Cleaned and optimized - Mista Tea
	
###Changelog:
	- Added to GitHub     May 27th, 2014
	- Added to Workshop   May 28th, 2014
	- Massive overhaul    Jun  5th, 2014
	- Large update        Jul 24th, 2014
	- Optimizations       Aug 12th, 2014
	- Bug fixes/features  Jun 30th, 2015
	- Bug fixes           Jul 11th, 2015

###Fixes:
	- Prevents crash from players using very high X/Y/Z offset values.
	- Prevents crash from players using very high P/Y/R rotate values.
	- Prevents crash from very specific constraint settings.
	- Fixed the halo option for ghosted props not working.
	- Fixed massive FPS drop from halos being rendered in a Think hook instead of a PreDrawHalos hooks.
		- Had to move back to using TOOL:Think
	- Fixed materials and colors being saved when duping stacked props.
	
###Tweaks:
	- Added convenience functions to retrieve the client convars.
	- Added option to enable/disable automatically applying materials to the stacked props.
	- Added option to enable/disable automatically applying colors to the stacked props.
	- Added option to enable/disable automatically applying physical properties (gravity, physics material, weight) to the stacked props.
	- Added support for props with multiple skins.
	- Added support for external prop protections/anti-spam addons with the StackerEntity hook.
	- Modified NoCollide to actually no-collide each stacker prop with every other prop in the stack.
	
	- Added console variables for server operators to limit various parts of stacker.
		> stacker_max_total       <-inf/inf>     (less than 0 == no limit)
		> stacker_max_count       <-inf/inf>     (less than 0 == no limit)
		> stacker_max_offsetx     <-inf/inf>
		> stacker_max_offsety     <-inf/inf>
		> stacker_max_offsetz     <-inf/inf>
		> stacker_stayinworld        <0/1>
		> stacker_force_weld         <0/1>
		> stacker_force_freeze       <0/1>
		> stacker_force_nocollide    <0/1>
		> stacker_delay              <0/inf>

	- Added console commands for server admins to control the console variables that limit stacker.
		> stacker_set_maxtotal    <-inf/inf>     (less than 0 == no limit)
		> stacker_set_maxcount    <-inf/inf>     (less than 0 == no limit)
		> stacker_set_maxoffset   <-inf/inf>
		> stacker_set_maxoffsetx  <-inf/inf>
		> stacker_set_maxoffsety  <-inf/inf>
		> stacker_set_maxoffsetz  <-inf/inf>
		> stacker_set_stayinworld    <0/1>
		> stacker_set_weld           <0/1>
		> stacker_set_freeze         <0/1>
		> stacker_set_nocollide      <0/1>
		> stacker_set_delay          <0/inf>
