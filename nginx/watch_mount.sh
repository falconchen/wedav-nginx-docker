#!/bin/sh

MOUNT_POINT="/usr/share/nginx/html/media"

# 启动 nginx
nginx

echo "Start monitoring mount point: $MOUNT_POINT"

while true; do
  if ! ls "$MOUNT_POINT" > /dev/null 2>&1; then
    echo "$(date) - Mount point $MOUNT_POINT is inaccessible. Reloading nginx..."
    nginx -s reload || { echo "Failed to reload nginx, restarting..."; nginx -s quit && nginx; }
  fi
  sleep 5
done

