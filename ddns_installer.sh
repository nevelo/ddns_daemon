#!/usr/bin/env bash
set -euo pipefail

# Ensure that we are running as root.
if ((EUID != 0)); then
	echo "ERROR: the ddns_installer must be run as root (or via sudo)." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create the ddns_sync user to run the service.
if ! id ddns_sync &>/dev/null; then
	useradd -r -s /usr/bin/nologin -d /nonexistent ddns_sync
	echo "Created system user ddns_sync."
else
	echo "User ddns_sync already exists."
fi

# Prepare configuration file.
CONFIG_FILE=/etc/ddns_sync.conf
if [[ ! -f "$CONFIG_FILE" ]]; then
	cat > "$CONFIG_FILE" <<'EOF'
# Configuration for ddns_sync
# Set TARGET_URL to your webhost's provided capability URL.
TARGET_URL="https://example.com/your/api"
EOF
	echo "Created config file $CONFIG_FILE; please edit this file to set TARGET_URL."
else
	echo "Using existing config file $CONFIG_FILE"
fi

# Preparing log directory.
LOG_DIR=/var/log/ddns_sync
LOG_FILE=$LOG_DIR/ddns.log
mkdir -p "$LOG_DIR"
chown ddns_sync:ddns_sync "$LOG_DIR"
chmod 2755 "$LOG_DIR"
echo "Prepared log directory $LOG_DIR"

# Installing ddns_sync.sh.
if [[ ! -f "$SCRIPT_DIR/ddns_sync.sh" ]]; then
	echo "ERROR: ddns_sync.sh not found in $SCRIPT_DIR" >&2
	exit 1
fi
cp "$SCRIPT_DIR/ddns_sync.sh" /usr/local/bin/ddns_sync.sh
chmod 755 /usr/local/bin/ddns_sync.sh
chown ddns_sync:ddns_sync /usr/local/bin/ddns_sync.sh
echo "Copied ddns_sync.sh to /usr/local/bin/"

# Configure logrotate
cat > /etc/logrotate.d/ddns_sync <<'EOF'
/var/log/ddns_sync/*.log {
	su ddns_sync ddns_sync
	monthly
	maxsize 10K
	rotate 24
	compress
	delaycompress
	missingok
	notifempty
	create 0640 ddns_sync ddns_sync
}
EOF

chmod 644 /etc/logrotate.d/ddns_sync

echo "Installed /etc/logrotate.d/ddns_sync"

# Configure cron
cat > /etc/cron.d/ddns_sync <<'EOF'
SHELL=/bin/bash
PATH=/usr/local/bin:usr/bin:/bin

# run every 10 minutes as ddns_sync
*/10 * * * * ddns_sync /usr/local/bin/ddns_sync.sh
EOF

chmod 644 /etc/cron.d/ddns_sync
chown root:root /etc/cron.d/ddns_sync

echo "Installed /etc/cron.d/ddns_sync"

# Final summary
echo "Setup complete!"
echo "  Config:    /etc/ddns_sync.conf"
echo "  Script:    /usr/local/bin/ddns_sync.sh"
echo "  Log file:  $LOG_FILE"
echo "  Logrotate: /etc/logrotate.d/ddns_sync"
echo "  Cron job:  /etc/cron.d/ddns_sync (every 10 minutes)"

