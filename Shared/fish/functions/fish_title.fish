function fish_title
    # NOTE: Cached, since fish_title runs on every prompt.
    set -q __os_name; or set -g __os_name (__os_release NAME)
    echo -n -e "$__os_name"
end
