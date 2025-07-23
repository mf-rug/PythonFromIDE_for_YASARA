# YasaraVSCode
Execute Yasara commands from VSCode or Cursor IDE

With this tool, you can write python code with the yasara library in your favorite code editor and execute individual lines or entire scripts in-Yasara simply by marking them in the IDE and pressing a keyboard shortcut. 

![Demo](assets/yaside_demo.gif)


## Installation
#### Auto installation:
clone this repository and run
```
./install_PythonFromIDE_for_YASARA.sh
```

#### Manual installation:
Below installation instructions for VSCode.  
For Cursor, just replace `/.vscode/` with `/.cursor/` and `/Application Support/Code/` with `/Application Support/Cursor/`

1. Create a shell script with commands to write to a helper file. Save this in `$HOME/.vscode/append_from_clipboard.sh`
```
#!/bin/bash
pbpaste > ~/.vscode/save_hl.py
```
2. Make shell script executable
```
chmod +x append_from_clipboard.sh
```

3. Install multi-command extension for VSCode

```
code --install-extension ryuta46.multi-command
```
Should `code` not be available for you / to install for Cursor, [install manually]([url](https://code.visualstudio.com/docs/configure/extensions/extension-marketplace)) within the IDE


4. Add a keyboard shortcut to VSCode, by adding this to `$HOME/Library/Application Support/Code/User/keybindings.json`

(adjust / perform manually if desired)
```
[
{
  "key": "cmd+alt+a",
  "command": "extension.multiCommand.execute",
  "args": {
    "sequence": [
      "editor.action.clipboardCopyAction",
      {
        "command": "workbench.action.terminal.sendSequence",
        "args": {
          "text": "$HOME/.vscode/append_from_clipboard.sh\u000D"
        }
      }
    ]
  },
  "when": "editorTextFocus"
}
]
```

5. Finally, create the yasara plugin by saving this as `PythonFromIDE.py` in the `yasara/plg` folder
```
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
```
