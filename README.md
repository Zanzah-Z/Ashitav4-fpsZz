# Ashitav4-fpsZz
A lightweight customizable in-game average-FPS overlay for HorizonXI Private Server using AshitaV4.
fpsZz Overlay Addon<br>
<a href="https://linktr.ee/zanzah" target="_blank"</a><br>
Buy me a Coffee?<br>
<a href="https://ko-fi.com/zanzah_z" target="_blank"</a><br>
====================<br>

Author: Zanzah<br>
Website: <a href="https://www.Zanzah.com" target="_blank"></a><br>
Version: 1.9<br>
Description: Displays the current FPS in-game with customizable options.<br>

Installation:
-------------
1. Place the `fpszz` folder into your Ashita4 `addons` directory.
2. Load the addon using `/addon load fpszz`.

Commands:
/fpszz s [scale]
- Set the scaling percentage of the text (50–400).
- Example: `/fpszz s 100` (default scale), `/fpszz s 200` (2x scale)

/fpszz c [hexcode]
- Set the font color using a hex value (no `#`).
- Example: `/fpszz c 00ff00` (bright green)

/fpszz bg
- Toggles background visibility behind the FPS text.

/fpszz o [opacity]
- Set text opacity between 0.0 and 1.0.
- Example: `/fpszz o 1.0` (fully visible), `/fpszz o 0.5` (semi-transparent)

/fpszz i [seconds]
- Set FPS update interval in seconds (0–60).
- 0 = real-time updates, 60 = update every 60 seconds
- Example: `/fpszz i 5` (average FPS every 5 seconds)

/fpszz f [font name]
- Change the font to any installed system font.
- If the font is invalid, the previous good config is restored.
- Example: `/fpszz f Arial`, `/fpszz f Consolas`

/fpszz d
- Toggles display of decimal points in FPS (e.g., "60.1" vs "60")

/fpszz t
- Toggles the "FPS:" label text.
- When off, only the number is displayed (e.g., "60")

Default Settings:
-----------------
- Color: White (`ffffff`)
- Font: Arial
- Opacity: 1.0
- Background: Off
- Decimal Display: Off
- Label: Off
- Scale: 100
- Interval: 1 (Second)

Latest Version Updates:
------
- Added more customization options. (f) (i) (d) and (t)
- Changed default settings from realtime (0) to update every 1 seconds.
- All user settings are saved persistently and applied on next load.
- Compatible with any valid font installed on the system.
- Font fallback system ensures the addon remains functional.

