#!/usr/bin/env bash

# Wait for Niri to be fully loaded
while ! niri msg workspaces >/dev/null 2>&1; do
    sleep 0.2
done

# Logging for debug
exec >/tmp/niri-startup.log 2>&1
set -x

echo "Starting Niri workspace configuration..."

# Helper to launch a command and move the resulting window to a specific workspace.
# Works by detecting the new window ID for a given app_id.
launch_on_workspace() {
    local target_ws="$1"
    local app_id="$2"
    shift 2
    local cmd=("$@")
    
    # Get list of existing window IDs for this app_id
    local pre_ids=$(niri msg --json windows | jq -r --arg app "$app_id" '.[] | select(.app_id == $app) | .id')
    
    # Launch the command fully detached, with all stdio pointed away from the
    # command-substitution pipe. Otherwise the long-lived GUI process inherits
    # this function's stdout (the $() pipe), so the caller's `id=$(...)` blocks
    # forever waiting for EOF that never comes (the app doesn't exit). That is
    # what hung the script right after the very first window. setsid also keeps
    # the launched app alive in its own session.
    setsid "${cmd[@]}" >/dev/null 2>&1 </dev/null &

    # Wait for the new window ID to appear
    for i in {1..50}; do
        local post_ids=$(niri msg --json windows | jq -r --arg app "$app_id" '.[] | select(.app_id == $app) | .id')
        local new_id=$(comm -13 <(echo "$pre_ids" | sort) <(echo "$post_ids" | sort) | head -n 1)
        if [ -n "$new_id" ] && [ "$new_id" != "null" ]; then
            # niri uses --window-id (not --id) for this action; <REFERENCE> is positional.
            niri msg action move-window-to-workspace --window-id "$new_id" "$target_ws"
            echo "$new_id"
            return 0
        fi
        sleep 0.2
    done
    return 1
}

# --- 1. SYSTEM WORKSPACE ---
echo "Configuring system workspace..."

# Launch clock (tuime) and zenith
clock_id=$(launch_on_workspace "system" "com.mitchellh.ghostty" ghostty --title="system-clock" -e tuime)
zenith_id=$(launch_on_workspace "system" "com.mitchellh.ghostty" ghostty --title="system-zenith" -e zenith)

# Merge zenith into the clock's column (vertical split)
if [ -n "$clock_id" ] && [ -n "$zenith_id" ]; then
    niri msg action focus-window --id "$clock_id"
    niri msg action consume-window-into-column
    niri msg action set-column-width "50%"
fi

# Prepare and open redthread board for system workspace
sys_rt_data_dir="/home/lario/.local/share/redthread_workspaces/system"
sys_rt_notes_file="${sys_rt_data_dir}/redthread/notes.json"
if [ ! -f "$sys_rt_notes_file" ]; then
    mkdir -p "$(dirname "$sys_rt_notes_file")"
    cat <<EOF > "$sys_rt_notes_file"
{
  "schemaVersion": 4,
  "activeIdx": 0,
  "boards": [
    {
      "name": "System TODO",
      "notes": [],
      "strings": []
    }
  ]
}
EOF
fi

# Launch redthread TUI
redthread_id=$(XDG_DATA_HOME="$sys_rt_data_dir" launch_on_workspace "system" "com.mitchellh.ghostty" ghostty --title="system-redthread" -e redthread)
if [ -n "$redthread_id" ]; then
    niri msg action focus-window --id "$redthread_id"
    niri msg action set-column-width "50%"
fi

# Launch Chrome
launch_on_workspace "system" "google-chrome" google-chrome --new-window about:blank

# Launch Sublime Text
launch_on_workspace "system" "sublime_text" flatpak run com.sublimehq.SublimeText


# --- 2. PLAYGROUND WORKSPACE ---
echo "Configuring playground workspace..."

# Launch Gram editor
launch_on_workspace "playground" "app.liten.Gram" flatpak run app.liten.Gram

# Launch Chrome
launch_on_workspace "playground" "google-chrome" google-chrome --new-window about:blank

# Launch simple terminal
launch_on_workspace "playground" "com.mitchellh.ghostty" ghostty --title="playground-terminal"

# Launch Harlequin SQL IDE
launch_on_workspace "playground" "com.mitchellh.ghostty" ghostty --title="playground-harlequin" -e harlequin


# --- 3. T2 MONO WORKSPACES (1 to 4) ---
for n in {1..4}; do
    echo "Configuring T2 Mono ${n} workspace..."
    ws_name="T2 Mono ${n}"
    dir_path="/home/lario/timbuk2/t2-mono-${n}"
    
    # 1. Prepare and open redthread board
    rt_data_dir="/home/lario/.local/share/redthread_workspaces/t2-mono-${n}"
    rt_notes_file="${rt_data_dir}/redthread/notes.json"
    if [ ! -f "$rt_notes_file" ]; then
        mkdir -p "$(dirname "$rt_notes_file")"
        cat <<EOF > "$rt_notes_file"
{
  "schemaVersion": 4,
  "activeIdx": 0,
  "boards": [
    {
      "name": "T2 Mono ${n} TODO",
      "notes": [],
      "strings": []
    }
  ]
}
EOF
    fi
    XDG_DATA_HOME="$rt_data_dir" launch_on_workspace "$ws_name" "com.mitchellh.ghostty" ghostty --title="t2-mono-${n}-redthread" -e redthread
    
    # 2. Open Croft in terminal
    launch_on_workspace "$ws_name" "com.mitchellh.ghostty" ghostty --title="t2-mono-${n}-croft" --working-directory="$dir_path" -e croft
    
    # 3. Open Chrome
    launch_on_workspace "$ws_name" "google-chrome" google-chrome --new-window about:blank
    
    # 4. Open Cline
    # launch_on_workspace "$ws_name" "com.mitchellh.ghostty" ghostty --title="t2-mono-${n}-cline" --working-directory="$dir_path" -e cline -i
    
    # 5. Open Terminal
    launch_on_workspace "$ws_name" "com.mitchellh.ghostty" ghostty --title="t2-mono-${n}-terminal" --working-directory="$dir_path"
done

echo "Configuration completed!"
