--[[
__________                            .__
\____    /____    ____ _____________  |  |__       ____  ____   _____
  /     /\__  \  /    \\___   /\__  \ |  |  \    _/ ___\/  _ \ /     \
 /     /_ / __ \|   |  \/    /  / __ \|   Y  \   \  \__(  <_> )  Y Y  \
/_______ (____  /___|  /_____ \(____  /___|  / /\ \___  >____/|__|_|  /
        \/    \/     \/      \/     \/     \/  \/     \/            \/



- Commands:
    Hold SHIFT then click>drag to reposition overlay.

    /zzfps s <50-400>       : scale (percent)
    /zzfps c <RRGGBB>       : color
    /zzfps bg               : toggle background
    /zzfps o <0.0-1.0>      : opacity
    /zzfps i <0-60>         : update interval seconds (0 = realtime)
    /zzfps f <fontname>     : font family
    /zzfps d                : toggle decimal
    /zzfps t                : toggle "FPS:" label
    /zzfps reset            : reset position + settings to defaults
	/zzfps help             : list commands in game
]]--

addon.name      = 'Zzfps';
addon.author    = 'Zanzah';
addon.version   = '2.5';
addon.desc      = 'Displays the current FPS on screen with customization. /zzfps help for commands/config';
addon.link      = 'https://github.com/Zanzah-Z/Ashitav4-Zzfps';

require('common');
local fonts     = require('fonts');
local settings  = require('settings');
local scaling   = require('scaling');
local chat      = require('chat');

local os_clock  = os.clock;

local has_ffi, ffi = pcall(require, 'ffi');
local SIZE_ARR = nil;
if (has_ffi) then
    pcall(function ()
        ffi.cdef[[
            typedef long LONG;
            typedef struct tagSIZE { LONG cx; LONG cy; } SIZE;
        ]];
        SIZE_ARR = ffi.typeof('SIZE[1]');
    end);
end

-- Build defaults
local function make_default_settings()
    return T{
        font = T{
            visible = true,
            font_family = 'Arial',
            font_height = scaling.scale_f(12),
            color = 0xFF00FF00,
            position_x = 130,
            position_y = 0,
            background = T{
                visible = false,
                -- Non-zero alpha for /zzfps bg.
                color = 0x80000000,
            },
        },
        interval = 1, -- Update interval in seconds (0 = real-time)
        show_decimal = false,
        show_label = false,
    };
end

-- Main --
local zzfps = T{
    settings = settings.load(make_default_settings()),
    font = nil,

    frame_times = T{},
    last_time = os_clock(),
    last_update = os_clock(),

    last_pos_x = nil,
    last_pos_y = nil,
    pos_dirty = false,
    pos_dirty_time = 0,
};

-- ------------------------------------------------------------
local function get_font_object()
    if (zzfps.font == nil) then
        return nil;
    end

    if (type(zzfps.font) == 'userdata') then
        return zzfps.font;
    end

    if (type(zzfps.font) == 'table') then
        for _, k in ipairs({ 'object', 'obj', '_object', '_obj', '_font', 'font_object', 'font' }) do
            if (zzfps.font[k] ~= nil and type(zzfps.font[k]) == 'userdata') then
                return zzfps.font[k];
            end
        end
    end

    -- If not found, call zzfps.font.
    return zzfps.font;
end

local function font_get_pos()
    local fo = get_font_object();
    if (fo ~= nil and fo.GetPositionX ~= nil) then
        return tonumber(fo:GetPositionX()), tonumber(fo:GetPositionY());
    end
    if (type(zzfps.font) == 'table' and zzfps.font.position_x ~= nil) then
        return tonumber(zzfps.font.position_x), tonumber(zzfps.font.position_y);
    end
    return tonumber(zzfps.settings.font.position_x), tonumber(zzfps.settings.font.position_y);
end

local function font_set_pos(x, y)
    local fo = get_font_object();
    if (fo ~= nil and fo.SetPositionX ~= nil) then
        fo:SetPositionX(x);
        fo:SetPositionY(y);
        return;
    end

    zzfps.settings.font.position_x = x;
    zzfps.settings.font.position_y = y;
    if (zzfps.font ~= nil and zzfps.font.apply ~= nil) then
        zzfps.font:apply(zzfps.settings.font);
    end
end

local function font_get_window_size()
    local fo = get_font_object();
    if (fo ~= nil and fo.GetWindowWidth ~= nil) then
        return tonumber(fo:GetWindowWidth()), tonumber(fo:GetWindowHeight());
    end
    return nil, nil;
end

local function font_get_text_size()
    local fo = get_font_object();
    if (not has_ffi or SIZE_ARR == nil or fo == nil or fo.GetTextSize == nil) then
        return nil, nil;
    end

    local s = SIZE_ARR();
    fo:GetTextSize(s);
    return tonumber(s[0].cx), tonumber(s[0].cy);
end

local function mark_pos_dirty(now)
    zzfps.pos_dirty = true;
    zzfps.pos_dirty_time = now;
end

local function track_and_persist_position(now)
    local x, y = font_get_pos();
    if (x == nil or y == nil) then
        return;
    end

    x = math.floor(x + 0.5);
    y = math.floor(y + 0.5);

    if (zzfps.last_pos_x ~= x or zzfps.last_pos_y ~= y) then
        zzfps.last_pos_x = x;
        zzfps.last_pos_y = y;
        zzfps.settings.font.position_x = x;
        zzfps.settings.font.position_y = y;
        mark_pos_dirty(now);
    end
end

local function clamp_to_window(now)
    local w, h = font_get_window_size();
    if (w == nil or h == nil) then
        return;
    end

    local x, y = font_get_pos();
    if (x == nil or y == nil) then
        return;
    end

    local tw, th = font_get_text_size();
    if (tw == nil or th == nil) then
        -- keep origin non-negative.
        local nx = math.max(0, x);
        local ny = math.max(0, y);
        if (nx ~= x or ny ~= y) then
            font_set_pos(nx, ny);
            zzfps.settings.font.position_x = nx;
            zzfps.settings.font.position_y = ny;
            track_and_persist_position(now);
        end
        return;
    end

    local pad = 1;
    local max_x = math.max(0, w - tw - pad);
    local max_y = math.max(0, h - th - pad);

    local nx = math.min(math.max(x, 0), max_x);
    local ny = math.min(math.max(y, 0), max_y);

    if (nx ~= x or ny ~= y) then
        font_set_pos(nx, ny);
        zzfps.settings.font.position_x = nx;
        zzfps.settings.font.position_y = ny;
        zzfps.last_pos_x = nx;
        zzfps.last_pos_y = ny;
        mark_pos_dirty(now);
    end
end

local function maybe_save_settings(now)
    if (zzfps.pos_dirty and (now - zzfps.pos_dirty_time) >= 0.25) then
        settings.save();
        zzfps.pos_dirty = false;
    end
end

-- ------------------------------------------------------------
settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        zzfps.settings = s;
    end

    if (zzfps.font ~= nil) then
        zzfps.font:apply(zzfps.settings.font);
    end

    settings.save();
end);

-- ------------------------------------------------------------
ashita.events.register('load', 'load_cb', function ()
    zzfps.font = fonts.new(zzfps.settings.font);

    -- detect user drag changes
    local now = os_clock();
    track_and_persist_position(now);
    maybe_save_settings(now);
end);

ashita.events.register('unload', 'unload_cb', function ()
    -- Persist latest position.
    local now = os_clock();
    track_and_persist_position(now);
    settings.save();

    if (zzfps.font ~= nil) then
        zzfps.font:destroy();
        zzfps.font = nil;
    end
end);

local function print_help()
    local h = chat.header(addon.name);
    print(h:append(chat.message('Commands:')));
    print(h:append(chat.message('  /zzfps help                 - this help')));
    print(h:append(chat.message('  /zzfps reset                - reset to defaults (incl. position)')));
    print(h:append(chat.message('  /zzfps s <50-400>           - scale percent (100 = default size)')));
    print(h:append(chat.message('  /zzfps c <RRGGBB>           - color (hex)')));
    print(h:append(chat.message('  /zzfps bg                   - toggle background')));
    print(h:append(chat.message('  /zzfps o <0.0-1.0>          - opacity')));
    print(h:append(chat.message('  /zzfps i <0-60>             - update interval seconds (0 = realtime)')));
    print(h:append(chat.message('  /zzfps f <FontName>         - font family')));
    print(h:append(chat.message('  /zzfps d                    - toggle decimal')));
    print(h:append(chat.message('  /zzfps t                    - toggle FPS label')));
    print(h:append(chat.message('Drag: hold SHIFT to click and reposition the overlay.')));
end

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:split(' ');
    if (#args == 0) then
        return;
    end

    local cmd = args[1]:lower();
    if (cmd ~= '/zzfps') then
        return;
    end

    local sub = (#args >= 2) and args[2]:lower() or 'help';

    if (sub == 'help' or sub == '?') then
        print_help();

    elseif (sub == 'reset') then
        zzfps.settings = make_default_settings();
        if (zzfps.font ~= nil) then
            zzfps.font:apply(zzfps.settings.font);
        end
        settings.save();
        print(chat.header(addon.name):append(chat.message('Settings reset to defaults.')));

    elseif (sub == 's' and args[3] ~= nil) then
        local val = tonumber(args[3]);
        if (val ~= nil) then
            val = math.max(50, math.min(400, val));
            zzfps.settings.font.font_height = scaling.scale_f((val / 100) * 12);
            if (zzfps.font ~= nil) then
                zzfps.font:apply(zzfps.settings.font);
            end
            settings.save();
        end

    elseif (sub == 'c' and args[3] ~= nil) then
        local hex = tonumber(args[3], 16);
        if (hex ~= nil) then
            zzfps.settings.font.color = bit.bor(0xFF000000, hex);
            if (zzfps.font ~= nil) then
                zzfps.font:apply(zzfps.settings.font);
            end
            settings.save();
        end

    elseif (sub == 'bg') then
        zzfps.settings.font.background.visible = not zzfps.settings.font.background.visible;

        -- If bkg = alpha 0, make visible.
        if (zzfps.settings.font.background.visible) then
            local a = bit.band(zzfps.settings.font.background.color, 0xFF000000);
            if (a == 0) then
                zzfps.settings.font.background.color = 0x80000000;
            end
        end

        if (zzfps.font ~= nil) then
            zzfps.font:apply(zzfps.settings.font);
        end
        settings.save();

    elseif (sub == 'o' and args[3] ~= nil) then
        local opacity = tonumber(args[3]);
        if (opacity ~= nil) then
            opacity = math.max(0.0, math.min(1.0, opacity));
            local alpha = math.floor(opacity * 255);
            local col = bit.band(zzfps.settings.font.color, 0x00FFFFFF);
            zzfps.settings.font.color = bit.bor(bit.lshift(alpha, 24), col);
            if (zzfps.font ~= nil) then
                zzfps.font:apply(zzfps.settings.font);
            end
            settings.save();
        end

    elseif (sub == 'i' and args[3] ~= nil) then
        local interval = tonumber(args[3]);
        if (interval ~= nil) then
            zzfps.settings.interval = math.max(0, math.min(60, interval));
            settings.save();
        end

    elseif (sub == 'f' and args[3] ~= nil) then
        local font_name = args[3];
        if (font_name ~= nil and font_name ~= '') then
            local old_font = zzfps.settings.font.font_family;
            zzfps.settings.font.font_family = font_name;

            local ok = pcall(function ()
                if (zzfps.font ~= nil) then
                    zzfps.font:apply(zzfps.settings.font);
                end
            end);

            if (not ok) then
                zzfps.settings.font.font_family = old_font;
                if (zzfps.font ~= nil) then
                    zzfps.font:apply(zzfps.settings.font);
                end
            else
                settings.save();
            end
        end

    elseif (sub == 'd') then
        zzfps.settings.show_decimal = not zzfps.settings.show_decimal;
        settings.save();

    elseif (sub == 't') then
        zzfps.settings.show_label = not zzfps.settings.show_label;
        settings.save();

    else
        print_help();
    end

    e.blocked = true;
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    if (zzfps.font == nil) then
        return;
    end

    local now = os_clock();

    -- Track pos changes.
    track_and_persist_position(now);
    clamp_to_window(now);
    maybe_save_settings(now);

    -- FPS calc.
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
