#!/usr/bin/env bash

# Fetches a webcall url to maintain public access using dynamic DNS.

# Configuration
target_url="https://example.com/path/to/your/webcall/url"
log_file="/var/log/ddns_sync/ddns_sync.log"

# Checking log file path
mkdir -p "$(dirname "$log_file")"

# Sending current public IP address to target URL; current public IP
# address is the expected return value.
response=$(curl -s "$target_url" | head -n1 | tr -d '\r\n')

# Logging
# Check if log file exists and has content
if [[ -f "$log_file" && -s "$log_file" ]]; then
	# Extract most recent logged response
	last_response=$(tail -n1 "$log_file" | cut -d' ' -f4-)
else
	last_response=""
fi

# If the response has changed, append to log.
if [[ "$response" != "$last_response" ]]; then
	timestamp=$(date  '+%Y-%m-%d %H:%M:%S UTC%z')
	echo "$timestamp $response" >> "$log_file"
fi
