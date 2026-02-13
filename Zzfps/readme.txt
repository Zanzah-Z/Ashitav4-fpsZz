Ashitav4-fpsZz
A lightweight customizable in-game average-FPS overlay for HorizonXI Private Server using AshitaV4. Zzfps Overlay Addon
https://linktr.ee/zanzah
Buy me a Coffee?
https://ko-fi.com/zanzah_z
====================

Author: Zanzah
Website: https://www.Zanzah.com
Version: 2.0
Description: Displays the current FPS in-game with customizable options.

Installation:
Place the Zzfps folder into your Ashita4 addons directory.
Load the addon using /addon load zzfps.
Commands: <br>
Shift+Click-and-drag to reposition. <br><br>

/zzfps s [scale] <br>
Set the scaling percentage of the text (50–400).
Example: /zzfps s 100 (default scale), /zzfps s 200 (2x scale)<br><br>

/zzfps c [hexcode] <br>
Set the font color using a hex value (no #).
Example: /zzfps c 00ff00 (bright green)<br><br>

/zzfps bg <br>
Toggles background visibility behind the FPS text.<br><br>

/zzfps o [opacity] <br>
Set text opacity between 0.0 and 1.0.
Example: /zzfps o 1.0 (fully visible), /zzfps o 0.5 (semi-transparent)<br><br>

/zzfps i [seconds] <br>
Set FPS update interval in seconds (0–60).
0 = real-time updates, 60 = update every 60 seconds
Example: /zzfps i 5 (average FPS every 5 seconds)<br><br>

/zzfps f [font name] <br>
Change the font to any installed system font.
If the font is invalid, the previous good config is restored.
Example: /zzfps f Arial, /zzfps f Consolas<br><br>

/zzfps d <br>
Toggles display of decimal points in FPS (e.g., "60.1" vs "60")<br><br>

/zzfps t <br>
Toggles the "FPS:" label text.
When off, only the number is displayed (e.g., "60")
<br><br>
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

