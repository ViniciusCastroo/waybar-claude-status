# waybar-claude-status

A minimal Waybar indicator for Claude Code activity.

It shows a quiet gray icon while idle, pulses yellow while Claude is working, then pulses the green icon for 15 seconds when a task finishes before returning to idle.

## Features

- Idle, busy, done, and hidden states
- Green completion pulse limited to the icon
- Supports multiple concurrent sessions with multiple Waybar slots
- Uses simple cache files under `$XDG_CACHE_HOME/ai-status.d`
- Works with Claude by default, with basic labels for other tools like Codex

## Files

- `scripts/ai-status.sh`: Waybar module script
- `scripts/ai-status-hook.py`: hook helper that writes status files
- `assets/`: SVG icons for idle, busy, and done states
- `examples/waybar-config.jsonc`: Waybar module snippet
- `examples/style.css`: CSS snippet for the indicator

## Install

Copy the scripts and assets into your Waybar config:

```sh
mkdir -p ~/.config/waybar/scripts ~/.config/waybar/assets
cp scripts/ai-status.sh scripts/ai-status-hook.py ~/.config/waybar/scripts/
cp assets/claudecode-*.svg ~/.config/waybar/assets/
chmod +x ~/.config/waybar/scripts/ai-status.sh ~/.config/waybar/scripts/ai-status-hook.py
```

Add the module snippet from `examples/waybar-config.jsonc` to your Waybar config, then merge `examples/style.css` into your Waybar stylesheet.

Reload Waybar after editing:

```sh
pkill -SIGUSR2 waybar
```

If your Waybar does not reload with `SIGUSR2`, restart it normally.

## Claude Code Hook

Use `ai-status-hook.py` from your Claude Code hooks or wrapper scripts:

```sh
~/.config/waybar/scripts/ai-status-hook.py busy claude
~/.config/waybar/scripts/ai-status-hook.py done claude
```

The hook also accepts JSON on stdin and tries to derive a stable session id from common fields such as `session_id`, `conversation_id`, `workspace.current_dir`, and `transcript_path`.

## Manual Test

You can test the Waybar output directly:

```sh
~/.config/waybar/scripts/ai-status-hook.py busy claude
~/.config/waybar/scripts/ai-status.sh 1

~/.config/waybar/scripts/ai-status-hook.py done claude
~/.config/waybar/scripts/ai-status.sh 1
```

Expected classes:

- `idle`: gray icon
- `busy`: yellow pulsing icon
- `done`: green pulsing icon for 15 seconds
- `hidden`: empty extra slot

## License

MIT
