function fish_greeting
    set -l os_name (__os_release PRETTY_NAME)
    echo (set_color --bold blue)Vasil Kotsev\'s (set_color --bold green)$os_name(set_color normal) Devcontainer

    set -l passwd_status (passwd -S (whoami) 2>/dev/null)
    if string match -rq '^[^[:space:]]+[[:space:]]+(NP|L|LK)[[:space:]]' -- "$passwd_status"
        echo (set_color --bold yellow)Hint:(set_color normal) run (set_color --bold cyan)'sudo passwd $(whoami)'(set_color normal) once to enable password-based (set_color --bold red)sudo(set_color normal) for this user.
    end
end
