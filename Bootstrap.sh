#!/bin/bash
# Intune shell script — runs as root at enrollment

set -e

SCRIPT_PATH="/usr/local/bin/installomator-1st-depnotify.sh"
DAEMON_LABEL="com.yourorg.installomator1st"
DAEMON_PATH="/Library/LaunchDaemons/${DAEMON_LABEL}.plist"
SENTINEL="/var/db/.Installomator1stDone"

# Bail if we've already run successfully
[[ -e "$SENTINEL" ]] && { echo "Already deployed, exiting."; exit 0; }

# 1. Drop the Installomator 1st DEPNotify script
mkdir -p /usr/local/bin
curl -fsSL "https://your.host/installomator-1st-depnotify.sh" -o "$SCRIPT_PATH"
chown root:wheel "$SCRIPT_PATH"
chmod 755 "$SCRIPT_PATH"

# 2. Write the LaunchDaemon
cat > "$DAEMON_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${DAEMON_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${SCRIPT_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/installomator-1st.out.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/installomator-1st.err.log</string>
</dict>
</plist>
EOF

chown root:wheel "$DAEMON_PATH"
chmod 644 "$DAEMON_PATH"

# 3. Load it now (also runs at every boot until removed)
launchctl bootstrap system "$DAEMON_PATH" 2>/dev/null || true
launchctl enable "system/${DAEMON_LABEL}"
launchctl kickstart -k "system/${DAEMON_LABEL}"

echo "Installomator 1st LaunchDaemon installed and kickstarted."
exit 0