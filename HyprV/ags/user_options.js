// For every option, see ~/.config/ags/modules/.configuration/user_options.js
// (vscode users ctrl+click this: file://./modules/.configuration/user_options.js)
// (vim users: `:vsp` to split window, move cursor to this path, press `gf`. `Ctrl-w` twice to switch between)
//   options listed in this file will override the default ones in the above file

const userConfigOptions = {
    'brightness': {
        // Object of controller names for each monitor, either "brightnessctl" or "ddcutil" or "auto"
        // 'default' one will be used if unspecified
        // Examples
        // 'eDP-1': "brightnessctl",
        // 'DP-1': "ddcutil",
        'controllers': {
            'default': "auto",
            'eDP-1': "brightnessctl",
            'DP-1': "ddcutil",
            'DP-2': "ddcutil",
            'DP-3': "ddcutil",
            'DP-4': "ddcutil"
        },
    },
    'overview': {
        'scale': 0.18, // Relative to screen size
        'numOfRows': 0,
        'numOfCols': 0,
        'wsNumScale': 0.09,
        'wsNumMarginScale': 0.07,
    },
    'sidebar': {
        'ai': {
            'extraGptModels': {
                'oxygen3': {
                    'name': 'Ali-Qwen',
                    'logo_name': 'ai-oxygen-symbolic',
                    'description': 'An API from Tornado Softwares\nPricing: Free: 100/day\nRequires you to join their Discord for a key',
                    'base_url': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
                    'key_file': 'oxygen_key.txt',
                    'model': 'qwen2-72b-instruct',
                },
            }
        },
        'image': {
            'columns': 2,
            'batchCount': 20,
            'allowNsfw': false,
            'saveInFolderByTags': false,
        },
        'pages': {
            'order': ["apis", "tools"],
            'apis': {
                'order': ["gpt", "gemini", "waifu", "booru"],
            }
        },
    },
    'weather': {
        'city': "Suzhou",
        'preferredUnit': "C", // Either C or F
    },
    'apps': {
        'bluetooth': "blueberry",
        'imageViewer': "loupe",
        'network': "XDG_CURRENT_DESKTOP=\"gnome\" gnome-control-center wifi",
        'settings': "XDG_CURRENT_DESKTOP=\"gnome\" gnome-control-center",
        'taskManager': "gnome-usage",
        'terminal': "kitty", // This is only for shell actions
    },
    'appearance': {
        'autoDarkMode': { // Turns on dark mode in certain hours. Time in 24h format
            'enabled': false,
            'from': "18:10",
            'to': "6:10",
        },
        'keyboardUseFlag': false, // Use flag emoji instead of abbreviation letters
        'layerSmoke': false,
        'layerSmokeStrength': 0.2,
        'barRoundCorners': 0, // 0: No, 1: Yes
        'fakeScreenRounding': 1, // 0: None | 1: Always | 2: When not fullscreen
    },
    'cheatsheet': {
        'keybinds': {
            'configPath': "/home/wilf/.config/hypr/hyprland-bind.conf" // Path to hyprland keybind config file. Leave empty for default (~/.config/hypr/hyprland/keybinds.conf)
        }
    },
    'icons': {
        // Find the window's icon by its class with levenshteinDistance
        // The file names are processed at startup, so if there
        // are too many files in the search path it'll affect performance
        // Example: ['/usr/share/icons/Tela-nord/scalable/apps']
        'searchPaths': ['/home/wilf/.local/share/icons/Windows-Eleven/apps/scalable/','/home/wilf/.local/share/icons/hicolor/256x256/apps/','/home/wilf/.local/share/icons/Mkos-Big-Sur/128x128@2x/apps'],
        'symbolicIconTheme': {
            "dark": "Adwaita",
            "light": "Adwaita",
        },
        substitutions: {
            'chrome-calendarR': 'calendar',
            'kitty-dropdown':'kitty',
            'code-url-handler': "visual-studio-code",
            'Code': "visual-studio-code",
            'GitHub Desktop': "github-desktop",
            'Minecraft* 1.20.1': "minecraft",
            'gnome-tweaks': "org.gnome.tweaks",
            'pavucontrol-qt': "pavucontrol",
            'wps': "wps-office2019-kprometheus",
            'wpsoffice': "wps-office2019-kprometheus",
            '': "image-missing",
        },
        regexSubstitutions: [
            {
                regex: /^steam_app_(\d+)$/,
                replace: "steam_icon_$1",
            }
        ]
    },
    'dock': {
        'enabled': true,
        'hiddenThickness': 5,
        'pinnedApps': [],
        'layer': 'top',
        'monitorExclusivity': true, // Dock will move to other monitor along with focus if enabled
        'searchPinnedAppIcons': true, // Try to search for the correct icon if the app class isn't an icon name
        'trigger': ['client-added', 'client-removed'], // client_added, client_move, workspace_active, client_active
        // Automatically hide dock after `interval` ms since trigger
        'autoHide': [
            {
                'trigger': 'client-added',
                'interval': 500,
            },
            {
                'trigger': 'client-removed',
                'interval': 500,
            },
        ],
    },
}

export default userConfigOptions;
