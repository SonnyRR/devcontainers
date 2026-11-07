# ---------------------------------------------------------------------------------------
# Devcontainer defaults for fish (system-wide).
# ---------------------------------------------------------------------------------------
# Installed to /etc/fish/conf.d so ~/.config/fish stays free for personal dotfiles that
# follow the XDG Base Directory spec. Dotfiles can override anything set here:
#   - ~/.config/fish/config.fish runs after every conf.d snippet
#   - ~/.config/fish/functions takes precedence over /etc/fish/functions
# NOTE: Static environment variables (EDITOR, VISUAL, FNM_DIR, XDG_*, ...) are set once,
# as Dockerfile ENV, so every process inherits them & projects can override them via
# devcontainer.json. Only what has to be evaluated per shell at runtime lives here.
# ---------------------------------------------------------------------------------------
if status is-interactive
    # Switch the NodeJS version on cd, based on .nvmrc/.node-version files.
    fnm env --use-on-cd --shell fish | source

    # DooD: Podman cannot serve buildx's BuildKit drivers, so fall back to the
    # classic builder when the mounted socket belongs to Podman.
    if test -w /var/run/docker.sock; and not set -q DOCKER_BUILDKIT
        if curl -s --max-time 1 --unix-socket /var/run/docker.sock http://localhost/version 2>/dev/null | string match -q '*Podman Engine*'
            set -gx DOCKER_BUILDKIT 0
        end
    end
end
