# finder-listview-enforcer

**Keep macOS Finder consistent by enforcing List View style on all your directories when viewed in Finder**


This daemon scans your home directory for `.DS_Store` files and updates them, so that all finder windows default to list view. 

---

## Features

- Runs automatically on a schedule via `launchd`
- Recursively finds all `.DS_Store` files in your home directory
- Forces Finder windows to open in **List View mode**

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ds_store-listview-enforcer.git
   cd ds_store-listview-enforcer
   ```

2. Run the installer:
   ```bash
   sudo bash install_daemon_tool.sh
   ```

   This will:
   - Install Homebrew, `pipx`, and dependencies if missing
   - Clone and patch the `ds_store` Python tool
   - Install the daemon to `/usr/local/bin/`
   - Register the launch daemon with `launchd`
   - Run it immediately and schedule future runs
   - Important Note: The script must restart finder after changes are made; your UI may blink for a moment. 

---

## How It Works

This tool uses [`ds_store`](https://github.com/dmgbuild/ds_store) under the hood to manipulate Finder metadata files.

Each run of the daemon:
- Scans your home directory for `.DS_Store` files (skipping unreadable paths)
- Updates them to use **List View** as the default (`icnv` ➜ `Nlsv`)
- Logs output to:  
  `/tmp/finder_listview_enforcer_daemon.stdout.log`

---

## Schedule

By default, the daemon runs **daily at 11:15 PM**. You can change this by editing:

```
/Library/LaunchDaemons/com.jcuberdruid.finder_listview_enforcer_daemon.plist
```

## Modify Style

If for some reason (yet unknown to mankind) you wish to use a different style you can edit the line **69** in the **__main__.py** file: 

| Finder View Style   | Code                      |
|---------------------|---------------------------|
| List View           | `("type", b'Nlsv')`       |
| Icon View           | `("type", b'icnv')`       |
| Column/Browser View | `("type", b'clmv')`       |
| Gallery View        | `("type", b'Flwv')`       |

## Uninstall

```bash
sudo launchctl bootout system /Library/LaunchDaemons/com.jcuberdruid.finder_listview_enforcer_daemon.plist
sudo rm /Library/LaunchDaemons/com.jcuberdruid.finder_listview_enforcer_daemon.plist
sudo rm /usr/local/bin/finder_listview_enforcer_daemon.sh
```

## Logging 

You can check the stdout and stderror logs in **/tmp**

finder_listview_enforcer_daemon.stderr.log    
finder_listview_enforcer_daemon.stdout.lo
