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
#      on macOS. A POSIX ACL grants the user rw where supported. This applies
#      immediately, without a re-login, & avoids adding the user to the 'root' group
#      (which would side-step the password-protected sudo policy).
#      NOTE: Some engines proxy the host socket through a VM-internal bind that does
#      not support POSIX ACLs (Docker Desktop's socket lands in the container as a
#      bind of /run/host-services/docker.proxy.sock, whose backing filesystem has no
#      xattr support - setfacl fails with "Operation not supported"). There the helper
#      falls back to chmod 0666. On such an engine the mode applies to Docker
#      Desktop's per-VM localhost proxy socket, not a shared multi-user host socket,
#      so the widening is contained to the engine the developer already owns.
#      NOTE: The ACL/mode lives on the socket itself, so it is lost when the engine
#      recreates the socket - hence this also runs on every container start. ACL & mode
#      changes are honoured dynamically, so already-running processes (e.g. VS Code
#      terminals) gain access right away without reopening the window.
#   2. Socket GID is non-zero - rootful Docker with a dedicated host group. A group in
#      the image is aligned to that GID & the user is added to it. This stays local to
#      the container & does not touch the host socket.
#
# Afterwards the engine flavor is detected from the daemon API, so that a matching
# Testcontainers host override can be recorded in the developer's ~/.testcontainers
# .properties. The Node & Java clients auto-detect the host of published ports from the
# bridge-network gateway, but the .NET client needs a resolvable DNS name advertised by
# the engine: Docker Desktop/OrbStack provide host.docker.internal, Podman provides
# host.containers.internal, & a bare Linux Docker Engine provides neither (so nothing
# is written). The properties file (not an env var) makes that override apply no matter
# how the test process is spawned. Re-runs on every start because the home dir is
# ephemeral, & is idempotent (also updating an existing host.override key).
#
# Granting socket access is best-effort: every failure is logged and the script
# still exits 0 so the devcontainer (which may not use Docker at all) is never
# blocked from starting. Testcontainers overrides only run when access succeeded.
# ---------------------------------------------------------------------------------------
set -eu

TARGET_USER="${SUDO_USER:-developer}"
SOCK="/var/run/docker.sock"

log() { echo "docker-socket-init: $*" >&2; }

# Record the Testcontainers host override for the detected engine flavor. Called on
# every successful path below because the config file lives in the developer's home
# directory, which is ephemeral (rebuilt with the container).
configure_testcontainers() {
  dev_home="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  props_file="${dev_home:-/home/$TARGET_USER}/.testcontainers.properties"

  engine="$(docker version --format '{{.Server.Platform.Name}}' 2>/dev/null || echo)"
  case "$engine" in
    Docker*) tc_alias=host.docker.internal ;;
    Podman*) tc_alias=host.containers.internal ;;
    *)
      log "unrecognized engine '${engine:-none}'; skipping Testcontainers host override."
      return 0
      ;;
  esac
  if ! getent hosts "$tc_alias" >/dev/null 2>&1; then
    log "$tc_alias does not resolve here; skipping Testcontainers host override."
    return 0
  fi

  if runuser -u "$TARGET_USER" -- sh -c '
    props="$1"; tcalias="$2"
    touch "$props"
    if grep -qs "^host.override=" "$props"; then
      sed -i "s|^host.override=.*|host.override=$tcalias|" "$props"
    else
      printf "host.override=%s\n" "$tcalias" >> "$props"
    fi
  ' sh "$props_file" "$tc_alias"; then
    log "wrote host.override=$tc_alias into $props_file (engine: $engine)."
  else
    log "failed to update $props_file; continuing."
    return 0
  fi
}

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
  configure_testcontainers
  exit 0
fi

sock_gid="$(stat -L -c '%g' "$SOCK")"

if [ "$sock_gid" = "0" ]; then
  # Targeted grant first: a POSIX ACL on the socket for the developer user. This
  # fails on sockets whose backing filesystem has no xattr support - notably
  # Docker Desktop's VM-internal proxy socket on macOS ("Operation not supported").
  if command -v setfacl >/dev/null 2>&1 && setfacl -m "u:${TARGET_USER}:rw" "$SOCK" 2>/dev/null; then
    log "granted '$TARGET_USER' rw on $SOCK via ACL (socket owned by GID 0)."
    configure_testcontainers
    exit 0
  fi

  # Last resort: widen the socket mode. Docker Desktop/OrbStack expose a per-VM
  # localhost proxy socket here, so 0666 stays contained to the engine this
  # developer already exclusively controls; dedicated multi-user Linux engines
  # never reach this branch (their socket GID is non-zero above).
  if chmod 0666 "$SOCK" 2>/dev/null; then
    log "ACL unsupported on $SOCK; granted access via chmod 0666 (per-VM proxy socket) instead."
    configure_testcontainers
    exit 0
  fi

  # Nothing worked - carry on anyway so the devcontainer still starts; Docker
  # tooling inside will fail until the socket permission issue is resolved.
  log "unable to grant '$TARGET_USER' access to $SOCK (ACL unavailable & chmod failed)."
  if ! runuser -u "$TARGET_USER" -- test -r "$SOCK" -a -w "$SOCK" 2>/dev/null; then
    log "'$TARGET_USER' cannot use the container engine socket; continuing anyway."
  fi
  exit 0
fi

# Ensure SOME group carries the socket GID - prefer an existing one to avoid a
# groupmod collision, otherwise create/re-GID the dedicated 'docker' group.
if ! getent group "$sock_gid" >/dev/null 2>&1; then
  if getent group docker >/dev/null 2>&1; then
    groupmod -g "$sock_gid" docker || { log "failed to re-GID 'docker' to $sock_gid; continuing."; exit 0; }
  else
    groupadd -g "$sock_gid" docker || { log "failed to create group for GID $sock_gid; continuing."; exit 0; }
  fi
fi

gid_group="$(getent group "$sock_gid" | cut -d: -f1)"
if [ -z "$gid_group" ]; then
  log "no group found for socket GID $sock_gid; cannot grant access; continuing."
  exit 0
fi

if ! id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx "$gid_group"; then
  usermod -aG "$gid_group" "$TARGET_USER" || { log "failed to add '$TARGET_USER' to '$gid_group'; continuing."; exit 0; }
fi
log "added '$TARGET_USER' to group '$gid_group' (GID $sock_gid); applies to new sessions."
configure_testcontainers
