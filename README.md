# 📦 Development Containers & Images

This repository contains personal container images for Devcontainers.

## 🧭 Purpose

- Provide standardized, reproducible `Linux` development environments
- Centralize image definitions, toolchains, and security/trust configuration in one place
- Publish curated images to Docker Hub for consumption by real code repositories

## 🧱 Toolchains

The full toolchain (language runtimes, SDKs, CLIs, shell, editor tooling, certificate
trust, etc.) is **installed at image build time inside the `Dockerfile`** and shipped
as part of the published `ACR` image. We deliberately **do not** rely on the devcontainer
spec's [Features](https://containers.dev/features) mechanism to provision the core
toolchain at container-create time.

This is intentional. Baking the toolchain into the build phase gives us:

- **Reproducibility.** A tagged image (e.g. `opensuse-tumbleweed:2026.02.12.1`) is
  byte-identical for every developer who pulls it. No drift from upstream Features
  picking up a new version on a Monday morning.
- **Fast container startup.** No multi-minute per-create install step - the container
  is ready as soon as it's pulled.
- **Offline / restricted-network friendly.** Once the image is in `ACR`, creating a
  container does not require hitting Microsoft, GitHub, OCI Features registries, or
  any other third-party endpoint.
- **Single auditable supply chain.** Every install command, package version, signing
  key, and trust root lives in the `Dockerfile` in this repo, is reviewed via PR, and
  is built and scanned in CI. No opaque per-feature install scripts run on the
  developer's machine.
- **Version pinning via the image tag**, not via a moving Feature version.

Devcontainer Features remain a perfectly valid escape hatch for **project-specific
additions** that don't belong in the shared base image (see
[Add a devcontainer template to your project](#4️⃣-add-a-devcontainer-template-to-your-project)).
The core toolchain, however, always comes from the image.

## 🛣️ Roadmap

- Additional `Linux` image flavors will be added over time for different team and workload needs
- Each flavor will have its own directory with a `Dockerfile` and image-specific `README`

## 🖼️ Images

> [!NOTE]
> 📄 **Every flavor below ships a ready-to-use `devcontainer.json` template** under
> its `<flavor>/.devcontainer/devcontainer.json`. The template wires up the published
> `ACR` image with sensible defaults (non-root `developer` user, `Fish` as the default
> VS Code terminal, persistent `Fish` history & XDG cache volumes, a read-only bind
> mount of your host `~/.gitconfig`, a tuned `NODE_OPTIONS` heap, and a curated set of
> VS Code extensions for `.NET`, web, and GitHub workflows). It is intended as a
> **starting point**: you can freely extend it with any property from the
> [`devcontainer.json` reference](https://containers.dev/implementors/json_reference/) -
> additional [`mounts`](https://containers.dev/implementors/json_reference/#mounts)
> (bind mounts, named volumes, `tmpfs`), extra `forwardPorts`, `postCreateCommand`
> hooks, `containerEnv`/`remoteEnv` variables, and so on. If you need a tool that
> isn't in the base image, you can also layer on a project-specific
> [Dev Container Feature](https://containers.dev/features) - but note that the **core
> toolchain itself is intentionally baked into the image at build time, not provisioned
> via Features** (see [Toolchains](#-toolchains)).
> You can drop the template straight into a project at `.devcontainer/devcontainer.json` -
> see [Add a devcontainer template to your project](#4️⃣-add-a-devcontainer-template-to-your-project)
> and each flavor's own README for the full breakdown.

### 🐧 OpenSUSE Tumbleweed

| Metadata              | Value                                                 |
| --------------------- | ----------------------------------------------------- |
| Author                | `Vasil Kotsev`                                        |
| Path                  | `OpenSUSE/Tumbleweed/`                                |
| Devcontainer template | `OpenSUSE/Tumbleweed/.devcontainer/devcontainer.json` |

The current image is based on `opensuse/tumbleweed:latest` and includes:

- Microsoft package repo: configured for `OpenSUSE` to install `.NET` packages
- Sensible defaults & toolchains for `.NET` and `Node.js` environments

### 📋 Installed Software

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
  - `FZF` (w/shell completion)
  - `Ripgrep` (w/shell completion)
  - `fd` (w/shell completion)
  - `zoxide` (smarter `cd`)
  - `tmux` (terminal multiplexer)
  - `ncdu` (disk usage analyzer)
- Developer `CLI` and editors:
  - `jq`
  - `Neovim`
  - `SQLite`
  - `tree-sitter-cli` (global `npm` install)
- File management & archives:
  - `Yazi` (terminal file manager)
  - `7-Zip`
  - `file`
- Media & document tools:
  - `FFmpeg`
  - `Poppler` PDF tools (`poppler-tools`)
- Language and platform toolchains:
  - `Python 3.14`
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
- Browser/runtime dependencies:
  - `GNOME Keyring`
  - Browser runtime support libraries (graphics/audio/X11/font stack)
- AI developer tooling:
  - `OpenCode` (global `npm` install)
  - `Anthropic Claude Code CLI` (global `npm` install)

Note: the base image `opensuse/tumbleweed:latest` may include additional preinstalled OS packages not listed above.

### 🐧 OpenSUSE Leap

| Metadata              | Value                                           |
| --------------------- | ----------------------------------------------- |
| Author                | `Vasil Kotsev`                                  |
| Path                  | `OpenSUSE/Leap/`                                |
| Devcontainer template | `OpenSUSE/Leap/.devcontainer/devcontainer.json` |

A variant of the image above, based on the stable `opensuse/leap:latest` release
rather than the rolling `Tumbleweed` base. It provisions the same corporate trust
setup, Microsoft package repo, toolchains, and developer defaults - and ships an
equivalent ready-to-use `devcontainer.json` template. See `OpenSUSE/Leap16.0/README.md`
for the full breakdown.

### 🐧 Ubuntu LTS

| Metadata              | Value                                        |
| --------------------- | -------------------------------------------- |
| Author                | `Vasil Kotsev`                               |
| Path                  | `Ubuntu/LTS/`                                |
| Devcontainer template | `Ubuntu/LTS/.devcontainer/devcontainer.json` |

A Debian-family variant based on `ubuntu:26.04`, providing the same corporate trust
setup, toolchains, and developer defaults (`developer` user, `Fish` shell) as the
images above, and a matching ready-to-use `devcontainer.json` template. Key distribution
differences: `.NET` is installed from Ubuntu's own apt feed (Microsoft no longer
publishes `.NET` to `packages.microsoft.com` for Ubuntu), the `Azure CLI` is installed
via Microsoft's maintained installer, and `fnm`/`sops` are pulled as release binaries
since they are not packaged in apt. See `Ubuntu/LTS/README.md` for the full breakdown.

## ☁️ Consumption Model

- Use local builds for validation and iteration while developing image changes
- For actual application repositories, pull published images from Docker Hub

## 🏷️ Image Tags

Each flavor is published to `docker.io/<your-dockerhub-username>/<image>` with the following stable
tags built from `main`:

| Flavor              | Image                 | Stable tags                                |
| ------------------- | --------------------- | ------------------------------------------ |
| OpenSUSE Tumbleweed | `opensuse-tumbleweed` | `latest`, `YYYY.MM.DD.N` (dated snapshots) |
| OpenSUSE Leap       | `opensuse-leap`       | `latest`, `16.0`                           |
| Ubuntu LTS          | `ubuntu`              | `latest`, `26.04`                          |

- **Tumbleweed** uses date-based (`CalVer`) versioning: every `main` build produces a new,
  immutable `YYYY.MM.DD.N` snapshot (e.g. `2026.02.12.1`) and moves `latest` to it.
- **Leap** and **Ubuntu** track a fixed version tag (`16.0` / `26.04`) that is overwritten
  with the newest content on each `main` build, alongside `latest`.
- Every build (on any branch) also publishes an immutable tag equal to the full 40-char
  commit SHA, letting you pin an image to the exact commit it was built from.
- Builds from non-`main` branches publish pre-release tags instead of the above:
  `beta-<version>-<short-sha>`, `beta-<branch>-<short-sha>`, and `beta-<branch>-latest`.

See each flavor's README for its specific tags.

## 🚀 Using the Devcontainers

To use one of these images in your own repository, copy the relevant flavor's
`devcontainer.json` template into your project, then authenticate to Docker Hub
so the image can be pulled.

### ✅ Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/) with the
  [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  extension (or the [`devcontainer` CLI](https://github.com/devcontainers/cli))
- A container runtime (`Docker` or `Podman`)
- The [`Azure CLI`](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az`)

### 1️⃣ Log in to Docker Hub

Use the `Docker CLI` to log the container runtime in to Docker Hub:

```bash
docker login
```

### 2️⃣ Add a devcontainer template to your project

Each flavor ships a ready-to-use `devcontainer.json` example with sensible defaults
(image reference, non-root `developer` user, `Fish` as the default VS Code terminal,
persistent `Fish` history & XDG cache volumes, a read-only bind mount of your host
`~/.gitconfig`, a tuned `NODE_OPTIONS` heap, and a curated set of VS Code extensions).
Treat it as a **starting point** - extend it with anything from the
[`devcontainer.json` reference](https://containers.dev/implementors/json_reference/),
e.g. additional [`mounts`](https://containers.dev/implementors/json_reference/#mounts)
(bind mounts, named volumes, `tmpfs`), extra `forwardPorts`, `postCreateCommand`
hooks, or `containerEnv`/`remoteEnv` variables. If a project genuinely needs a tool
that isn't in the base image, you can also layer on a project-specific
[Dev Container Feature](https://containers.dev/features) - but the **core toolchain
itself is intentionally baked into the image at build time** rather than provisioned
via Features (see [Toolchains](#-toolchains)).

Copy the template for the flavor you want into your repository at
`.devcontainer/devcontainer.json`:

| Flavor              | Template                                              | Published image                                         |
| ------------------- | ----------------------------------------------------- | ------------------------------------------------------- |
| OpenSUSE Tumbleweed | `OpenSUSE/Tumbleweed/.devcontainer/devcontainer.json` | `docker.io/<your-dockerhub-username>/opensuse-tumbleweed:latest` |
| OpenSUSE Leap       | `OpenSUSE/Leap/.devcontainer/devcontainer.json`       | `docker.io/<your-dockerhub-username>/opensuse-leap:latest`       |
| Ubuntu LTS          | `Ubuntu/LTS/.devcontainer/devcontainer.json`          | `docker.io/<your-dockerhub-username>/ubuntu-lts:latest`          |

> [!TIP]
> The templates reference the `:latest` tag. To pin to a specific version, change the
> `image` tag (e.g. `docker.io/<your-dockerhub-username>/ubuntu-lts:26.04`), or pin to an exact commit
> with the full-SHA tag (e.g. `docker.io/<your-dockerhub-username>/ubuntu-lts:<40-char-commit-sha>`).

### 5️⃣ Open the project in the container

- **VS Code:** open the repository and run **Dev Containers: Reopen in Container** from the
  command palette.
- **CLI:** run `devcontainer up --workspace-folder .` from the repository root.

VS Code (or the CLI) will pull the image from `ACR` using the credentials configured in
step 3 and start your development container.
