#!/bin/sh
# Writes env.js from the container env vars on every start, so one image works for every environment.
# shortcut: values are inserted as-is into JS strings, a value with a single quote breaks env.js; escape it if that ever matters
set -e
cat > /usr/share/nginx/html/env.js <<JS
window.env = { GATEWAY_SERVICE_URL: '${GATEWAY_SERVICE_URL}', ADMIN_PATH: '${ADMIN_PATH:-_admin}', SESSION_TIMEOUT_MINUTES: '${SESSION_TIMEOUT_MINUTES:-0}' };
JS
echo "env.js written: GATEWAY_SERVICE_URL=${GATEWAY_SERVICE_URL} ADMIN_PATH=${ADMIN_PATH:-_admin} SESSION_TIMEOUT_MINUTES=${SESSION_TIMEOUT_MINUTES:-0}"
