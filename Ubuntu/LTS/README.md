# 🐧 Ubuntu LTS Devcontainer Image

This directory contains the `Dockerfile` for a custom general-purpose devcontainer, based on `ubuntu:26.04`, alongside a template `devcontainer.json` for use in actual codebases.

## 📄 Devcontainer Template (with Sensible Defaults)

A ready-to-use `devcontainer.json` example ships at
[`./.devcontainer/devcontainer.json`](./.devcontainer/devcontainer.json). Drop it into
your project at `.devcontainer/devcontainer.json` to get a fully wired-up environment
out of the box. The template configures:

- **Image:** `docker.io/<your-dockerhub-username>/ubuntu-lts:latest` (pin to `26.04` for the
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
  `ghcr.io/devcontainers/features/docker-outside-of-docker`, `kubectl-helm-minikube`,
  `terraform`, `aws-cli`) via the `features` block. **But please don't use Features to
  replace toolchain that already lives in the base image** - see
  [Toolchains](#-toolchains).

## 🧭 Purpose

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
- Terminal and shell experience:
  - `Fish` shell (w/shell integration)
  - `fzf`
  - `ripgrep`
  - `fd`
  - `zoxide` (smarter `cd`)
  - `tmux` (terminal multiplexer)
  - `ncdu` (disk usage analyzer)
- Developer `CLI` and editors:
  - `jq`
  - `Neovim` (latest stable, GitHub release)
  - `SQLite`
  - `tree-sitter-cli` (global `npm` install)
- File management & archives:
  - `Yazi` (terminal file manager)
  - `7-Zip`
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
- Cloud and secrets tooling:
  - `Azure CLI`
  - `SOPS` (release binary)
- Browser/runtime dependencies:
  - `GNOME Keyring`
  - Browser runtime support libraries (graphics/audio/X11/font stack)
- AI developer tooling:
  - `OpenCode` (global `npm` install)
  - `Anthropic Claude Code CLI` (global `npm` install)

Note: the base image `ubuntu:26.04` may include additional preinstalled OS packages not listed above.

## 👤 User & Shell Defaults

- Creates a non-root user: `developer` (configurable via `ARG USERNAME`)
- Default shell is `Fish`: `/usr/bin/fish`
- User is added to `wheel` with sudo configuration files under `/etc/sudoers.d`
- MOTD includes guidance for enabling password-based sudo bootstrap

## 🛠️ Build Locally

```bash
docker buildx build --load -t ubuntu-lts-devbox:local -f .\Ubuntu\LTS\Dockerfile .
```

## ▶️ Run Locally

```bash
docker run --rm -it --user developer ubuntu-lts-devbox:local
```

## ☁️ Registry & Consumption Guidance

For real project repositories, this image should be consumed from Docker Hub, not rebuilt ad hoc per repository.

- Local build/run is intended for validation and iteration
- Production/standardized `DevContainer` usage should pull the published image from Docker Hub

## 🏷️ Image Tags

Published to `docker.io/<your-dockerhub-username>/ubuntu-lts`. This flavor tracks a fixed release
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
