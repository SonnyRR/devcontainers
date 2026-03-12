# ---------------------------------------------------------------------------------------
# Vasil Kotsev's Ubuntu LTS Devcontainer Image
# ---------------------------------------------------------------------------------------
# Description : General-purpose Ubuntu-based devcontainer image tailored for .NET/NodeJS ecosystems
# Author      : Vasil Kotsev
# Updated     : 2026-02-12
# ---------------------------------------------------------------------------------------
FROM ubuntu:24.04

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

## Install base developer toolchains.
## NOTE: On Ubuntu 24.04 the .NET SDK ships in the distro's own apt feed
## (Microsoft no longer publishes .NET to packages.microsoft.com for Ubuntu),
## so dotnet-sdk-10.0 is installed straight from apt here.
## The lib*/font packages are the headless-browser (Playwright) runtime deps;
## the *t64 suffixes are the Ubuntu 24.04+ time_t-transition package names.
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo \
      gcc \
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
      pinentry-curses \
      fish \
      tmux \
      fzf \
      ripgrep \
      jq \
      fd-find \
      lazygit \
      git \
      neovim \
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

## Install developer CLIs that Ubuntu does not package (fnm, sops),
## pulling the latest release binaries for the build host's architecture.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) sops_arch="linux.amd64" ;; \
      arm64) sops_arch="linux.arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest -o /tmp/sops-release.json; \
    sops_ver="$(grep -Po '"tag_name": *"v\K[^"]*' /tmp/sops-release.json)"; \
    curl -fsSL "https://github.com/getsops/sops/releases/download/v${sops_ver}/sops-v${sops_ver}.${sops_arch}" -o /usr/local/bin/sops; \
    chmod +x /usr/local/bin/sops; \
    curl -fsSL https://fnm.vercel.app/install -o /tmp/fnm-install.sh; \
    bash /tmp/fnm-install.sh --install-dir /usr/local/bin --skip-shell; \
    rm -f /tmp/sops-release.json /tmp/fnm-install.sh

RUN useradd -m -s /usr/bin/fish "$USERNAME"

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

## Set up sensible defaults for the fish terminal.
RUN mkdir -p /home/$USERNAME/.config/fish
COPY Ubuntu/LTS/cfg/config.fish /home/$USERNAME/.config/fish/config.fish
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

## Environment variables.
## NOTE: These are primarily configured in Ubuntu/LTS/cfg/config.fish,
## and are duplicated here as a fallback for non-fish shells.
ENV SHELL=/usr/bin/fish \
    FNM_DIR=/home/${USERNAME}/.local/share/fnm \
    EDITOR=nvim \
    VISUAL=nvim \
    DOTNET_CLI_TELEMETRY_OPTOUT=true \
    SSL_CERT_DIR=/home/${USERNAME}/.aspnet/dev-certs/trust:/etc/ssl/certs \
    PATH=/home/${USERNAME}/.dotnet/tools:/home/${USERNAME}/.local/bin:${PATH}

## Set up fnm fallback for bash.
COPY Ubuntu/LTS/cfg/.bashrc /home/$USERNAME/.bashrc
RUN chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

USER $USERNAME

## Set up NodeJS (Latest LTS).
RUN fish -lc 'fnm install --lts; fnm default lts-latest'

## Set up AI CLI Harnesses & additional CLI tools as global NodeJS packages.
RUN fish -lc 'fnm exec --using lts-latest npm install -g corepack@latest opencode-ai @anthropic-ai/claude-code tree-sitter-cli'

## Setup pnpm
RUN fish -lc 'fnm exec --using lts-latest corepack enable pnpm'

## Trust the ASP.NET Core Development SSL certificate.
RUN fish -lc 'dotnet dev-certs https -t'

## Provision global dotnet tools
RUN fish -lc 'dotnet tool install -g dotnet-ef && dotnet tool install -g dotnet-outdated-tool && dotnet tool install -g gitversion.tool && dotnet tool install -g nuke.globaltool && dotnet tool install -g ilspycmd && dotnet tool install -g easydotnet'

CMD ["/usr/bin/fish"]
