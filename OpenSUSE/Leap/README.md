# 🐧 OpenSUSE Leap Devcontainer Image

This directory contains the `Dockerfile` for a custom general-purpose devcontainer, based on `opensuse/leap:16.0`, alongside a template `devcontainer.json` for use in actual codebases.

## 📄 Devcontainer Template (with Sensible Defaults)

A ready-to-use `devcontainer.json` example ships at
[`./.devcontainer/devcontainer.json`](./.devcontainer/devcontainer.json). Drop it into
your project at `.devcontainer/devcontainer.json` to get a fully wired-up environment
out of the box. The template configures:

- **Image:** `docker.io/vkotzsev/opensuse-leap:latest` (pin to `16.0` for the
  fixed-version tag)
- **User:** runs as the non-root `developer` account
- **Shell:** `Fish` set as the default VS Code integrated terminal profile
- **Persistent state:** named volumes for `Fish` history (`~/.local/share/fish`) and
  the `XDG` cache (`~/.cache`), scoped per `${devcontainerId}`
- **Git identity:** read-only bind mount of your host `~/.gitconfig`
- **Env:** `NODE_OPTIONS=--max-old-space-size=4096` for larger Node workloads
- **Lifecycle:** `shutdownAction: stopContainer` to stop the container when VS Code
  closes
- **Extensions:** EditorConfig, ESLint, Prettier, C# Dev Kit, C#, Playwright, Angular
  Language Service, GitHub Pull Requests

### 🧩 Extending the Template

The template is intentionally a **starting point**. You can extend it with any property
from the [`devcontainer.json` reference](https://containers.dev/implementors/json_reference/),
including:

- Additional [`mounts`](https://containers.dev/implementors/json_reference/#mounts) -
  extra bind mounts (e.g. `~/.ssh`, `~/.azure`), named volumes for build caches
  (`node_modules`, `~/.nuget/packages`), or `tmpfs` mounts for ephemeral data
- `forwardPorts` / `portsAttributes` for app ports
- Lifecycle hooks: `postCreateCommand`, `postStartCommand`, `postAttachCommand`,
  `onCreateCommand`, `initializeCommand`, `updateContentCommand`
- Additional `containerEnv` / `remoteEnv` variables
- Extra VS Code `customizations.vscode.extensions` / `settings`
- If a project genuinely needs a tool that isn't in the base image, you can layer on
  a project-specific [Dev Container Feature](https://containers.dev/features) (e.g.
  `kubectl-helm-minikube`, `terraform`, `aws-cli`) via the `features` block.
  **But please don't use Features to replace toolchain that already lives in the base
  image** - see [Toolchains](#-toolchains). (Note: Docker-outside-of-Docker is already
  baked into the image - see
  [Docker (outside of Docker)](#-docker-outside-of-docker).)

## 🧭 Purpose

This image provides a ready-to-use `Linux` development environment for local testing and for use in standardized team development containers.

## 🧰 Toolchains

The entire toolchain - language runtimes/SDKs, CLIs, shell, editor tooling, corporate
certificate trust - is **installed at image build time inside the `Dockerfile`** and
shipped as part of the published image. We **deliberately do not** use the
devcontainer spec's [Features](https://containers.dev/features) mechanism to provision
the core toolchain at container-create time.

Why baked-in beats Features for the base image:

- **Reproducibility.** A tagged image (e.g. `opensuse-leap:16.0`) is byte-identical
  for every developer who pulls it.
- **Fast container startup.** No multi-minute per-create install step - `Reopen in
Container` is essentially "pull and go".
- **Offline / restricted-network friendly.** Container creation does not require
  reaching out to Microsoft, GitHub, OCI Features registries, or any other third
  party.
- **Single auditable supply chain.** Every install command, package version, signing
  key, and trust root is in this repo's `Dockerfile`, reviewed via PR, and built and
  scanned in CI.
- **Corporate trust handled once.** The system CA certificate store is
   imported and validated at build time.
- **Version pinning via the image tag**, not via a moving Feature version.

What is provisioned at build time (high-level):

- Microsoft package repo: configured for `OpenSUSE` to install `.NET` packages
- Certificate and `TLS` tooling:
  - `CA certificates`
  - `Mozilla CA bundle`
  - `Curl`
  - `OpenSSL`
  - `GPG` (signing & key management)
- System and privilege tools:
  - `Sudo`
  - Development toolchain (`patterns-devel-base-devel_basis`)
  - `glibc`
  - `ICU`
- Source control and remote access:
  - `Git`
  - `GitHub CLI` (`gh`)
  - `OpenSSH`
  - `Lazygit` (terminal UI for `Git`)
- Terminal and shell experience:
  - `Fish` shell (w/shell integration)
  - `fzf` (w/shell completion)
  - `ripgrep` (w/shell completion)
  - `fd` (w/shell completion)
  - `zoxide` (smarter `cd`)
  - `tmux` (terminal multiplexer)
  - `ncdu` (disk usage analyzer)
- Developer `CLI` and editors:
  - `jq`
  - `awk` (GNU `gawk`)
  - `Neovim`
  - `SQLite`
  - `tree-sitter-cli` (global `npm` install)
- File management & archives:
  - `Yazi` (terminal file manager, w/shell completion)
  - `7-Zip`
  - `file`
- Media & document tools:
  - `FFmpeg`
  - `Poppler` PDF tools (`poppler-tools`)
- Language and platform toolchains:
  - `Python 3.13`
  - `.NET SDK 10.0`
  - `Node.js LTS` (via `FNM`)
  - `pnpm` (via `Corepack`)
  - `LuaJIT`
  - .NET global tools:
    - `dotnet-ef`
    - `dotnet-outdated-tool`
    - `gitversion.tool`
    - `nuke.globaltool`
    - `ilspycmd`
    - `easydotnet`
- Cloud and secrets tooling:
  - `Azure CLI`
  - `SOPS`
- Container tooling:
  - `Docker (DooD)`
- Browser/runtime dependencies:
  - `GNOME Keyring`
  - Browser runtime support libraries (graphics/audio/X11/font stack)
- AI developer tooling:
  - `OpenCode V2` (global `npm` install of `@opencode/cli`)
  - `Anthropic Claude Code CLI` (global `npm` install)

Note: the base image `opensuse/leap:latest` may include additional preinstalled OS packages not listed above.

## 👤 User & Shell Defaults

- Creates a non-root user: `developer` (configurable via `ARG USERNAME`)
- Default shell is `Fish`: `/usr/bin/fish`
- User is added to `wheel` with sudo configuration files under `/etc/sudoers.d`
- MOTD includes guidance for enabling password-based sudo bootstrap

## 🐳 Docker (outside of Docker)

The image ships the **Docker CLI** so you can run `docker` / `docker compose` from
inside the container against the **host's Docker daemon** (a.k.a. Docker-outside-of-Docker,
or "DooD") - there is no separate in-container daemon and no `privileged` mode required.

Everything is baked into the image at build time; no Dev Container Feature is used:

- The Docker CLI client is installed from the distribution's own signed repositories
  (`docker` + `docker-compose` from the openSUSE repos).
- A `docker` group is created and the `developer` user is added to it.
- Because the host socket's group GID is only known at runtime, the helper
  `/usr/local/bin/docker-socket-init.sh` (executed as root via a dedicated NOPASSWD
  sudoers rule, `12-docker-socket-init`) aligns the in-container `docker` group GID to
  the mounted socket at container-create time. It is a safe no-op when the socket is
  not present.

To enable it, bind-mount the host Docker socket into the container. The bundled
`devcontainer.json` already does this for you:

```json
"mounts": [
  "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
],
"postCreateCommand": "sudo /usr/local/bin/docker-socket-init.sh"
```

> [!NOTE]
> The daemon runs on the **host**, so containers you launch from inside this devcontainer
> are siblings of the devcontainer itself, not nested children. They share the host's
> Docker networks and publish ports directly on the host.

> [!NOTE]
> **macOS hosts:** Docker Desktop exposes the socket as `root:root` (GID `0`), which maps
> to the container's `root` group. The init helper therefore adds the `developer` user to
> the `root` *group* (not uid `0`) so it can reach the socket. This is expected for
> Docker-outside-of-Docker on macOS and only grants group-level access to the socket.

If you previously added the `ghcr.io/devcontainers/features/docker-outside-of-docker`
Feature, you no longer need it - the equivalent capability is now part of the base image.

## 🛠️ Build Locally

Build from the **repo root** - the `Dockerfile`s `COPY` from `OpenSUSE/Leap/cfg/...`, so the
build context must be the repository root, not the flavor directory:

```bash
docker buildx build --load -t opensuse-leap-devbox:local -f ./OpenSUSE/Leap/Dockerfile .
```

> [!NOTE]
> On macOS the default builder targets the host platform. Pass `--platform linux/amd64`
> (portable) or `--platform linux/arm64` (native on Apple Silicon) so a Linux image is
> produced.

## ▶️ Run Locally

```bash
docker run --rm -it --user developer opensuse-leap-devbox:local
```

To try Docker-outside-of-Docker manually, bind-mount the host socket and run the init
helper. A **fresh shell** is needed afterwards so the new group membership takes effect:

```bash
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  opensuse-leap-devbox:local
# inside:
sudo /usr/local/bin/docker-socket-init.sh
newgrp root   # or: sg root -c 'docker ps'
docker ps
```

## 🚀 Spin up via the devcontainer CLI

You can drive the whole flow from the command line with the
[`devcontainer` CLI](https://github.com/devcontainers/cli) (requires Node.js):

```bash
npm install -g @devcontainers/cli   # or: npx -y @devcontainers/cli
```

### 🔨 Build the image locally (optional)

The published image is normally pulled from Docker Hub, but to build and test a change
locally, run from the **repo root** (the `Dockerfile` `COPY`s from `OpenSUSE/Leap/cfg/...`,
so the build context must be the repository root):

```bash
docker buildx build --load --platform linux/amd64 -t opensuse-leap-devbox:local -f ./OpenSUSE/Leap/Dockerfile .
```

> [!NOTE]
> On macOS pass `--platform linux/amd64` (portable) or `--platform linux/arm64` (native on
> Apple Silicon) so a Linux image is produced.

### 🔗 Use the local image

Point a project's `devcontainer.json` at your local build instead of the published one.
Either retag to the template's image name:

```bash
docker tag opensuse-leap-devbox:local docker.io/vkotzsev/opensuse-leap:latest
```

…or, in a throwaway test workspace, copy the template and overwrite its `image` field:

```bash
mkdir -p /tmp/doo-test/.devcontainer
cp ./OpenSUSE/Leap/.devcontainer/devcontainer.json /tmp/doo-test/.devcontainer/devcontainer.json
# edit the copied file so "image" points at opensuse-leap-devbox:local
```

### ▶️ Bring it up and verify

```bash
devcontainer up --workspace-folder /tmp/doo-test
devcontainer exec --workspace-folder /tmp/doo-test -- docker version
devcontainer exec --workspace-folder /tmp/doo-test -- docker ps
```

The `postCreateCommand` (`sudo /usr/local/bin/docker-socket-init.sh`) aligns the
in-container group to the mounted host socket, so `docker` works without `sudo` in any
`exec`/terminal session opened afterwards. On macOS the host socket is `root:root` (GID
`0`), so the helper adds `developer` to the `root` *group* (see
[Docker (outside of Docker)](#-docker-outside-of-docker)). If a long-running shell
started before `postCreateCommand` still reports a permission error, open a fresh
`devcontainer exec` session or run `newgrp root` / `sg root -c 'docker ps'`.

### 🧹 Tear down

The CLI has no `stop`/`down` command; remove the container directly with Docker:

```bash
docker ps   # locate the container (name derived from the workspace folder)
docker rm -f <container>
```

## ☁️ Registry & Consumption Guidance

For real project repositories, this image should be consumed from Docker Hub, not rebuilt ad hoc per repository.

- Local build/run is intended for validation and iteration
- Production/standardized `DevContainer` usage should pull the published image from Docker Hub

## 🏷️ Image Tags

Published to `docker.io/vkotzsev/opensuse-leap`. This flavor tracks a fixed release
version:

- `latest` - the most recent build from `main`
- `16.0` - the pinned base version; overwritten on each `main` build with the newest content

Builds from non-`main` branches publish pre-release tags instead:

- `beta-16.0-<short-sha>`
- `beta-<branch>-<short-sha>`
- `beta-<branch>-latest`

In addition, every build (on any branch) publishes an immutable tag equal to the full 40-char
commit SHA so you can pin the image to the exact commit it was built from.

## 📝 Notes

- `CMD` defaults to Fish for an interactive developer session
