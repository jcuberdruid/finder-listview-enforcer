#!/usr/bin/env bash
set -e  

if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v pipx &> /dev/null; then
  echo "Installing pipx..."
  brew install pipx
  pipx ensurepath
fi

export PATH="$HOME/.local/bin:$PATH"
if [ ! -d "ds_store" ]; then
  git clone https://github.com/dmgbuild/ds_store.git
fi

if [ ! -d /usr/local/bin ]; then
  sudo mkdir -p /usr/local/bin
  sudo chown $(whoami):admin /usr/local/bin
fi

DAEMON_PATH="/usr/local/bin/finder_listview_enforcer_daemon.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/__main__.py" "$SCRIPT_DIR/ds_store/src/ds_store/"


cd ds_store
pipx install . --force

cd ..

DS_STORE_BIN="$(command -v ds_store)"
USER_HOME=$(eval echo "~$SUDO_USER")

cat <<EOF | sudo tee "$DAEMON_PATH" > /dev/null
#!/usr/bin/env bash
set -euo pipefail

USER_HOME="$USER_HOME"
DS_STORE_BIN="$DS_STORE_BIN"
LOGFILE="/tmp/finder_listview_enforcer_daemon.stdout.log"

timestamp=\$(date "+%Y-%m-%d %H:%M:%S")
echo "[\$timestamp] Using binary: \$DS_STORE_BIN" >> "\$LOGFILE"
echo "[\$timestamp] Starting loop..." >> "\$LOGFILE"

(
    find "\$USER_HOME" -type f -name '.DS_Store' 2>>"\$LOGFILE" || true
) | while IFS= read -r ds_store_file; do
    timestamp=\$(date "+%Y-%m-%d %H:%M:%S")
    echo "[\$timestamp] Processing: \$ds_store_file" >> "\$LOGFILE"
    "\$DS_STORE_BIN" "\$ds_store_file"
done

#reset finder
killall finder
EOF



#remove repo 
rm -rf ./ds_store

echo "Installation successful. Testing installation..."
if ! command -v ds_store &> /dev/null; then
  echo "ERROR: ds_store was not installed correctly."
  exit 1
fi

echo "ds_store installed successfully!"

#start daemon service 
PLIST_NAME="com.jcuberdruid.finder_listview_enforcer_daemon.plist"
PLIST_PATH="/Library/LaunchDaemons/$PLIST_NAME"

chmod +x "$DAEMON_PATH"

cat << EOF | sudo tee "$PLIST_PATH" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jcuberdruid.finder_listview_enforcer_daemon</string>

    <key>ProgramArguments</key>
    <array>
        <string>$DAEMON_PATH</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key>
        <integer>15</integer>
        <key>Hour</key>
        <integer>23</integer>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/finder_listview_enforcer_daemon.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/finder_listview_enforcer_daemon.stderr.log</string>
</dict>
</plist>
EOF

sudo chown root:wheel "$PLIST_PATH"
sudo chmod 644 "$PLIST_PATH"
sudo launchctl unload "$PLIST_PATH" 2>/dev/null || true
sudo launchctl load "$PLIST_PATH"
echo "Daemon installed and loaded."
