--[[
__________                            .__
\____    /____    ____ _____________  |  |__       ____  ____   _____
  /     /\__  \  /    \\___   /\__  \ |  |  \    _/ ___\/  _ \ /     \
 /     /_ / __ \|   |  \/    /  / __ \|   Y  \   \  \__(  <_> )  Y Y  \
/_______ (____  /___|  /_____ \(____  /___|  / /\ \___  >____/|__|_|  /
        \/    \/     \/      \/     \/     \/  \/     \/            \/


]]--

addon.name      = 'zzfps';
addon.author    = 'Zanzah';
addon.version   = '2.1';
addon.desc      = 'Displays the current FPS on screen with customization. Commands/Config @: Github or Zanzah.com/fpszz (redirects to Github)';
addon.link      = 'https://github.com/Zanzah-Z/Ashitav4-Zzfps';

require('common');
local fonts     = require('fonts');
local settings  = require('settings');
local scaling   = require('scaling');

local os_clock  = os.clock;

-- Default Settings
local default_settings = T{
    font = T{
        visible     = true,
        locked      = false,               -- allow dragging
        font_family = 'Arial',
        font_height = scaling.scale_f(12),
        color       = 0xFF00FF00,
        position_x  = 130,
        position_y  = 0,
        background  = T{
            visible = false,
            color   = 0x00000000,
        },
        opacity = 1.0,
    },
    interval     = 1,       -- update interval in seconds (0 = real-time)
    show_decimal = false,
    show_label   = false,
};

-- Main Object
local zzfps = T{
    settings        = settings.load(default_settings),
    font            = nil,
    frame_times     = T{},
    last_time       = os_clock(),
    last_update     = os_clock(),

    -- position persistence
    last_pos_save   = 0,
    pos_save_rate   = 0.50,  -- throttle disk writes
};

local function clamp(n, a, b)
    if (n < a) then return a end
    if (n > b) then return b end
    return n
end

local function safe_number(v)
    if (type(v) == 'number') then return v end
    return nil
end

-- Sync position in settings and save
local function sync_position_from_font(now)
    if (zzfps.font == nil) then return end

    local x = safe_number(zzfps.font.position_x);
    local y = safe_number(zzfps.font.position_y);
    if (x == nil or y == nil) then return end

    if (x ~= zzfps.settings.font.position_x or y ~= zzfps.settings.font.position_y) then
        zzfps.settings.font.position_x = x;
        zzfps.settings.font.position_y = y;

        if (now - zzfps.last_pos_save) >= zzfps.pos_save_rate then
            zzfps.last_pos_save = now;
            settings.save();
        end
    end
end

settings.register('settings', 'settings_update', function(s)
    if (s ~= nil) then
        zzfps.settings = s;
    end
    if (zzfps.font ~= nil) then
        zzfps.font:apply(zzfps.settings.font);
    end
    settings.save();
end);

ashita.events.register('load', 'load_cb', function()
    zzfps.font = fonts.new(zzfps.settings.font);
end);

ashita.events.register('unload', 'unload_cb', function()
    -- final position sync + save on unload
    if (zzfps.font ~= nil) then
        local x = safe_number(zzfps.font.position_x);
        local y = safe_number(zzfps.font.position_y);
        if (x ~= nil and y ~= nil) then
            zzfps.settings.font.position_x = x;
            zzfps.settings.font.position_y = y;
        end
        settings.save();

        zzfps.font:destroy();
        zzfps.font = nil;
    end
end);

ashita.events.register('command', 'command_cb', function(e)
    local args = e.command:split(' ');
    if (#args == 0) then
        return;
    end

    local cmd = args[1]:lower();
    if (cmd ~= '/zzfps' and cmd ~= '//zzfps') then
        return;
    end

    local sub = (args[2] ~= nil) and args[2]:lower() or '';

    -- size scale: /zzfps s 150   (50..400)
    if (sub == 's' and args[3]) then
        local val = tonumber(args[3]);
        if (val) then
            val = clamp(val, 50, 400);
            zzfps.settings.font.font_height = scaling.scale_f((val / 100) * 12);
            if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
        end

    -- color: /zzfps c FF00FF
    elseif (sub == 'c' and args[3]) then
        local hex = tonumber(args[3], 16);
        if (hex) then
            zzfps.settings.font.color = bit.bor(0xFF000000, hex);
            if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
        end

    -- background toggle: /zzfps bg
    elseif (sub == 'bg') then
        zzfps.settings.font.background.visible = not zzfps.settings.font.background.visible;
        if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end

    -- opacity: /zzfps o 0.5
    elseif (sub == 'o' and args[3]) then
        local opacity = tonumber(args[3]);
        if (opacity) then
            opacity = clamp(opacity, 0.0, 1.0);
            local alpha = math.floor(opacity * 255);
            local col = bit.band(zzfps.settings.font.color, 0x00FFFFFF);
            zzfps.settings.font.color = bit.bor(bit.lshift(alpha, 24), col);
            if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
        end

    -- interval: /zzfps i 1  (0..60)
    elseif (sub == 'i' and args[3]) then
        local interval = tonumber(args[3]);
        if (interval) then
            zzfps.settings.interval = clamp(interval, 0, 60);
        end

    -- font face: /zzfps f Arial
    elseif (sub == 'f' and args[3]) then
        local font_name = args[3];
        if (font_name and font_name ~= '') then
            local old_font = zzfps.settings.font.font_family;
            zzfps.settings.font.font_family = font_name;

            local ok = pcall(function()
                if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
            end);

            if (not ok) then
                zzfps.settings.font.font_family = old_font;
                if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
            end
        end

    -- decimal toggle: /zzfps d
    elseif (sub == 'd') then
        zzfps.settings.show_decimal = not zzfps.settings.show_decimal;

    -- label toggle: /zzfps t
    elseif (sub == 't') then
        zzfps.settings.show_label = not zzfps.settings.show_label;

    -- explicit position: /zzfps pos 130 0
    elseif (sub == 'pos' and args[3] and args[4]) then
        local x = tonumber(args[3]);
        local y = tonumber(args[4]);
        if (x and y) then
            zzfps.settings.font.position_x = x;
            zzfps.settings.font.position_y = y;
            if (zzfps.font) then
                zzfps.font.position_x = x;
                zzfps.font.position_y = y;
                zzfps.font:apply(zzfps.settings.font);
            end
        end
    end

    settings.save();
    e.blocked = true;
end);

ashita.events.register('d3d_present', 'present_cb', function()
    if (zzfps.font == nil) then
        return;
    end

    local now = os_clock();

    -- persist position
    sync_position_from_font(now);

    -- FPS calc
    local delta = now - zzfps.last_time;
    zzfps.last_time = now;

    table.insert(zzfps.frame_times, delta);
    if (#zzfps.frame_times > 100) then
        table.remove(zzfps.frame_times, 1);
    end

    if (zzfps.settings.interval == 0 or (now - zzfps.last_update >= zzfps.settings.interval)) then
        zzfps.last_update = now;

        local total = 0;
        for _, dt in ipairs(zzfps.frame_times) do
            total = total + dt;
        end

        local avg = (#zzfps.frame_times > 0) and (total / #zzfps.frame_times) or 0;
        local fps = (avg > 0) and (1 / avg) or 0;

        if (zzfps.settings.show_decimal) then
            fps = string.format('%.1f', fps);
        else
            fps = string.format('%d', math.floor(fps + 0.5));
        end

        if (zzfps.settings.show_label) then
            zzfps.font.text = 'FPS: ' .. fps;
        else
            zzfps.font.text = fps;
        end
    end
end);
