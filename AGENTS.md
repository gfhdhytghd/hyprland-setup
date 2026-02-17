# Repo Notes for Agents

## Monitor config: local vs public

- Local (machine-specific) monitor layouts are allowed in `~/.config/HyprV/` only.
- Public repo version must stay generic and portable.

Public requirements:

- Keep only `HyprV/hypr/hyprland-monitors.conf`.
- Do not add `HyprV/hypr/hyprland-monitors-1.conf` or `HyprV/hypr/hyprland-monitors-2.conf`.
- `HyprV/hypr/hyprland-monitors.conf` must be a regular file (not a symlink).
- Use generic monitor line:

```conf
monitor = , preferred, auto, auto
```

Before commit/push:

- If syncing from `~/.config/HyprV/`, re-check monitor files and remove machine-specific settings.
- Ensure no keybind/script toggles between monitor preset files.
