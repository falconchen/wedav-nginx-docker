#!/bin/bash

# === 配置区 ===

CONTAINER_NAME="webdav-client-kita"
FUSE_MOUNT="/mnt/kita"
COMPOSE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# === 自动检测 compose project 和 service 名称 ===

COMPOSE_PROJECT_NAME=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$CONTAINER_NAME" 2>/dev/null)
SERVICE_NAME=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.service" }}' "$CONTAINER_NAME" 2>/dev/null)

if [ -z "$COMPOSE_PROJECT_NAME" ] || [ -z "$SERVICE_NAME" ]; then
  echo "[$(date)] ERROR: Cannot determine compose project or service name from container $CONTAINER_NAME"
  exit 1
fi

# === 检查是否 unhealthy ===

health_status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)

recreate_flag=0

if [ "$health_status" = "unhealthy" ]; then
  echo "[$(date)] $CONTAINER_NAME is unhealthy. Will recreate."
  recreate_flag=1
fi

# === 检查挂载点是否崩溃 ===

if mountpoint -q "$FUSE_MOUNT"; then
  if ! ls "$FUSE_MOUNT" &> /dev/null; then
    echo "[$(date)] Mountpoint $FUSE_MOUNT is broken. Attempting to unmount..."

    if sudo fusermount -u "$FUSE_MOUNT" || sudo umount -l "$FUSE_MOUNT"; then
      echo "[$(date)] Successfully unmounted $FUSE_MOUNT"
      recreate_flag=1
    else
      echo "[$(date)] ERROR: Failed to unmount $FUSE_MOUNT"
      exit 1
    fi
  fi
fi

# === 重建容器（如果需要） ===

if [ "$recreate_flag" = "1" ]; then
  echo "[$(date)] Recreating service '$SERVICE_NAME' from compose project '$COMPOSE_PROJECT_NAME'..."

  cd "$COMPOSE_DIR" || {
    echo "[$(date)] ERROR: Failed to cd into $COMPOSE_DIR"
    exit 1
  }

  docker compose -p "$COMPOSE_PROJECT_NAME" up -d --force-recreate --no-deps "$SERVICE_NAME"

  echo "[$(date)] [$SERVICE_NAME] has been recreated."
else
  echo "[$(date)] No issues detected for $CONTAINER_NAME"
fi

exit 0

