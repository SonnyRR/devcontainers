if status is-interactive

    function fish_greeting
        echo (set_color --bold blue)Vasil Kotsev\'s (set_color --bold E95420)Ubuntu 26.04(set_color normal) Devcontainer

        set -l passwd_status (passwd -S (whoami) 2>/dev/null)
        if string match -rq '^[^[:space:]]+[[:space:]]+(NP|L|LK)[[:space:]]' -- "$passwd_status"
            echo (set_color --bold yellow)Hint:(set_color normal) run (set_color --bold cyan)'sudo passwd $(whoami)'(set_color normal) once to enable password-based (set_color --bold red)sudo(set_color normal) for this user.
        end
    end

    fnm env --use-on-cd --shell fish | source

    function fish_title
        echo -n -e "Ubuntu LTS"
    end

    function cls
        clear
    end

end
