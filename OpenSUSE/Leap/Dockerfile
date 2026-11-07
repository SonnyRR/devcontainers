# ----------------------------------------------------------------------------------------
# Stacked Deck OpenSUSE Leap Devcontainer Image
# ----------------------------------------------------------------------------------------
# Description : OpenSUSE Leap based devcontainer image tailored for .NET/NodeJS ecosystems
# Author      : Vasil Kotsev
# Updated     : 2026-10-05
# ----------------------------------------------------------------------------------------
FROM opensuse/leap:16.0

ARG USERNAME=developer

## Refresh software repositories & install pre-requisites for
## SSL certificate management.
## NOTE: By default OpenSUSE-Leap comes with these packages,
## but I'm adding them explicitly here in case there are updates.
RUN zypper -n ref && zypper -n in --no-recommends \
      ca-certificates \
      ca-certificates-mozilla \
      curl \
      openssl

## Set up Microsoft RPM repository for .NET SDK & Runtimes.
## See: https://learn.microsoft.com/en-us/dotnet/core/install/linux-opensuse?tabs=dotnet10#opensuse-leap-16
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    curl -fsSL https://packages.microsoft.com/config/opensuse/16/prod.repo -o /etc/zypp/repos.d/microsoft-prod.repo && \
    chown root:root /etc/zypp/repos.d/microsoft-prod.repo && \
    zypper -n --gpg-auto-import-keys ref && \
    zypper addrepo --name 'Azure CLI' \
      https://packages.microsoft.com/yumrepos/azure-cli azure-cli && \
    zypper -n --gpg-auto-import-keys refresh azure-cli

## Set up the official GitHub CLI RPM repository for the `gh` package.
## NOTE: This is the GitHub-maintained, GPG-signed repo (the same one used
## for openSUSE/SUSE in the official docs), keeping `gh` on the same
## auditable "signed repo baked at build time" footing as the rest of the
## toolchain rather than relying on a community-packaged build.
## See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#opensusesuse-linux-zypper
RUN zypper -n addrepo https://cli.github.com/packages/rpm/gh-cli.repo && \
    zypper -n --gpg-auto-import-keys ref

## Install base developer toolchains.
RUN zypper -n in --no-recommends \
      sudo \
      icu \
      patterns-devel-base-devel_basis \
      glibc \
      libX11-6 \
      libX11-xcb1 \
      xorg-x11-fonts \
      mozilla-nspr \
      mozilla-nss \
      libatk-1_0-0 \
      libatk-bridge-2_0-0 \
      libcups2 \
      libdrm2 \
      libgbm1 \
      libxkbcommon0 \
      libasound2 \
      libatspi0 \
      libXcomposite1 \
      libXdamage1 \
      libXfixes3 \
      libXrandr2 \
      libpango-1_0-0 \
      libcairo2 \
      openssh \
      gnome-keyring \
      ncdu \
      btop \
      gpg2 \
      pinentry \
      fish \
      tmux \
      fzf \
      fzf-fish-integration \
      ripgrep \
      ripgrep-fish-completion \
      jq \
      fd \
      fd-fish-completion \
      file \
      gawk \
      7zip \
      ffmpeg \
      poppler-tools \
      zoxide \
      yazi \
      yazi-fish-completion \
      git \
      lazygit \
      neovim \
      fnm \
      sops \
      gh \
      sqlite3 \
      dotnet-sdk-10.0 \
      python313 \
      azure-cli \
      luajit \
      acl \
      docker \
      docker-buildx \
      docker-compose \
    && zypper -n clean -a

RUN useradd -m -s /usr/bin/fish "$USERNAME"

## Create the docker group for Docker-outside-of-Docker and grant the developer
## user access; the runtime helper (see docker-socket-init.sh) re-applies it at
## devcontainer create & start, preferring this group for socket GID alignment
## and using an ACL when the socket is owned by GID 0.
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

## Run the Docker-outside-of-Docker socket access helper and allow the developer
## user to run it without a password (mirrors the passwd-bootstrap NOPASSWD rule).
## NOTE: acl is required by the helper for GID-0 sockets (macOS Docker
## Desktop/OrbStack & rootless Podman), docker-buildx is the CLI's buildx plugin
## (only the host daemon runs in the container; the daemon is socket-mounted).
## See: Shared/docker-socket-init.sh
COPY Shared/docker-socket-init.sh /usr/local/bin/docker-socket-init.sh
RUN chmod 0755 /usr/local/bin/docker-socket-init.sh && \
    chown root:root /usr/local/bin/docker-socket-init.sh && \
    printf '%s\n' "$USERNAME ALL=(root) NOPASSWD: /usr/local/bin/docker-socket-init.sh" > /etc/sudoers.d/12-docker-socket-init && \
    chmod 0440 /etc/sudoers.d/12-docker-socket-init

## Pre-create the targets of the named volumes mounted by the devcontainer.json
## template, including GCM's credential store.
## NOTE: Docker seeds a fresh named volume from the image path, so a missing path
## would yield a root-owned volume the user cannot write to - GCM in particular
## refuses to widen permissions on an existing store.
RUN mkdir -p \
      /home/$USERNAME/.cache \
      /home/$USERNAME/.local/share/fish \
      /home/$USERNAME/.claude \
      /home/$USERNAME/.config/gh \
      /home/$USERNAME/.azure \
      /home/$USERNAME/.gcm \
      /home/$USERNAME/.nuget/packages \
      /home/$USERNAME/.npm && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# Set tmux directory & permissions
RUN mkdir -p /run/tmux && chmod 1777 /run/tmux

## Set up system-wide shell defaults.
## NOTE: These live in /etc (fish conf.d & functions, /etc/bash.bashrc.local) rather than
## the user's home, so ~/.config & ~/.bashrc stay free for personal dotfiles following
## the XDG Base Directory spec. Dotfiles can override all of it: ~/.config/fish/config.fish
## & ~/.bashrc run afterwards, & ~/.config/fish/functions takes precedence over
## /etc/fish/functions.
COPY OpenSUSE/Leap/cfg/fish/conf.d/ /etc/fish/conf.d/
COPY Shared/fish/functions/ /etc/fish/functions/
COPY OpenSUSE/Shared/bash.bashrc.local /etc/bash.bashrc.local

## Environment variables.
## NOTE: This is the single source of truth for static environment variables. ENV is
## inherited by every process (VS Code terminals, tasks, debuggers, docker exec), so
## the shell configs above only hold what must be evaluated per shell at runtime.
## Projects can override any of these via remoteEnv/containerEnv in devcontainer.json,
## & dotfiles via ~/.config/fish/config.fish or ~/.bashrc.
ENV SHELL=/usr/bin/fish \
    FNM_DIR=/home/${USERNAME}/.local/share/fnm \
    EDITOR=nvim \
    VISUAL=nvim \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    XDG_STATE_HOME=/home/${USERNAME}/.local/state \
    XDG_CACHE_HOME=/home/${USERNAME}/.cache \
    DOTNET_CLI_TELEMETRY_OPTOUT=true \
    CLAUDE_CONFIG_DIR=/home/${USERNAME}/.claude \
    SSL_CERT_DIR=/home/${USERNAME}/.aspnet/dev-certs/trust:/etc/ssl/certs \
    PATH=/home/${USERNAME}/.dotnet/tools:/home/${USERNAME}/.local/bin:${PATH}

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
RUN fish -lc 'dotnet tool install -g dotnet-ef && dotnet tool install -g dotnet-outdated-tool && dotnet tool install -g gitversion.tool && dotnet tool install -g fallout.globaltool && dotnet tool install -g ilspycmd && dotnet tool install -g easydotnet && dotnet tool install -g git-credential-manager'

CMD ["/usr/bin/fish"]
