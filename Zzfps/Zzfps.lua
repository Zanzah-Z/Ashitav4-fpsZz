--[[
__________                            .__
\____    /____    ____ _____________  |  |__       ____  ____   _____
  /     /\__  \  /    \\\___   /\__  \ |  |  \    _/ ___\\/  _ \ /     \
 /     /_ / __ \|   |  \/    /  / __ \|   Y  \   \  \__(  <_> )  Y Y  \
/_______ (____  /___|  /_____ \(____  /___|  / /\ \___  >____/|__|_|  /
        \/    \/     \/      \/     \/     \/  \/     \/            \/
]]

addon.name      = 'Zzfps';
addon.author    = 'Zanzah';
addon.version   = '2.0';
addon.desc      = 'Displays the current FPS on screen with customization. Commands/Config @: Github or Zanzah.com/fpszz (redirects to Github)';
addon.link      = 'https://github.com/Zanzah-Z/Ashitav4-fpsZz';

require('common');

local fonts     = require('fonts');
local settings  = require('settings');
local scaling   = require('scaling');

local os_clock  = os.clock;

-- Default Settings
local default_settings = T{
    font = T{
        visible = true,
        font_family = 'Arial',
        font_height = scaling.scale_f(12),
        color = 0xFF00FF00,
        position_x = 130,
        position_y = 0,
        background = T{
            visible = false,
            color = 0x00000000,
        },
        opacity = 1.0,
    },
    interval = 1,        -- seconds (0 = real-time)
    show_decimal = false,
    show_label = false,
};

-- Main Object
local zzfps = T{
    settings = settings.load(default_settings),
    font = nil,

    frame_times = T{},
    last_time = os_clock(),
    last_update = os_clock(),

    -- Position persistence (throttled)
    last_pos_save = 0,
    pos_save_interval = 0.25, -- seconds

    previous_font = 'Arial',
};

-- Apply settings + auto-save (settings lib handles per-character addon configs)
settings.register('settings', 'settings_update', function(s)
    if (s ~= nil) then
        zzfps.settings = s;
    end

    if (zzfps.font ~= nil) then
        zzfps.font:apply(zzfps.settings.font);
    end

    settings.save();
end);

-- Helpers
local function clamp(v, a, b)
    if (v < a) then return a end
    if (v > b) then return b end
    return v
end

local function save_position_if_changed(now)
    if (zzfps.font == nil) then return end

    local f = zzfps.font;
    if (f.position_x ~= zzfps.settings.font.position_x) or (f.position_y ~= zzfps.settings.font.position_y) then
        zzfps.settings.font.position_x = f.position_x;
        zzfps.settings.font.position_y = f.position_y;

        if ((now - zzfps.last_pos_save) >= zzfps.pos_save_interval) then
            zzfps.last_pos_save = now;
            settings.save();
        end
    end
end

-- Events
ashita.events.register('load', 'load_cb', function()
    zzfps.font = fonts.new(zzfps.settings.font);
end);

ashita.events.register('unload', 'unload_cb', function()
    -- Save one last time on unload (position + any pending changes)
    settings.save();

    if (zzfps.font ~= nil) then
        zzfps.font:destroy();
        zzfps.font = nil;
    end
end);

ashita.events.register('command', 'command_cb', function(e)
    -- Commands:
    -- /zzfps s <50-400>     (scale %)
    -- /zzfps c <RRGGBB>     (hex, no 0x, alpha auto)
    -- /zzfps bg             (toggle background)
    -- /zzfps o <0.0-1.0>    (opacity)
    -- /zzfps i <0-60>       (interval seconds)
    -- /zzfps f <fontname>   (font family)
    -- /zzfps d              (toggle decimal)
    -- /zzfps t              (toggle label)
    -- /zzfps help

    local args = e.command:split(' ');
    if (#args == 0) then return end

    local cmd = (args[1] or ''):lower();
    if (cmd ~= '/zzfps') then
        return;
    end

    local sub = (args[2] or ''):lower();

    if (sub == '' or sub == 'help') then
        print('[zzfps] Commands: /zzfps s <50-400>, c <RRGGBB>, bg, o <0-1>, i <0-60>, f <font>, d, t');
        e.blocked = true;
        return;
    end

    if (sub == 's' and args[3]) then
        local val = tonumber(args[3]);
        if (val) then
            val = clamp(val, 50, 400);
            zzfps.settings.font.font_height = scaling.scale_f((val / 100) * 12);
            if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
        end

    elseif (sub == 'c' and args[3]) then
        local hex = tonumber(args[3], 16);
        if (hex) then
            zzfps.settings.font.color = bit.bor(0xFF000000, hex);
            if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
        end

    elseif (sub == 'bg') then
        zzfps.settings.font.background.visible = not zzfps.settings.font.background.visible;
        if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end

    elseif (sub == 'o' and args[3]) then
        local opacity = tonumber(args[3]);
        if (opacity) then
            opacity = clamp(opacity, 0.0, 1.0);
            local alpha = math.floor(opacity * 255);
            local col = bit.band(zzfps.settings.font.color, 0x00FFFFFF);
            zzfps.settings.font.color = bit.bor(bit.lshift(alpha, 24), col);
            if (zzfps.font) then zzfps.font:apply(zzfps.settings.font); end
        end

    elseif (sub == 'i' and args[3]) then
        local interval = tonumber(args[3]);
        if (interval) then
            zzfps.settings.interval = clamp(interval, 0, 60);
        end

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
            else
                zzfps.previous_font = font_name;
            end
        end

    elseif (sub == 'd') then
        zzfps.settings.show_decimal = not zzfps.settings.show_decimal;

    elseif (sub == 't') then
        zzfps.settings.show_label = not zzfps.settings.show_label;
    end

    settings.save();
    e.blocked = true;
end);

ashita.events.register('d3d_present', 'present_cb', function()
    if (zzfps.font == nil) then
        return;
    end

    local now = os_clock();

    -- Persist position (if user drags/moves via Ashita font system/UI)
    save_position_if_changed(now);

    -- FPS tracking
    local delta = now - zzfps.last_time;
    zzfps.last_time = now;

    table.insert(zzfps.frame_times, delta);
    if (#zzfps.frame_times > 100) then
        table.remove(zzfps.frame_times, 1);
    end

    if (zzfps.settings.interval == 0) or ((now - zzfps.last_update) >= zzfps.settings.interval) then
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
