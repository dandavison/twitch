use /Users/dan/src/devenv/nushell/stdlib.nu *

export def PM-CONFIG [] {
    {
        'PM_FZF_COLOR_THEME': 'light'
    }
}

export def PROJECTS-FILE [] { '~/.pm.yml' | path expand }
def LOG-FILE [] { '/tmp/pm.log' }
def DEBUG [] { true }

# type Window = {id: Int, name: String}
# type Project = {name: String dir: String}

export def-env 'pm switch' [name?, cmd?: string] { # -> Void
    let name = if ($name | is-empty) {
        pm select
    } else {
        $name
    }
    if not ($name | is-empty) {
        let projects = (pm read-projects | pm bubble-up $name)
        $projects | pm write-projects
        let dir = (($projects | pm get $name).dir | path expand)
        if not ($dir | path exists) {
            mkdir $dir
        }
        term switch $name $dir $cmd
    }
}

export def 'pm edit-projects' [] { # -> Void
    edit (PROJECTS-FILE)
}

export def-env 'pm cd' [path?: string] {
    let path = if ($path | is-empty) {
        (pm current).dir 
    } else {
        $path
    }
    cd $path
}

export def 'pm current-name' [] { # -> Option<String>
    if ('PM_PROJECT_NAME' in $env) {
        $env.PM_PROJECT_NAME
    }
}

export def 'pm current' [] { # -> Option<Project>
    let name = (pm current-name)
    if not ($name | is-empty) {
        pm read-projects | pm get $name
    }
}

export def 'pm list' [] { # -> List<String>
    pm read-projects | get name
}

export def 'term clean' [] { # -> Void
    let active = (tmux display-message -p '#I')
    term list | get name | uniq -d | par-each { |window|
        term list | where name == $window | where id != $active | skip 1 | get id | par-each { |id|
            tmux kill-window -t $id
        }
    }
}

# -------------------------------------------------------------------------------------
#
# Private

export def 'pm read-projects' [] { PROJECTS-FILE | path expand | open }

export def 'pm write-projects' [] { $in | to yaml | save --force --raw (PROJECTS-FILE) }

export def 'pm bubble-up' [name: string] {
    let projects = $in
    (($projects | where name != $name) | prepend ($projects | pm get $name))
}

def 'pm select' [] { # -> Option<String>
    let name = (pm current-name)
    pm list | where (($name | is-empty) or $it != $name)
            | str join "\n"
            | ^fzf --layout reverse --exact --cycle --height 50% --info hidden --prompt='  ' --border rounded --color (PM-CONFIG).PM_FZF_COLOR_THEME
            | str trim -r
}

export def 'pm get' [name: string] {
    $in | where name == $name | unwrap-only
}

def 'term switch' [name: string, dir: string, cmd?: string] { # -> Void
    let window = (term get $name)
    let overlay_cmd = $'overlay use .pm.nu as ($name); let-env PM_PROJECT_NAME = "($name)"'
    let cmd = ([$overlay_cmd $cmd] | where { |it| not ($it | is-empty) }
                                   | str join '; ')
    if ($window | is-empty) {
        tmux new-window -n $name -c $dir $"nu --execute '($cmd)'"
    } else {
        tmux send-keys -t $name 'C-a' 'C-k' $cmd 'Enter'
        tmux select-window -t $window.id
    }
}

export def 'term list' [] { # -> List<Window>
    tmux-list-windows
}

def 'term delete' [name: string] { # -> Void
    tmux kill-window -t (term get $name).id
}

def 'term get' [name: string, --no-validate] { # -> Option<Window>
    let windows = (term list | where name == $name)
    if ($windows | is-empty) {
        null
    } else {
        if not $no_validate {
            if ($windows | length) > 1 {
                error make {msg: $"Duplicate tmux windows with name: '($name)'"}
            }
        }
        $windows.0
    }
}

def tmux-list-windows [] {  # -> List<Window>
    tmux list-windows -F '#I #W'
        | lines
        | split column ' ' id name
}


def debug [msg: string] {
    if DEBUG {
        let msg = $"($msg)\n"
        print $msg
        $msg | save --append (LOG-FILE)
    }
}
