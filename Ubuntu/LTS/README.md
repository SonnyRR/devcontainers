# 🐧 Ubuntu LTS Devcontainer Image

This directory contains the `Dockerfile` for a custom general-purpose devcontainer,
based on `ubuntu:26.04`, alongside a template `devcontainer.json` for use in actual
codebases.

## 📄 Devcontainer Template (with Sensible Defaults)

A ready-to-use `devcontainer.json` example ships at
[`./.devcontainer/devcontainer.json`](./.devcontainer/devcontainer.json). Drop it into
your project at `.devcontainer/devcontainer.json` to get a fully wired-up environment
out of the box. The template configures:

- **Image:** `docker.io/vkotzsev/ubuntu-lts:latest` (pin to `26.04` for the
  fixed-version tag)
- **User:** runs as the non-root `developer` account
- **Shell:** `Fish` set as the default VS Code integrated terminal profile
- **Persistent state:** named volumes for `Fish` history (`~/.local/share/fish`) and
  the `XDG` cache (`~/.cache`), scoped per `${devcontainerId}`
- **Git identity:** read-only bind mount of your host `~/.config/git/config`
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

## 🎯 Purpose

This image provides a ready-to-use `Linux` development environment for local testing and for use in standardized team development containers.

## 🧰 Toolchains

The entire toolchain - language runtimes/SDKs, CLIs, shell, editor tooling, corporate
certificate trust - is **installed at image build time inside the `Dockerfile`** and
shipped as part of the published image. We **deliberately do not** use the
devcontainer spec's [Features](https://containers.dev/features) mechanism to provision
the core toolchain at container-create time.

Why baked-in beats Features for the base image:

- **Reproducibility.** A tagged image (e.g. `ubuntu:26.04`) is byte-identical for
  every developer who pulls it.
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

- `.NET` is installed from Ubuntu's own `apt` feed (Microsoft's package repo is not used)
- Certificate and `TLS` tooling:
  - `CA certificates`
  - `Curl`
  - `OpenSSL`
  - `GPG` (signing & key management)

- System and privilege tools:
  - `Sudo`
  - `Build Essential` (GCC/G++/Make toolchain)
- Source control and remote access:
  - `Git`
  - `GitHub CLI` (`gh`)
  - `OpenSSH` (client)
  - `Lazygit` (terminal UI for `Git`)
  - `Git Credential Manager` (configure `credential.helper` in your `~/.config/git/config`)
- Terminal and shell experience:
  - `Fish` shell (w/shell integration)
  - `fzf`
  - `ripgrep`
  - `fd`
  - `zoxide` (smarter `cd`)
  - `tmux` (terminal multiplexer)
  - `ncdu` (disk usage analyzer)
- `btop` (resource monitor)
- Developer `CLI` and editors:
  - `jq`
  - `awk` (GNU `gawk`)
  - `Neovim` (latest stable, GitHub release)
  - `SQLite`
  - `tree-sitter-cli` (global `npm` install)
- File management & archives:
  - `Yazi` (terminal file manager)
  - `7-Zip`
  - `unzip`
  - `tar`
  - `file`
- Media & document tools:
  - `FFmpeg`
  - `Poppler` PDF tools (`poppler-utils`)
- Language and platform toolchains:
  - `Python 3`
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
    - `git-credential-manager`
- Cloud and secrets tooling:
  - `Azure CLI`
  - `SOPS` (release binary)
- Container tooling:
  - `Docker (DooD)`
- Browser/runtime dependencies:
  - `GNOME Keyring`
  - Browser runtime support libraries (graphics/audio/X11/font stack)
- AI developer tooling:
  - `OpenCode V2` (global `npm` install of `@opencode/cli`)
  - `Anthropic Claude Code CLI` (global `npm` install)

Note: the base image `ubuntu:26.04` may include additional preinstalled OS packages not listed above.

## 🧑‍💻 User & Shell Defaults

- Creates a non-root user: `developer` (configurable via `ARG USERNAME`)
- Default shell is `Fish`: `/usr/bin/fish`
- `developer` is added to a `wheel` group created by the image (Ubuntu's own sudo
  group is left untouched) and gets password-based `sudo` via the sudoers fragments
  under `/etc/sudoers.d`
- Password bootstrap: `developer` may run `passwd` on itself without a password
  (`11-passwd-bootstrap`), after which `sudo` unlocks - `00-wheel-auth` rejects
  root and target-user password authentication, so the account's own password is
  the only one that works

## 🔐 Git Credential Manager

[Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager)
(GCM) is installed as a global `.NET` tool. The image configures nothing itself - add
this to your own `~/.config/git/config`, which the template bind-mounts read-only:

```ini
[credential]
    helper =
    helper = /home/developer/.dotnet/tools/git-credential-manager
    credentialStore = plaintext
```

- The empty `helper =` drops any system-level helper. It must live in your file, not
  `/etc/gitconfig`, because Git reads system config first and appends global config after.
- `credentialStore = plaintext` writes to `~/.gcm/store` at mode `0700`. GCM has no
  default store on Linux, so without it credential writes fail; use `cache` to store
  nothing.
- The path is the `dotnet tool install -g` location; adjust it if you build with a
  non-default `USERNAME`.

The first HTTPS clone or push triggers GCM's sign-in flow. Credentials are not persisted
by default - add a volume for `/home/developer/.gcm` to keep them across recreations.
The image pre-creates that directory so the volume is not seeded `root`-owned.

## 🐳 Docker (outside of Docker)

The image ships the **Docker CLI** so you can run `docker` / `docker compose` from
inside the container against the **host's Docker daemon** (a.k.a. Docker-outside-of-Docker,
or "DooD") - there is no separate in-container daemon and no `privileged` mode required.

Everything is baked into the image at build time; no Dev Container Feature is used:

- The Docker CLI client is installed from the official signed repository
  (`docker-ce-cli` + `docker-compose-plugin` from Docker's apt repo on Ubuntu).
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

Build from the **repo root** - the `Dockerfile`s `COPY` from `Ubuntu/LTS/cfg/...`, so the
build context must be the repository root, not the flavor directory:

```bash
docker buildx build --load -t ubuntu-lts-devbox:local -f ./Ubuntu/LTS/Dockerfile .
```

> [!NOTE]
> On macOS the default builder targets the host platform. Pass `--platform linux/amd64`
> (portable) or `--platform linux/arm64` (native on Apple Silicon) so a Linux image is
> produced.

## ▶️ Run Locally

```bash
docker run --rm -it --user developer ubuntu-lts-devbox:local
```

To try Docker-outside-of-Docker manually, bind-mount the host socket and run the init
helper. A **fresh shell** is needed afterwards so the new group membership takes effect:

```bash
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ubuntu-lts-devbox:local
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
locally, run from the **repo root** (the `Dockerfile` `COPY`s from `Ubuntu/LTS/cfg/...`,
so the build context must be the repository root):

```bash
docker buildx build --load --platform linux/amd64 -t ubuntu-lts-devbox:local -f ./Ubuntu/LTS/Dockerfile .
```

> [!NOTE]
> On macOS pass `--platform linux/amd64` (portable) or `--platform linux/arm64` (native on
> Apple Silicon) so a Linux image is produced.

### 🔗 Use the local image

Point a project's `devcontainer.json` at your local build instead of the published one.
Either retag to the template's image name:

```bash
docker tag ubuntu-lts-devbox:local docker.io/vkotzsev/ubuntu-lts:latest
```

…or, in a throwaway test workspace, copy the template and overwrite its `image` field:

```bash
mkdir -p /tmp/doo-test/.devcontainer
cp ./Ubuntu/LTS/.devcontainer/devcontainer.json /tmp/doo-test/.devcontainer/devcontainer.json
# edit the copied file so "image" points at ubuntu-lts-devbox:local
```

### ✅ Bring it up and verify

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

Published to `docker.io/vkotzsev/ubuntu-lts`. This flavor tracks a fixed release
version:

- `latest` - the most recent build from `main`
- `26.04` - the pinned base version; overwritten on each `main` build with the newest content

Builds from non-`main` branches publish pre-release tags instead:

- `beta-26.04-<short-sha>`
- `beta-<branch>-<short-sha>`
- `beta-<branch>-latest`

In addition, every build (on any branch) publishes an immutable tag equal to the full 40-char
commit SHA so you can pin the image to the exact commit it was built from.

## 📝 Notes

- `CMD` defaults to Fish for an interactive developer session
