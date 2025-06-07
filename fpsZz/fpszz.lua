--[[
__________                            .__
\____    /____    ____ _____________  |  |__       ____  ____   _____
  /     /\__  \  /    \\\___   /\__  \ |  |  \    _/ ___\\/  _ \ /     \
 /     /_ / __ \|   |  \/    /  / __ \|   Y  \   \  \__(  <_> )  Y Y  \
/_______ (____  /___|  /_____ \(____  /___|  / /\ \___  >____/|__|_|  /
        \/    \/     \/      \/     \/     \/  \/     \/            \/
]]

addon.name      = 'fpszz';
addon.author    = 'Zanzah';
addon.version   = '1.9';
addon.desc      = 'Displays the current FPS on screen with customization.';
addon.link      = 'https://www.Zanzah.com';

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
    interval = 1, -- Update interval in seconds (0 = real-time)
    show_decimal = false,
    show_label = false,
};

-- Main Object
local fpszz = T{
    settings = settings.load(default_settings),
    font = nil,
    frame_times = T{},
    last_time = os_clock(),
    last_update = os_clock(),
    previous_font = 'Arial',
};

settings.register('settings', 'settings_update', function(s)
    if (s ~= nil) then
        fpszz.settings = s;
    end
    if (fpszz.font ~= nil) then
        fpszz.font:apply(fpszz.settings.font);
    end
    settings.save();
end);

ashita.events.register('load', 'load_cb', function()
    fpszz.font = fonts.new(fpszz.settings.font);
end);

ashita.events.register('unload', 'unload_cb', function()
    if (fpszz.font ~= nil) then
        fpszz.font:destroy();
        fpszz.font = nil;
    end
end);

ashita.events.register('command', 'command_cb', function(e)
    local args = e.command:lower():split(' ');
    if (#args == 0 or args[1] ~= '/fpszz') then
        return;
    end

    if args[2] == 's' and args[3] then
        local val = tonumber(args[3]);
        if val then
            val = math.max(50, math.min(400, val));
            fpszz.settings.font.font_height = scaling.scale_f(val / 100 * 12);
            fpszz.font:apply(fpszz.settings.font);
        end
    elseif args[2] == 'c' and args[3] then
        local hex = tonumber(args[3], 16);
        if hex then
            fpszz.settings.font.color = bit.bor(0xFF000000, hex);
            fpszz.font:apply(fpszz.settings.font);
        end
    elseif args[2] == 'bg' then
        fpszz.settings.font.background.visible = not fpszz.settings.font.background.visible;
        fpszz.font:apply(fpszz.settings.font);
    elseif args[2] == 'o' and args[3] then
        local opacity = tonumber(args[3]);
        if opacity then
            opacity = math.max(0.0, math.min(1.0, opacity));
            local alpha = math.floor(opacity * 255);
            local col = bit.band(fpszz.settings.font.color, 0x00FFFFFF);
            fpszz.settings.font.color = bit.bor(bit.lshift(alpha, 24), col);
            fpszz.font:apply(fpszz.settings.font);
        end
    elseif args[2] == 'i' and args[3] then
        local interval = tonumber(args[3]);
        if interval then
            fpszz.settings.interval = math.max(0, math.min(60, interval));
        end
    elseif args[2] == 'f' and args[3] then
        local font_name = args[3];
        if font_name and font_name ~= '' then
            local old_font = fpszz.settings.font.font_family;
            fpszz.settings.font.font_family = font_name;
            local success = pcall(function()
                fpszz.font:apply(fpszz.settings.font);
            end);
            if not success then
                fpszz.settings.font.font_family = old_font;
                fpszz.font:apply(fpszz.settings.font);
            else
                fpszz.previous_font = font_name;
            end
        end
    elseif args[2] == 'd' then
        fpszz.settings.show_decimal = not fpszz.settings.show_decimal;
    elseif args[2] == 't' then
        fpszz.settings.show_label = not fpszz.settings.show_label;
    end

    settings.save();
    e.blocked = true;
end);

ashita.events.register('d3d_present', 'present_cb', function()
    if (fpszz.font == nil) then
        return;
    end

    local now = os_clock();
    local delta = now - fpszz.last_time;
    fpszz.last_time = now;

    table.insert(fpszz.frame_times, delta);
    if (#fpszz.frame_times > 100) then
        table.remove(fpszz.frame_times, 1);
    end

    if fpszz.settings.interval == 0 or (now - fpszz.last_update >= fpszz.settings.interval) then
        fpszz.last_update = now;

        local total = 0;
        for _, dt in ipairs(fpszz.frame_times) do
            total = total + dt;
        end

        local avg = (#fpszz.frame_times > 0) and (total / #fpszz.frame_times) or 0;
        local fps = (avg > 0) and (1 / avg) or 0;

        if fpszz.settings.show_decimal then
            fps = string.format('%.1f', fps);
        else
            fps = string.format('%d', math.floor(fps + 0.5));
        end

        if fpszz.settings.show_label then
            fpszz.font.text = 'FPS: ' .. fps;
        else
            fpszz.font.text = fps;
        end
    end
end);

