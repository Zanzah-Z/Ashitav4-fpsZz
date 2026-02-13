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
addon.version   = '2.5a';
addon.desc      = 'Displays the current FPS on screen with customization. /zzfps help for commands/config';
addon.link      = 'https://github.com/Zanzah-Z/Ashitav4-Zzfps';

require('common')

local chat     = require('chat')
local fonts    = require('fonts')
local settings = require('settings')
local scaling  = require('scaling')

local os_clock = os.clock

-- Default Settings --
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
            -- Default alpha bg:
            color = 0xA0000000,
        },
        opacity = 1.0,
    },
    interval = 1,          -- Update interval in seconds (0 = real-time)
    show_decimal = false,
    show_label = false,
}

-- Main --
local zzfps = T{
    settings = settings.load(default_settings),
    font = nil,

    -- fps avg
    frame_times = T{},
    last_time = os_clock(),
    last_update = os_clock(),

    last_pos_sync = 0.0,
    pos_dirty_since = nil,
}

-- ------------------------------------------------------------
local function clamp(v, lo, hi)
    if (hi < lo) then return lo end
    if (v < lo) then return lo end
    if (v > hi) then return hi end
    return v
end

local function deepcopy(t)
    if type(t) ~= 'table' then return t end
    local r = {}
    for k, v in pairs(t) do
        r[k] = deepcopy(v)
    end
    return setmetatable(r, getmetatable(t))
end

local function ensure_color_alpha()
    local opacity = tonumber(zzfps.settings.font.opacity) or 1.0
    opacity = math.max(0.0, math.min(1.0, opacity))

    local alpha = math.floor(opacity * 255.0 + 0.5)
    local rgb = bit.band(zzfps.settings.font.color, 0x00FFFFFF)
    zzfps.settings.font.color = bit.bor(bit.lshift(alpha, 24), rgb)
end

local function apply_font()
    if (zzfps.font == nil) then return end
    ensure_color_alpha()
    zzfps.font:apply(zzfps.settings.font)
end

local function print_help()
    local h = chat.header(addon.name)
    print(h:append(chat.message('Commands:')))
    print(h:append(chat.message('  /zzfps help')))
    print(h:append(chat.message('  /zzfps reset')))
    print(h:append(chat.message('  /zzfps s <percent>        (50..400)')))
    print(h:append(chat.message('  /zzfps c <RRGGBB>         (ex: /zzfps c 00ff00)')))
    print(h:append(chat.message('  /zzfps bg                 (toggle background)')))
    print(h:append(chat.message('  /zzfps o <0.0..1.0>       (opacity)')))
    print(h:append(chat.message('  /zzfps i <0..60>          (interval seconds; 0=realtime)')))
    print(h:append(chat.message('  /zzfps f <font>           (ex: /zzfps f Consolas)')))
    print(h:append(chat.message('  /zzfps d                  (toggle decimals)')))
    print(h:append(chat.message('  /zzfps t                  (toggle label)')))
end

local function get_font_position()
    if (zzfps.font ~= nil) then
        if (type(zzfps.font.GetPositionX) == 'function' and type(zzfps.font.GetPositionY) == 'function') then
            return tonumber(zzfps.font:GetPositionX()) or zzfps.settings.font.position_x,
                   tonumber(zzfps.font:GetPositionY()) or zzfps.settings.font.position_y
        end
        if (zzfps.font.position_x ~= nil and zzfps.font.position_y ~= nil) then
            return tonumber(zzfps.font.position_x) or zzfps.settings.font.position_x,
                   tonumber(zzfps.font.position_y) or zzfps.settings.font.position_y
        end
    end
    return zzfps.settings.font.position_x, zzfps.settings.font.position_y
end

local function set_font_position(x, y)
    zzfps.settings.font.position_x = x
    zzfps.settings.font.position_y = y
    apply_font()
end

local function get_game_client_size()
    if (type(get_window_size_cached) == 'function') then
        local w, h = get_window_size_cached()
        w, h = tonumber(w), tonumber(h)
        if (w ~= nil and h ~= nil and w > 0 and h > 0) then
            return w, h
        end
    end
    return nil, nil
end

local function approx_text_bounds()
    -- CrashFix -- Avoid AshitaCore:GetFontManager():GetTextSize()
    local text = ''
    if (zzfps.font ~= nil and zzfps.font.text ~= nil) then
        text = tostring(zzfps.font.text)
    end

    local fh = tonumber(zzfps.settings.font.font_height) or scaling.scale_f(12)
    -- width estimate:
    local cw = fh * 0.60
    local w = math.floor((#text * cw) + 10)
    local h = math.floor(fh + 8)

    if (zzfps.settings.font.background ~= nil and zzfps.settings.font.background.visible) then
        w = w + 6
        h = h + 6
    end

    if (w < 20) then w = 20 end
    if (h < 12) then h = 12 end
    return w, h
end

local function persist_position_if_needed(now)
    -- Sync pos. Rate-limited.
    local x, y = get_font_position()
    x, y = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0)

    local sx = math.floor(tonumber(zzfps.settings.font.position_x) or 0)
    local sy = math.floor(tonumber(zzfps.settings.font.position_y) or 0)

    if (x ~= sx or y ~= sy) then
        if (zzfps.pos_dirty_since == nil) then
            zzfps.pos_dirty_since = now
        end
        if (now - zzfps.pos_dirty_since >= 0.25) then
            zzfps.settings.font.position_x = x
            zzfps.settings.font.position_y = y
            settings.save()
            zzfps.pos_dirty_since = nil
        end
    else
        zzfps.pos_dirty_since = nil
    end
end

local function clamp_to_window()
    local sw, sh = get_game_client_size()
    if (sw == nil or sh == nil) then return end

    local ww, wh = approx_text_bounds()
    local x, y = get_font_position()

    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)

    local nx = clamp(x, 0, math.floor(sw - ww))
    local ny = clamp(y, 0, math.floor(sh - wh))

    if (nx ~= x or ny ~= y) then
        set_font_position(nx, ny)
        settings.save()
    end
end

-- ------------------------------------------------------------
settings.register('settings', 'settings_update', function(s)
    if (s ~= nil) then
        zzfps.settings = s
    end
    apply_font()
    settings.save()
end)

-- ------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
    zzfps.font = fonts.new(zzfps.settings.font)
    apply_font()
end)

ashita.events.register('unload', 'unload_cb', function()
    -- Pos sync
    local now = os_clock()
    persist_position_if_needed(now)
    clamp_to_window()

    if (zzfps.font ~= nil) then
        zzfps.font:destroy()
        zzfps.font = nil
    end
end)

ashita.events.register('command', 'command_cb', function(e)
    local cmd = e.command
    if (cmd == nil or cmd == '') then return end

    local args = cmd:split(' ')
    if (#args == 0) then return end

    if (args[1]:lower() ~= '/zzfps') then
        return
    end

    local sub = (#args >= 2) and args[2]:lower() or 'help'

    if (sub == 'help' or sub == '?') then
        print_help()

    elseif (sub == 'reset') then
        zzfps.settings = deepcopy(default_settings)
        apply_font()
        settings.save()
        print(chat.header(addon.name):append(chat.message('Settings reset.')))

    elseif (sub == 's' and args[3] ~= nil) then
        local val = tonumber(args[3])
        if (val ~= nil) then
            val = math.max(50, math.min(400, val))
            zzfps.settings.font.font_height = scaling.scale_f((val / 100.0) * 12.0)
            apply_font()
            settings.save()
        end

    elseif (sub == 'c' and args[3] ~= nil) then
        local hex = tonumber(args[3], 16)
        if (hex ~= nil) then
            zzfps.settings.font.color = bit.bor(bit.band(zzfps.settings.font.color, 0xFF000000), bit.band(hex, 0x00FFFFFF))
            apply_font()
            settings.save()
        end

    elseif (sub == 'bg') then
        zzfps.settings.font.background.visible = not zzfps.settings.font.background.visible
        -- If transparent background, fix it
        if (zzfps.settings.font.background.visible) then
            if (bit.band(zzfps.settings.font.background.color, 0xFF000000) == 0x00000000) then
                zzfps.settings.font.background.color = 0xA0000000
            end
        end
        apply_font()
        settings.save()

    elseif (sub == 'o' and args[3] ~= nil) then
        local opacity = tonumber(args[3])
        if (opacity ~= nil) then
            zzfps.settings.font.opacity = math.max(0.0, math.min(1.0, opacity))
            apply_font()
            settings.save()
        end

    elseif (sub == 'i' and args[3] ~= nil) then
        local interval = tonumber(args[3])
        if (interval ~= nil) then
            zzfps.settings.interval = math.max(0, math.min(60, interval))
            settings.save()
        end

    elseif (sub == 'f' and args[3] ~= nil) then
        local font_name = args[3]
        if (font_name ~= nil and font_name ~= '') then
            local old = zzfps.settings.font.font_family
            zzfps.settings.font.font_family = font_name

            local ok = pcall(function()
                apply_font()
            end)

            if (not ok) then
                zzfps.settings.font.font_family = old
                apply_font()
            else
                settings.save()
            end
        end

    elseif (sub == 'd') then
        zzfps.settings.show_decimal = not zzfps.settings.show_decimal
        settings.save()

    elseif (sub == 't') then
        zzfps.settings.show_label = not zzfps.settings.show_label
        settings.save()

    else
        print_help()
    end

    e.blocked = true
end)

ashita.events.register('d3d_present', 'present_cb', function()
    if (zzfps.font == nil) then
        return
    end

    local now = os_clock()

    -- FPS calc
    local delta = now - zzfps.last_time
    zzfps.last_time = now

    table.insert(zzfps.frame_times, delta)
    if (#zzfps.frame_times > 100) then
        table.remove(zzfps.frame_times, 1)
    end

    if (zzfps.settings.interval == 0 or (now - zzfps.last_update >= zzfps.settings.interval)) then
        zzfps.last_update = now

        local total = 0
        for _, dt in ipairs(zzfps.frame_times) do
            total = total + dt
        end

        local avg = (#zzfps.frame_times > 0) and (total / #zzfps.frame_times) or 0
        local fps = (avg > 0) and (1 / avg) or 0

        if (zzfps.settings.show_decimal) then
            fps = string.format('%.1f', fps)
        else
            fps = string.format('%d', math.floor(fps + 0.5))
        end

        if (zzfps.settings.show_label) then
            zzfps.font.text = 'FPS: ' .. fps
        else
            zzfps.font.text = fps
        end
    end

    persist_position_if_needed(now)
    clamp_to_window()
end)
