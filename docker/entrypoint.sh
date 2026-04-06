#!/bin/bash
set -e

# Fix static asset permissions for nginx (www-data)
# Volume mounts from Windows override build-time permissions
echo "Fixing asset permissions..."
find /var/www/assets -type d -exec chmod 755 {} \; 2>/dev/null || true
find /var/www/assets -type f -exec chmod 644 {} \; 2>/dev/null || true

# Fix root-level files (index.cfm, Application.cfc etc.)
find /var/www -maxdepth 1 -type f -exec chmod 644 {} \; 2>/dev/null || true

echo "Permissions fixed. Starting services..."

# Execute the original entrypoint/command
exec "$@"
