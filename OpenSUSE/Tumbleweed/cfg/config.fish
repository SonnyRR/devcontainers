if status is-interactive

    function fish_greeting
        echo (set_color --bold blue)Vasil Kotsev\'s (set_color --bold green)OpenSUSE Tumbleweed(set_color --reset) Devcontainer

        set -l passwd_status (passwd -S (whoami) 2>/dev/null)
        if string match -rq '^[^[:space:]]+[[:space:]]+(NP|L|LK)[[:space:]]' -- "$passwd_status"
            echo (set_color --bold yellow)Hint:(set_color --reset) run (set_color --bold cyan)'sudo passwd $(whoami)'(set_color --reset) once to enable password-based (set_color --bold red)sudo(set_color --reset) for this user.
        end
    end

   fnm env --use-on-cd --shell fish | source

    function fish_title
        echo -n -e "OpenSUSE Tumbleweed"
    end

    function cls
        clear
    end

end
