#!/bin/sh
# ---------------------------------------------------------------------------------------
# Docker-outside-of-Docker (DooD) socket access helper
# ---------------------------------------------------------------------------------------
# Grants the non-root devcontainer user read/write access to the host container engine
# socket bind-mounted at /var/run/docker.sock. The socket's owner is only known at
# runtime, so this runs as root (via a scoped NOPASSWD sudo rule) from the
# devcontainer onCreateCommand & postStartCommand. It is idempotent & a no-op when the
# socket is not mounted.
#
# Two cases are handled:
#   1. Socket GID is 0 - rootless Podman/Docker (the host user maps to container root)
#      or an engine that owns the socket as root:root, such as Docker Desktop & OrbStack
#      on macOS. A POSIX ACL grants the user rw. This applies immediately, without a
#      re-login, & avoids adding the user to the 'root' group (which would side-step
#      the password-protected sudo policy).
#      NOTE: The ACL lives on the socket itself, so it is lost when the engine recreates
#      the socket - hence this also runs on every container start. ACLs are honured
#      dynamically, so already-running processes (e.g. VS Code terminals) gain access
#      right away without reopening the window.
#   2. Socket GID is non-zero - rootful Docker with a dedicated host group. A group in
#      the image is aligned to that GID & the user is added to it. This stays local to
#      the container & does not touch the host socket.
# ---------------------------------------------------------------------------------------
set -eu

TARGET_USER="${SUDO_USER:-developer}"
SOCK="/var/run/docker.sock"

log() { echo "docker-socket-init: $*" >&2; }

if [ ! -S "$SOCK" ]; then
  log "$SOCK not mounted; skipping."
  exit 0
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  log "user '$TARGET_USER' does not exist."
  exit 1
fi

# Already accessible (fresh login session, so group changes are taken into account).
if runuser -u "$TARGET_USER" -- test -r "$SOCK" -a -w "$SOCK" 2>/dev/null; then
  log "'$TARGET_USER' already has access to $SOCK."
  exit 0
fi

sock_gid="$(stat -L -c '%g' "$SOCK")"

if [ "$sock_gid" = "0" ]; then
  setfacl -m "u:${TARGET_USER}:rw" "$SOCK"
  log "granted '$TARGET_USER' rw on $SOCK via ACL (socket owned by GID 0)."
  exit 0
fi

# Ensure SOME group carries the socket GID - prefer an existing one to avoid a
# groupmod collision, otherwise create/re-GID the dedicated 'docker' group.
if ! getent group "$sock_gid" >/dev/null 2>&1; then
  if getent group docker >/dev/null 2>&1; then
    groupmod -g "$sock_gid" docker
  else
    groupadd -g "$sock_gid" docker
  fi
fi

gid_group="$(getent group "$sock_gid" | cut -d: -f1)"
if [ -z "$gid_group" ]; then
  log "no group found for socket GID $sock_gid; cannot grant access."
  exit 1
fi

if ! id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx "$gid_group"; then
  usermod -aG "$gid_group" "$TARGET_USER"
fi
log "added '$TARGET_USER' to group '$gid_group' (GID $sock_gid); applies to new sessions."
