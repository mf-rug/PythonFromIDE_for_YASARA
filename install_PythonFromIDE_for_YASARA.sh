#! /bin/bash

echo "Installing PythonFromIDE extension for YASARA."
echo '=============================================='
installed_editors=()
if [ -e "/Applications/Visual Studio Code.app" ]; then
  installed_editors+=("VSCode")
fi
if [ -e "/Applications/Cursor.app" ]; then
  installed_editors+=("cursor")
fi
if [ ${#installed_editors[@]} -eq 0 ]; then
  echo "No installations found for cursor or VSCode. Continue anyway? (y/n)"
  echo "Script creation cancelled."
  exit
else
  echo "Found installations for: ${installed_editors[@]}"
fi


for editor in ${installed_editors[@]}; do
  echo
  echo "Installing PythonForIDE extension for $editor"
  if [ "$editor" == "cursor" ]; then
    editor_app='Cursor'
    editor_config='.cursor'
    editor_lib='Cursor'
  elif [ "$editor" == "VSCode" ]; then
    editor_app='Visual Studio Code'
    editor_config='.vscode'
    editor_lib='Code'
  fi

  # Check if the $editor configuration directory exists
  echo "Checking if $editor configuration directory exists..."
  if [ ! -d "$HOME/$editor_config" ]; then
    echo "$editor configuration directory $HOME/$editor_config/ does not exist."
    read -p "Do you want to create the $editor_config directory? (y/n) " create_$editor
    if [ "$create_$editor" != "y" ]; then
      echo "Script creation cancelled."
      exit
    else
      mkdir "$HOME/$editor_config"
      echo "Created $editor_config directory."
    fi
  fi

  # Proceed with creating the script if the directory exists or was created
  # create a shell script with commands to write to a helper file
  echo \
  '#!/bin/bash
  pbpaste > /tmp/PythonIDE_watch.py' \
  > "$HOME/$editor_config/append_from_clipboard.sh"

  echo "Creating shell script to append from clipboard..."
  # make shell script executable
  chmod +x "$HOME/$editor_config/append_from_clipboard.sh"
  echo "Made shell script executable."

  # install multi-command for $editor
  # should `code` not be available for you, install manually within $editor
  if [ "$editor" == "VSCode" ]; then
    if command -v code &> /dev/null; then
      echo "Installing multi-command extension for $editor..."
      code --install-extension ryuta46.multi-command
      echo "Multi-command extension installed."
    else
      echo "`code` is not available. Please install the multi-command extension manually."
      read -p "Do you want to proceed with the script creation? (y/n) " proceed
      if [ "$proceed" != "y" ]; then
        echo "Script creation aborted."
        exit
      fi
    fi
  else
    echo "command line based extension installation is not possible for cursor."
    echo "Install multi-command extension manually within Cursor."
    read -p "Do you want to proceed with the script creation? (y/n) " proceed
    if [ "$proceed" != "y" ]; then
      echo "Script creation aborted."
      exit
    fi
  fi

  # add a keyboard shortcut to $editor, adjust / perform manually if desired
  keybindings_dir="$HOME/Library/Application Support/$editor_lib/User"
  echo "Setting up keybindings for macOS..."

  if [ ! -d "$keybindings_dir" ]; then
    echo "Keybindings directory $keybindings_dir does not exist. Aborting script."
    exit 1
  fi

  keybindings_file="$keybindings_dir/keybindings.json"

  new_entry='{
    "key": "cmd+alt+a",
    "command": "extension.multiCommand.execute",
    "args": {
      "sequence": [
        "editor.action.clipboardCopyAction",
        {
          "command": "workbench.action.terminal.sendSequence",
          "args": {
            "text": "'${HOME}/$editor_config/append_from_clipboard.sh'\n"
          }
        }
      ]
    },
    "when": "editorTextFocus"
  }'

  # Create the file if it doesn't exist
  if [ ! -f "$keybindings_file" ]; then
    echo "Creating keybindings file..."
    echo "[]" > "$keybindings_file"
  fi

  # Patch the JSON array using Python
  python3 - <<EOF
import json
import os

path = os.path.expanduser("${keybindings_file}")
with open(path, 'r') as f:
    try:
        data = json.load(f)
        if not isinstance(data, list):
            raise ValueError("keybindings.json does not contain a JSON array.")
    except Exception:
        data = []

new_binding = ${new_entry}

if new_binding not in data:
    data.append(new_binding)

with open(path, 'w') as f:
    json.dump(data, f, indent=2)
EOF

  echo "Patched keybindings with new entry."
  echo "Installation for $editor finished."
done

# Check if the YASARA directory exists before creating the plugin
yasara_dir="/Applications/YASARA.app/Contents/yasara/plg/"
echo
echo "Checking for YASARA..."
if [ ! -d "$yasara_dir" ]; then
  echo "YASARA plg directory not found. Please save the plugin manually."
else
  echo "Creating YASARA plugin..."
  cat << EOF > "$yasara_dir"/PythonFromIDE.py
# YASARA PLUGIN
# TOPIC:       Python
# TITLE:       PythonFromIDE
# AUTHOR:      M.J.L.J. Fürst
# LICENSE:     GPL (www.gnu.org)
# DESCRIPTION: This plugin allows executing python code in a YASARA session from VSCode/Cursor
#

"""
MainMenu: Options
  PullDownMenu: PythonFromIDE
    Request: Python
"""

from yasara import *
import os
import time

# get paths
file_to_watch = "/tmp/PythonIDE_watch.py"
closeplg = "/tmp/closeplg"

# delete existing helper files
if (os.path.exists(file_to_watch)):
  os.remove(file_to_watch)
if (os.path.exists(closeplg)):
  os.remove(closeplg)

with open(closeplg, 'a'):
  os.utime(closeplg, None)

with open(file_to_watch, 'a'):
  os.utime(file_to_watch, None)

# Make Button to quit plugin
Console('OFF')
img = MakeImage("Buttons",topcol="None",bottomcol="None")
ShowImage(img,alpha=85,priority=1)
PrintImage(img) 
Font("Arial",height=7,color="black")
ShowButton("PyIDE",x='80%', y='0.5%',color="White", height=29, action=f'DelFile {closeplg}')

# Show info
ShowMessage('PythonFromIDE plugin launched. To quit, press button above HUD.')
Wait(500)
HideMessage()
PrintCon()
Console('ON')

# run main loop
last_mtime = 0
while os.path.exists(closeplg):
  try:
      mtime = os.path.getmtime(file_to_watch)
      if mtime != last_mtime:
          last_mtime = mtime
          with open(file_to_watch, "r") as f:
              code = f.read()
              exec(code, globals())
  except Exception as e:
      Print(e)
      Console('Open')
  time.sleep(1)

# Hide button
Console('OFF')
PrintImage(img) 
FillRect()
PrintCon()
Console('ON')

# End plugin
plugin.end()

EOF
fi
echo "YASARA plugin creation completed, plugin at:"
echo "$yasara_dir"/PythonFromIDE.py
echo "Installation complete."
echo '=============================================='
