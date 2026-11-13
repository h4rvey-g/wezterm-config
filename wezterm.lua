local wezterm = require 'wezterm'
local mux = wezterm.mux

local config = wezterm.config_builder()

-- Font
local text_font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font Mono',
  { family = 'LXGW WenKai Mono', scale = 1.15 },
}

config.font = text_font
config.font_size = 16.0

config.color_scheme = 'Catppuccin Mocha'

-- Higher contrast text colors for readability over image backgrounds.
config.use_fancy_tab_bar = true
config.show_close_tab_button_in_tabs = true
config.window_close_confirmation = 'NeverPrompt'
config.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
  'cmd.exe',
  'pwsh.exe',
  'powershell.exe',
  'wezterm',
}
config.tab_max_width = 32
config.window_frame = {
  font = text_font,
  font_size = 18.0,
}

-- Make launcher/command palette overlays less noisy and visually aligned with the
-- rest of this config. The '+' button right-click handler below scopes the
-- launcher to only these custom entries, so WezTerm's built-in command dump
-- won't get in the way.
config.command_palette_font = text_font
config.command_palette_font_size = 15.0
config.command_palette_rows = 8
config.command_palette_bg_color = '#1e1e2e'
config.command_palette_fg_color = '#cdd6f4'
config.launcher_alphabet = 'arstneioqwfpbjluy;'

config.colors = {
  launcher_label_bg = { Color = '#cba6f7' },
  launcher_label_fg = { Color = '#1e1e2e' },
  input_selector_label_bg = { Color = '#cba6f7' },
  input_selector_label_fg = { Color = '#1e1e2e' },
  tab_bar = {
    background = '#181825',
    active_tab = {
      bg_color = '#cba6f7',
      fg_color = '#1e1e2e',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#313244',
      fg_color = '#cdd6f4',
    },
    inactive_tab_hover = {
      bg_color = '#45475a',
      fg_color = '#f5e0dc',
    },
    new_tab = {
      bg_color = '#181825',
      fg_color = '#cdd6f4',
    },
    new_tab_hover = {
      bg_color = '#cba6f7',
      fg_color = '#1e1e2e',
    },
  },
}

config.launch_menu = {
  {
    label = '  Local zsh',
    domain = 'DefaultDomain',
    args = { '/bin/zsh', '-l' },
  },
}

wezterm.on('new-tab-button-click', function(window, pane, button, default_action)
  if button == 'Right' then
    window:perform_action(
      wezterm.action.ShowLauncherArgs {
        flags = 'FUZZY|LAUNCH_MENU_ITEMS',
        title = 'New tab',
        help_text = '选择要打开的会话，Esc 取消，输入可过滤',
        fuzzy_help_text = '过滤: ',
      },
      pane
    )
    return false
  end

  -- Keep the built-in behavior for left/middle click.
  if default_action then
    window:perform_action(default_action, pane)
    return false
  end
end)

-- Cmd+T/N, Cmd+Shift+[/], and Cmd+1-9 use WezTerm's default bindings.
config.keys = {
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  {
    key = 'LeftArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  -- WezTerm names splits by pane arrangement, not divider orientation.
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'phys:Grave',
    mods = 'NONE',
    action = wezterm.action.SendString '`',
  },
}

-- Pick a random image from ~/Pictures/backdrops each time WezTerm loads.
local backdrop_dir = wezterm.config_dir .. '/backdrops'
local image_extensions = { 'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp' }
local backdrops = {}

for _, ext in ipairs(image_extensions) do
  for _, image in ipairs(wezterm.glob(backdrop_dir .. '/*.' .. ext)) do
    table.insert(backdrops, image)
  end
  for _, image in ipairs(wezterm.glob(backdrop_dir .. '/*.' .. string.upper(ext))) do
    table.insert(backdrops, image)
  end
end

table.sort(backdrops)

if #backdrops > 0 then
  math.randomseed(os.time())
  local image = backdrops[math.random(#backdrops)]

  config.background = {
    {
      source = { File = image },
      width = 'Cover',
      height = 'Cover',
      horizontal_align = 'Center',
      vertical_align = 'Middle',
      repeat_x = 'NoRepeat',
      repeat_y = 'NoRepeat',
      hsb = {
        brightness = 0.16,
        hue = 1.0,
        saturation = 1.0,
      },
    },
    {
      source = { Color = '#1e1e2e' },
      width = '100%',
      height = '100%',
      opacity = 0.68,
    },
  }
else
  wezterm.log_warn('No backdrop images found in ' .. backdrop_dir)
end

local function tab_title(tab)
  local title = tab.tab_title
  if title == nil or title == '' then
    title = tab.active_pane.title
  end
  return title
end

wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local title = ' ' .. tab_title(tab)
  title = wezterm.truncate_right(title, math.max(1, max_width - 2))

  local bg = '#313244'
  local fg = '#a6adc8'

  if tab.is_active then
    bg = '#cba6f7'
    fg = '#1e1e2e'
  end

  if hover and not tab.is_active then
    bg = '#45475a'
    fg = '#f5e0dc'
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
    { Text = '  ' .. title .. '  ' },
  }
end)

-- Maximize the initial GUI window on startup.
wezterm.on('gui-startup', function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

return config
