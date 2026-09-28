# 📦 Development Containers & Images

This repository contains personal container images for Devcontainers, tailored for
AI-assisted .NET/NodeJS software development.

## 🧭 Purpose

- Provide standardized, reproducible `Linux` development environments
- Centralize image definitions, toolchains, and security/trust configuration in one place
- Publish curated images to Docker Hub for consumption by real code repositories

## 🧱 Toolchains

The full toolchain (language runtimes, SDKs, CLIs, shell, editor tooling, certificate
trust, etc.) is **installed at image build time inside the `Dockerfile`** and shipped
as part of the published image. I deliberately **do not** rely on the devcontainer
spec's [Features](https://containers.dev/features) mechanism to provision the core
toolchain at container-create time.

This is intentional. Baking the toolchain into the build phase gives us:

- **Reproducibility.** A tagged image (e.g. `opensuse-tumbleweed:2026.02.12.1`) is
  byte-identical for every developer who pulls it. No drift from upstream Features
  picking up a new version on a Monday morning.
- **Fast container startup.** No multi-minute per-create install step - the container
  is ready as soon as it's pulled.
- **Single auditable supply chain.** Every install command, package version, signing
  key, and trust root lives in the `Dockerfile` in this repo, is reviewed via PR, and
  is built and scanned in CI. No opaque per-feature install scripts run on the
  developer's machine.
- **Version pinning via the image tag**, not via a moving Feature version.

Devcontainer Features remain a perfectly valid escape hatch for **project-specific
additions** that don't belong in the shared base image (see
[Add a devcontainer template to your project](#4️⃣-add-a-devcontainer-template-to-your-project)).
The core toolchain, however, always comes from the image - for example,
Docker-outside-of-Docker (the `docker` CLI client plus a bind-mounted host socket) is
baked into every flavor rather than pulled in via the `docker-outside-of-docker` Feature.

## 🖼️ Images

> [!NOTE]
> 📄 **Every flavor below ships a ready-to-use `devcontainer.json` template** under
> its `<flavor>/.devcontainer/devcontainer.json`. The template wires up the published
> image with sensible defaults (non-root `developer` user, `Fish` as the default
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
  - `pass` (GNU password-store; packaged as `password-store` on `openSUSE`)
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
  - `Git Credential Manager` (`git-credential-manager`, registered as the
    system-wide `credential.helper` - see
    [Git Credential Manager](#-git-credential-manager))
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
    - `git-credential-manager`
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

Note: the base image `opensuse/tumbleweed:latest` may include additional preinstalled OS packages not listed above.

### 🐧 OpenSUSE Leap

| Metadata              | Value                                           |
| --------------------- | ----------------------------------------------- |
| Author                | `Vasil Kotsev`                                  |
| Path                  | `OpenSUSE/Leap/`                                |
| Devcontainer template | `OpenSUSE/Leap/.devcontainer/devcontainer.json` |

A variant of the image above, based on the stable `opensuse/leap:16.0` release
rather than the rolling `Tumbleweed` base. It provisions the same corporate trust
setup, Microsoft package repo, toolchains, and developer defaults - and ships an
equivalent ready-to-use `devcontainer.json` template. See `OpenSUSE/Leap/README.md`
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

## 🔐 Git Credential Manager

Every flavor installs
[Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager)
(GCM) as a global `.NET` tool - the method the GCM project documents as preferred on
Linux - and registers it as the **system-wide** Git credential helper in
`/etc/gitconfig`:

```ini
[credential]
    helper =
    helper = /home/developer/.dotnet/tools/git-credential-manager
```

- The leading empty `helper =` is deliberate. Git resets the accumulated helper chain
  on an empty value, so any helper inherited from your host `~/.gitconfig` is dropped
  and GCM becomes the only helper in the chain.
- System scope, rather than a plain `git-credential-manager configure`, is what makes
  this survive the templates' **read-only** bind mount of your host `~/.gitconfig` over
  `/home/developer/.gitconfig`. A user-level entry would be shadowed at runtime.

### One-time in-container bootstrap

GCM ships with **no default credential store on Linux**, so the images select its
GPG/`pass`-compatible store (`GCM_CREDENTIAL_STORE=gpg`) to keep credentials encrypted
at rest inside the container. That store needs a GPG key of its own. Generate one
entirely inside the devcontainer - **nothing is required on the host machine**:

```bash
# 1. create a passphrase-less key (an empty passphrase means gpg-agent never prompts)
gpg --batch --passphrase '' \
    --quick-generate-key 'Your Name <you@example.com>' default default never

# 2. initialise the password store against that key
pass init you@example.com
```

Verify:

```bash
git-credential-manager --version
git config --system --get-all credential.helper
```

The first HTTPS `git clone`/`git push` then triggers GCM's normal device-code or
browser sign-in flow.

> [!NOTE]
> The images set `GPG_TTY=/dev/null`. That is a deliberate non-terminal, not a real
> TTY: GCM refuses to load the gpg store unless `GPG_TTY` or `SSH_TTY` is merely
> *present* (a plain environment-variable presence check), and because the key above
> has no passphrase, `gpg-agent` never actually opens a terminal. This is what lets
> the same setup work over SSH, in the VS Code terminal, and in the VS Code Git UI,
> with no TTY plumbing.

> [!IMPORTANT]
> `GPG_TTY=/dev/null` is only valid while the key has **no** passphrase. If you
> passphrase-protect it, prompting will fail - drop the variable and run
> `export GPG_TTY=$(tty)` in a real interactive session instead.

> [!NOTE]
> None of this is persisted by default, because a container's writable layer is
> ephemeral: a recreated container means a fresh key and a fresh `pass init`. To carry
> the key and stored credentials across recreations, add volumes for
> `/home/developer/.gnupg` and `/home/developer/.password-store` to your
> `devcontainer.json`. Create both directories in the image first - Docker seeds a
> fresh volume from the image path, so if the paths do not exist the volume is created
> `root`-owned and GnuPG will refuse to use it.

Prefer a different store? GCM gives environment variables precedence over Git config,
so any of these work per-shell without editing `/etc/gitconfig`:

```bash
GCM_CREDENTIAL_STORE=cache git clone ...      # in-memory only, nothing at rest
GCM_CREDENTIAL_STORE=plaintext git clone ...  # ⚠️ unencrypted on disk
GCM_CREDENTIAL_STORE=none git clone ...       # no store; chain your own helper
```

## 🏷️ Image Tags

Each flavor is published to `docker.io/vkotzsev/<image>` with the following stable
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
| OpenSUSE Tumbleweed | `OpenSUSE/Tumbleweed/.devcontainer/devcontainer.json` | `docker.io/vkotzsev/opensuse-tumbleweed:latest` |
| OpenSUSE Leap       | `OpenSUSE/Leap/.devcontainer/devcontainer.json`       | `docker.io/vkotzsev/opensuse-leap:latest`       |
| Ubuntu LTS          | `Ubuntu/LTS/.devcontainer/devcontainer.json`          | `docker.io/vkotzsev/ubuntu-lts:latest`          |

> [!TIP]
> The templates reference the `:latest` tag. To pin to a specific version, change the
> `image` tag (e.g. `docker.io/vkotzsev/ubuntu-lts:26.04`), or pin to an exact commit
> with the full-SHA tag (e.g. `docker.io/vkotzsev/ubuntu-lts:<40-char-commit-sha>`).

### 5️⃣ Open the project in the container

- **VS Code:** open the repository and run **Dev Containers: Reopen in Container** from the
  command palette.
- **CLI:** run `devcontainer up --workspace-folder .` from the repository root.

### 🧪 Build locally & drive with the devcontainer CLI

You don't have to consume the published image - you can build any flavor locally and
point a project at it. Build from the **repo root** (the `Dockerfile`s `COPY` from
`<flavor>/cfg/...`, so the build context must be the repository root):

```bash
docker buildx build --load --platform linux/amd64 -t ubuntu-lts-devbox:local -f ./Ubuntu/LTS/Dockerfile .
```

> [!NOTE]
> On macOS pass `--platform linux/amd64` (or `linux/arm64` on Apple Silicon); the default
> builder otherwise targets the host platform and won't produce a Linux image.

Then either retag to the template's image name (`docker.io/vkotzsev/<flavor>:latest`) or
copy the flavor's `devcontainer.json` and set its `image` to your local tag, and bring it
up with the CLI:

```bash
devcontainer up --workspace-folder /path/to/your-project
devcontainer exec --workspace-folder /path/to/your-project -- docker ps
```

The CLI has no `stop`/`down` command - tear down the container with Docker directly
(`docker ps` to find the name, then `docker rm -f <container>`). Each flavor's README has
the full local-build + CLI walkthrough, including the macOS Docker-outside-of-Docker socket
caveat (see [🐳 Docker (outside of Docker)](#-docker-outside-of-docker) in the flavor
READMEs).
