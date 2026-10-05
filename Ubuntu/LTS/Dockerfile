# ---------------------------------------------------------------------------------------
# Vasil Kotsev's Ubuntu LTS Devcontainer Image
# ---------------------------------------------------------------------------------------
# Description : General-purpose Ubuntu-based devcontainer image tailored for .NET/NodeJS ecosystems
# Author      : Vasil Kotsev
# Updated     : 2026-09-28
# ---------------------------------------------------------------------------------------
FROM ubuntu:26.04

ARG USERNAME=developer
ARG DEBIAN_FRONTEND=noninteractive

## Refresh software repositories & install pre-requisites for
## SSL certificate management.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      openssl \
      gnupg \
      lsb-release

## Set up the official GitHub CLI apt repository for the `gh` package.
## NOTE: gh is not in the official Ubuntu repos. This uses GitHub's maintained,
## GPG-signed keyring + apt repo (the official Debian/Ubuntu method),
## keeping gh on the same auditable "signed repo baked at build time"
## footing as the rest of the toolchain.
## See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    mkdir -p -m 755 /etc/apt/sources.list.d && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list

## Set up the official Yazi apt repository for the `yazi` package.
## NOTE: Yazi is not in the official Ubuntu repos. This uses the project's
## maintained, GPG-signed keyring + apt repo (the official Debian/Ubuntu
## method), keeping yazi on the same auditable "signed repo baked at build
## time" footing as gh. The repo ships latest stable amd64/arm64 builds.
## See: https://yazi-rs.github.io/docs/installation/#apt
RUN curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg \
      -o /etc/apt/keyrings/yazi-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/yazi-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds stable main" \
      > /etc/apt/sources.list.d/yazi.list

## Set up the official Docker apt repository for the docker CLI.
## NOTE: Docker is not in the Ubuntu feed. This uses Docker's maintained,
## GPG-signed keyring + apt repo (the official method), keeping docker on the
## same auditable "signed repo baked at build time" footing as gh/yazi.
## Only the CLI client (docker-ce-cli) is installed; the daemon runs on the
## host (Docker-outside-of-Docker). See:
## https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list

## Install base developer toolchains.
## NOTE: On Ubuntu 26.04 the .NET SDK ships in the distro's own apt feed
## (Microsoft no longer publishes .NET to packages.microsoft.com for Ubuntu),
## so dotnet-sdk-10.0 is installed straight from apt here.
## The lib*/font packages are the headless-browser (Playwright) runtime deps;
## the *t64 suffixes are the Ubuntu 26.04+ time_t-transition package names.
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo \
      build-essential \
      libnss3 \
      libnspr4 \
      libatk1.0-0t64 \
      libatk-bridge2.0-0t64 \
      libatspi2.0-0t64 \
      libcups2t64 \
      libdrm2 \
      libgbm1 \
      libxkbcommon0 \
      libasound2t64 \
      libxcomposite1 \
      libxdamage1 \
      libxfixes3 \
      libxrandr2 \
      libpango-1.0-0 \
      libcairo2 \
      libx11-6 \
      libx11-xcb1 \
      libxcb1 \
      fonts-liberation \
      openssh-client \
      gnome-keyring \
      ncdu \
      gpg \
      pass \
      pinentry-curses \
      fish \
      tmux \
      fzf \
      ripgrep \
      jq \
      fd-find \
      7zip \
      file \
      gawk \
      ffmpeg \
      poppler-utils \
      zoxide \
      yazi \
      lazygit \
      git \
      unzip \
      tar \
      gh \
      sqlite3 \
      dotnet-sdk-10.0 \
      python3 \
      luajit \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## Install the Azure CLI.
## NOTE: Azure CLI is not in the Ubuntu feed. The official Microsoft apt repo
## keys off the release codename, which may lag for a brand-new LTS, so we use
## Microsoft's maintained installer which adds the repo (with fallback) itself.
RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb -o /tmp/install-azure-cli.sh && \
    bash /tmp/install-azure-cli.sh && \
    rm -f /tmp/install-azure-cli.sh

## Install the Docker CLI client + compose plugin (Docker-outside-of-Docker).
## NOTE: Only the CLI is installed; the Docker daemon runs on the host and the
## socket is bind-mounted into the container at devcontainer-create time.
RUN apt-get update && apt-get install -y --no-install-recommends \
      docker-ce-cli \
      docker-compose-plugin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## Install developer CLIs that Ubuntu does not package (fnm, sops),
## pulling the latest release binaries for the build host's architecture.
## NOTE: The latest version is resolved from the GitHub release page's
## 302 redirect (https://github.com/<owner>/<repo>/releases/latest) rather
## than the GitHub REST API, because unauthenticated api.github.com calls
## are rate-limited (60/hr per IP) and CI runners share IPs, which made the
## build fail intermittently with "API rate limit exceeded".
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) sops_arch="linux.amd64" ;; \
      arm64) sops_arch="linux.arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    sops_ver="$(curl -fsS -o /dev/null -w '%{redirect_url}' https://github.com/getsops/sops/releases/latest | sed -E 's:.*/tag/v([^/]+)$:\1:')"; \
    curl -fsSL "https://github.com/getsops/sops/releases/download/v${sops_ver}/sops-v${sops_ver}.${sops_arch}" -o /usr/local/bin/sops; \
    chmod +x /usr/local/bin/sops; \
    curl -fsSL https://fnm.vercel.app/install -o /tmp/fnm-install.sh; \
    bash /tmp/fnm-install.sh --install-dir /usr/local/bin --skip-shell; \
    rm -f /tmp/fnm-install.sh

## Install Neovim (latest stable) from the official GitHub release tarball.
## NOTE: Ubuntu's apt feed ships an outdated Neovim, so we pull the latest
## stable release directly from GitHub, mirroring the sops/fnm approach above
## (version resolved from the release-page redirect, not the rate-limited API).
## See: https://github.com/neovim/neovim/releases/latest
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) nvim_arch="x86_64" ;; \
      arm64) nvim_arch="arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    nvim_ver="$(curl -fsS -o /dev/null -w '%{redirect_url}' https://github.com/neovim/neovim/releases/latest | sed -E 's:.*/tag/v([^/]+)$:\1:')"; \
    curl -fsSL "https://github.com/neovim/neovim/releases/download/v${nvim_ver}/nvim-linux-${nvim_arch}.tar.gz" \
      -o /tmp/nvim.tar.gz; \
    tar -xzf /tmp/nvim.tar.gz -C /opt; \
    ln -s "/opt/nvim-linux-${nvim_arch}/bin/nvim" /usr/local/bin/nvim; \
    rm -f /tmp/nvim.tar.gz

RUN useradd -m -s /usr/bin/fish "$USERNAME"

## Create the docker group for Docker-outside-of-Docker and grant the
## developer user access; the in-container GID is aligned to the mounted
## host socket at devcontainer-create time (see docker-socket-init.sh).
RUN getent group docker >/dev/null || groupadd docker && \
    usermod -aG docker "$USERNAME"

## Set up sudoers.
RUN getent group wheel >/dev/null || groupadd wheel && \
    usermod -aG wheel "$USERNAME" && \
    printf '%s\n' 'Defaults:%wheel !targetpw' > /etc/sudoers.d/00-wheel-auth && \
    printf '%s\n' 'Defaults:%wheel !rootpw' >> /etc/sudoers.d/00-wheel-auth && \
    chmod 0440 /etc/sudoers.d/00-wheel-auth && \
    printf '%s\n' '%wheel ALL=(ALL:ALL) PASSWD: ALL' > /etc/sudoers.d/10-wheel-passwd && \
    printf '%s\n' "$USERNAME ALL=(root) NOPASSWD: /usr/bin/passwd $USERNAME" > /etc/sudoers.d/11-passwd-bootstrap && \
    chmod 0440 /etc/sudoers.d/11-passwd-bootstrap && \
    chmod 0440 /etc/sudoers.d/10-wheel-passwd

## Install the Docker-outside-of-Docker socket GID alignment helper and
## allow the developer user to run it without a password (mirrors the
## passwd-bootstrap NOPASSWD rule). See: Ubuntu/LTS/cfg/docker-socket-init.sh
COPY Ubuntu/LTS/cfg/docker-socket-init.sh /usr/local/bin/docker-socket-init.sh
RUN chmod 0755 /usr/local/bin/docker-socket-init.sh && \
    chown root:root /usr/local/bin/docker-socket-init.sh && \
    printf '%s\n' "$USERNAME ALL=(root) NOPASSWD: /usr/local/bin/docker-socket-init.sh" > /etc/sudoers.d/12-docker-socket-init && \
    chmod 0440 /etc/sudoers.d/12-docker-socket-init

## Register Git Credential Manager as the system-wide Git credential helper.
## NOTE: This is byte-for-byte what `git-credential-manager configure --system`
## writes, but it is authored here instead of executed because the tool is
## installed further down as the non-root `developer` user, who cannot write
## /etc/gitconfig at build time. Writing it at the system level (rather than via
## a plain `git-credential-manager configure`) is also what makes it survive the
## devcontainer template's READ-ONLY bind mount of the host ~/.gitconfig over
## /home/developer/.gitconfig - a user-level entry would be shadowed at runtime.
## The leading empty `helper =` is required: Git resets the accumulated helper
## chain on an empty value, so a helper inherited from the host ~/.gitconfig is
## dropped and GCM becomes the only helper. See:
## https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/usage.md
RUN printf '%s\n\t%s\n\t%s\n' \
      '[credential]' \
      'helper =' \
      "helper = /home/$USERNAME/.dotnet/tools/git-credential-manager" \
      > /etc/gitconfig

## Set up sensible defaults for the fish terminal.
RUN mkdir -p /home/$USERNAME/.config/fish
COPY Ubuntu/LTS/cfg/config.fish /home/$USERNAME/.config/fish/config.fish
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

## Environment variables.
## NOTE: These are primarily configured in Ubuntu/LTS/cfg/config.fish,
## and are duplicated here as a fallback for non-fish shells.
## GCM_CREDENTIAL_STORE=gpg selects Git Credential Manager's GPG/`pass`-compatible
## credential store. GCM ships with NO default store on Linux, so without this
## every credential write fails until a store is chosen. See the "Git Credential
## Manager" section of README.md for the one-time in-container key bootstrap.
## GPG_TTY=/dev/null is a deliberate non-terminal, not a real TTY: GCM refuses to
## load the gpg store unless GPG_TTY or SSH_TTY is merely *present* (a plain
## env-var presence check in CredentialStore.ValidateGpgPass), and because the
## documented bootstrap produces a passphrase-less key, gpg-agent never actually
## opens a terminal - so this satisfies that guard with no TTY and no pinentry.
## NOTE: this is only valid while the key has no passphrase. If you passphrase-
## protect it, drop this and `export GPG_TTY=$(tty)` in a real interactive session.
ENV SHELL=/usr/bin/fish \
    FNM_DIR=/home/${USERNAME}/.local/share/fnm \
    EDITOR=nvim \
    VISUAL=nvim \
    DOTNET_CLI_TELEMETRY_OPTOUT=true \
    GCM_CREDENTIAL_STORE=gpg \
    GPG_TTY=/dev/null \
    SSL_CERT_DIR=/home/${USERNAME}/.aspnet/dev-certs/trust:/etc/ssl/certs \
    PATH=/home/${USERNAME}/.dotnet/tools:/home/${USERNAME}/.local/bin:${PATH}

## Set up fnm fallback for bash.
COPY Ubuntu/LTS/cfg/.bashrc /home/$USERNAME/.bashrc
RUN chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

USER $USERNAME

## Set up NodeJS (Latest LTS).
RUN fish -lc 'fnm install --lts; fnm default lts-latest'

## Set up AI CLI Harnesses & additional CLI tools as global NodeJS packages.
RUN fish -lc 'fnm exec --using lts-latest npm install -g corepack@latest @opencode/cli @anthropic-ai/claude-code tree-sitter-cli'

## Setup pnpm
RUN fish -lc 'fnm exec --using lts-latest corepack enable pnpm'

## Trust the ASP.NET Core Development SSL certificate.
RUN fish -lc 'dotnet dev-certs https -t'

## Provision global dotnet tools
RUN fish -lc 'dotnet tool install -g dotnet-ef && dotnet tool install -g dotnet-outdated-tool && dotnet tool install -g gitversion.tool && dotnet tool install -g nuke.globaltool && dotnet tool install -g ilspycmd && dotnet tool install -g easydotnet && dotnet tool install -g git-credential-manager'

CMD ["/usr/bin/fish"]
