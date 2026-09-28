# ----------------------------------------------------------------------------------------
# Stacked Deck OpenSUSE Leap Devcontainer Image
# ----------------------------------------------------------------------------------------
# Description : OpenSUSE Leap based devcontainer image tailored for .NET/NodeJS ecosystems
# Author      : Vasil Kotsev
# Updated     : 2026-09-28
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
## NOTE: The GnuPG `pass` front-end is packaged as `password-store` on openSUSE
## (it is named `pass` in the Ubuntu image), but it provides the same `pass`
## binary - GCM's gpg credential store is `pass`-compatible and needs it to
## initialise the store.
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
      password-store \
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

# Set tmux directory & permissions
RUN mkdir -p /run/tmux && chmod 1777 /run/tmux

## Set up sensible defaults for the fish terminal.
RUN mkdir -p /home/$USERNAME/.config/fish
COPY OpenSUSE/Leap/cfg/config.fish /home/$USERNAME/.config/fish/config.fish
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

## Environment variables.
## NOTE: These are primarily configured in OpenSUSE/Leap/cfg/config.fish,
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
COPY OpenSUSE/Shared/.bashrc /home/$USERNAME/.bashrc
RUN chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

USER $USERNAME

## Set up NodeJS (Latest LTS).
RUN fish -lc 'fnm install --lts; fnm default lts-latest'

## Set up AI CLI Harnesses & additional CLI tools as global NodeJS packages.
## NOTE: OpenCode V2 is the scoped `@opencode/cli` package; the V1 line shipped
## under the unscoped name `opencode-ai`. A postinstall hook resolves the native
## `opencode` binary for the build platform out of the package's
## optionalDependencies (@opencode/cli-linux-x64 or -linux-arm64, with musl and
## AVX2-baseline variants), so the installed `opencode` is a self-contained
## native binary rather than a NodeJS shim. This is the documented V2 install
## path, so no curl/binary juggling is needed. See: https://opencode.ai/v2/docs/
RUN fish -lc 'fnm exec --using lts-latest npm install -g corepack@latest @opencode/cli @anthropic-ai/claude-code tree-sitter-cli'

## Setup pnpm
RUN fish -lc 'fnm exec --using lts-latest corepack enable pnpm'

## Trust the ASP.NET Core Development SSL certificate.
RUN fish -lc 'dotnet dev-certs https -t'

## Provision global dotnet tools
## NOTE: git-credential-manager is installed as a global .NET tool because that
## is the method the GCM project documents as preferred on Linux - it needs no
## per-distribution .rpm and no extra download step, and it lands in
## ~/.dotnet/tools which is already on PATH (see ENV above). That location is
## what /etc/gitconfig above points credential.helper at.
RUN fish -lc 'dotnet tool install -g dotnet-ef && dotnet tool install -g dotnet-outdated-tool && dotnet tool install -g gitversion.tool && dotnet tool install -g nuke.globaltool && dotnet tool install -g ilspycmd && dotnet tool install -g easydotnet && dotnet tool install -g git-credential-manager'

## Verify the baked-in Git Credential Manager wiring.
## NOTE: /etc/gitconfig hard-codes the tool's install path, so if the tool layout
## ever drifts the build must fail loudly here rather than silently degrading to
## a username/password prompt for every Git remote at runtime. `pass` is checked
## too because the gpg credential store cannot be initialised without it.
RUN set -eu; \
    helper="$(git config --system --get-all credential.helper | tail -n 1)"; \
    test -n "$helper" || { echo 'no system-wide credential.helper configured' >&2; exit 1; }; \
    test -x "$helper" || { echo "configured credential.helper '$helper' is not executable" >&2; exit 1; }; \
    command -v pass >/dev/null || { echo 'pass is missing from PATH' >&2; exit 1; }; \
    git-credential-manager --version

CMD ["/usr/bin/fish"]
