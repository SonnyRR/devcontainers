#!/bin/sh
# Grants the non-root developer user access to the mounted host Docker socket
# (Docker-outside-of-Docker). The host socket's group GID is only known at
# runtime, so this runs (as root, via a NOPASSWD sudo rule) from the
# devcontainer postCreateCommand. It is a no-op when the socket is not mounted.
#
# The socket is owned by a host GID that, inside the container, may not map to
# the 'docker' group we created at build time. So we ensure SOME group in the
# image carries that GID and add the user to it - preferring an existing group
# that already has the GID (avoiding a groupmod collision) before falling back
# to creating/re-GIDing the dedicated 'docker' group.
set -e

USERNAME="${USERNAME:-developer}"
SOCK="/var/run/docker.sock"

if [ ! -S "$SOCK" ]; then
  echo "docker-socket-init: $SOCK not found; skipping Docker group setup." >&2
  exit 0
fi

sock_gid=$(stat -c '%g' "$SOCK")

if ! getent group "$sock_gid" >/dev/null 2>&1; then
  if ! getent group docker >/dev/null 2>&1; then
    groupadd -g "$sock_gid" docker 2>/dev/null || groupadd docker
  else
    groupmod -g "$sock_gid" docker 2>/dev/null || true
  fi
fi

gid_group=$(getent group "$sock_gid" | cut -d: -f1)
if [ -n "$gid_group" ]; then
  if ! id -nG "$USERNAME" 2>/dev/null | tr ' ' '\n' | grep -qx "$gid_group"; then
    usermod -aG "$gid_group" "$USERNAME"
  fi
  echo "docker-socket-init: '$USERNAME' added to group '$gid_group' (GID $sock_gid) for the mounted Docker socket." >&2
else
  echo "docker-socket-init: no group found for socket GID $sock_gid; cannot grant access." >&2
  exit 1
fi
