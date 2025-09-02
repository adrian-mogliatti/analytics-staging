#!/usr/bin/env bash
set -euo pipefail

: "${BASIC_AUTH_USER:?}"
: "${BASIC_AUTH_PASS:?}"
htpasswd -bc /etc/nginx/.htpasswd "$BASIC_AUTH_USER" "$BASIC_AUTH_PASS"

# If a backend host env var is present, rewrite the nginx config so it proxies to that FQDN
if [ -n "${BACKEND_HOST:-}" ]; then
  sed -i "s|proxy_pass http://backend:3000;|proxy_pass https://${BACKEND_HOST}/api/;|g" /etc/nginx/conf.d/default.conf
fi

nginx -g 'daemon off;'

