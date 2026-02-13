Ashitav4-Zzfps
A lightweight customizable in-game average-FPS overlay for HorizonXI Private Server using AshitaV4. Zzfps Overlay Addon
https://linktr.ee/zanzah
Buy me a Coffee?
https://ko-fi.com/zanzah_z
====================

Author: Zanzah
Website: https://www.Zanzah.com
Description: Displays the current FPS in-game with customizable options.

Installation:
Place the Zzfps folder into your Ashita4 addons directory.
Load the addon via default.txt or manually ingame by using /addon load zzfps.
Commands:
Shift+Click-and-drag to reposition.

/zzfps s [scale]
Set the scaling percentage of the text (50–400).
Example: /zzfps s 100 (default scale), /zzfps s 200 (2x scale)

/zzfps c [hexcode]
Set the font color using a hex value (no #).
Example: /zzfps c 00ff00 (bright green)

/zzfps bg
Toggles background visibility behind the FPS text.

/zzfps o [opacity]
Set text opacity between 0.0 and 1.0.
Example: /zzfps o 1.0 (fully visible), /zzfps o 0.5 (semi-transparent)

/zzfps i [seconds]
Set FPS update interval in seconds (0–60).
0 = real-time updates, 60 = update every 60 seconds
Example: /zzfps i 5 (average FPS every 5 seconds)

/zzfps f [font name]
Change the font to any installed system font.
If the font is invalid, the previous good config is restored.
Example: /zzfps f Arial, /zzfps f Consolas

/zzfps d
Toggles display of decimal points in FPS (e.g., "60.1" vs "60")

/zzfps t
Toggles the "FPS:" label text.
When off, only the number is displayed (e.g., "60")


Default Settings:
Color: White (ffffff)
Font: Arial
Opacity: 1.0
Background: Off
Decimal Display: Off
Label: Off
Scale: 100
Interval: 1 (Second)
Latest Version Updates:
Changed from fpszz to Zzfps to make suite more uniform. More addons coming soon!
Added more customization options. (f) (i) (d) and (t)
Changed default settings from realtime (0) to update every 1 seconds.
All user settings are saved persistently and applied on next load.
Compatible with any valid font installed on the system.

Font fallback system ensures the addon remains functional.

