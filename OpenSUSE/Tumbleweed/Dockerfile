# ---------------------------------------------------------------------------------------
# OpenSUSE Tumbleweed Devcontainer Image
# ---------------------------------------------------------------------------------------
# Description : General-purpose devcontainer image tailored for .NET/NodeJS ecosystems
# Author      : Vasil Kotsev
# Updated     : 2026-02-12
# ---------------------------------------------------------------------------------------
FROM opensuse/tumbleweed:latest

ARG USERNAME=developer

## Refresh software repositories & install pre-requisites for
## SSL certificate management.
## NOTE: By default OpenSUSE-Tumbleweed comes with these packages,
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
    zypper -n --gpg-auto-import-keys ref

## Set up the official GitHub CLI RPM repository for the 'gh' package.
## NOTE: This is the GitHub-maintained, GPG-signed repo (the same one used
## for openSUSE/SUSE in the official docs), keeping 'gh' on the same
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
      python314 \
      azure-cli \
      luajit \
      docker \
      docker-compose \
    && zypper -n clean -a

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
## passwd-bootstrap NOPASSWD rule). See: OpenSUSE/Shared/cfg/docker-socket-init.sh
COPY OpenSUSE/Shared/cfg/docker-socket-init.sh /usr/local/bin/docker-socket-init.sh
RUN chmod 0755 /usr/local/bin/docker-socket-init.sh && \
    chown root:root /usr/local/bin/docker-socket-init.sh && \
    printf '%s\n' "$USERNAME ALL=(root) NOPASSWD: /usr/local/bin/docker-socket-init.sh" > /etc/sudoers.d/12-docker-socket-init && \
    chmod 0440 /etc/sudoers.d/12-docker-socket-init

## Set up sensible defaults for the fish terminal.
RUN mkdir -p /home/$USERNAME/.config/fish
COPY OpenSUSE/Tumbleweed/cfg/config.fish /home/$USERNAME/.config/fish/config.fish
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

## Environment variables.
## NOTE: These are primarily configured in OpenSUSE/Tumbleweed/cfg/config.fish,
## and are duplicated here as a fallback for non-fish shells.
ENV SHELL=/usr/bin/fish \
    FNM_DIR=/home/${USERNAME}/.local/share/fnm \
    EDITOR=nvim \
    VISUAL=nvim \
    DOTNET_CLI_TELEMETRY_OPTOUT=true \
    SSL_CERT_DIR=/home/${USERNAME}/.aspnet/dev-certs/trust:/etc/ssl/certs \
    PATH=/home/${USERNAME}/.dotnet/tools:/home/${USERNAME}/.local/bin:${PATH}

## Set up fnm fallback for bash.
COPY OpenSUSE/Shared/.bashrc /home/$USERNAME/.bashrc
RUN chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

USER $USERNAME

## Set up NodeJS (Latest LTS).
RUN fish -lc 'fnm install --lts; fnm default lts-latest'

## Set up AI CLI Harnesses & additional CLI tools as global NodeJS packages.
RUN fish -lc 'fnm exec --using lts-latest npm install -g corepack@ latest opencode-ai @anthropic-ai/claude-code tree-sitter-cli'

## Setup pnpm
RUN fish -lc 'fnm exec --using lts-latest corepack enable pnpm'

## Trust the ASP.NET Core Development SSL certificate.
RUN fish -lc 'dotnet dev-certs https -t'

## Provision global dotnet tools
RUN fish -lc 'dotnet tool install -g dotnet-ef && dotnet tool install -g dotnet-outdated-tool && dotnet tool install -g gitversion.tool && dotnet tool install -g nuke.globaltool && dotnet tool install -g ilspycmd && dotnet tool install -g easydotnet'

CMD ["/usr/bin/fish"]
