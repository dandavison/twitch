# type Window = {id: Int, name: String}

export def PROJECTS-FILE [] { '~/.pm.yml' }
def LOG-FILE [] { '/tmp/pm.log' }
def DEBUG [] { true }

export def PROJECTS [] { PROJECTS-FILE | path expand | open | sort }

export def-env 'pm switch' [name?: string] { # -> Void
    let name = if ($name | is-empty) {
        pm select
    } else {
        $name
    }
    if not ($name | is-empty) {
        debug $'pm switch: got ($name)'
        let dir = ((PROJECTS | get $name).dir | path expand)
        if not ($dir | path exists) {
            debug $'pm switch: creating dir: ($dir)'
            mkdir $dir
        }
        term switch $name $dir
    }
}

export def 'pm edit-projects' [] { # -> Void
    edit --zed (PROJECTS-FILE)
}

export def 'pm list' [] { # -> List<String>
    PROJECTS | transpose name | get name
}

export def 'term clean' [] { # -> Void
    let active = (tmux display-message -p '#I')
    term list | get name | uniq -d | par-each { |window|
        term list | where name == $window | where id != $active | skip 1 | get id | par-each { |id|
            debug $'tmux kill-window -t ($id)'
            tmux kill-window -t $id
        }
    }
}

# Open a file or directory in VSCode.
# With no input, select a project file.
export def edit [path?: string --zed] { # -> Void
  let path = (if $path == null {
      (PROJECTS | get (pm select)).dir
    } else {
      $path
    }
  )
  if (not ($path | is-empty)) {
    if $zed {
        ^zed $path
    } else {
        ^code $path
    }
  }
}

alias vscode = edit

# -------------------------------------------------------------------------------------
#
# Private

# let-env FZF_DEFAULT_OPTS = '--color=fg:#d0d0d0,bg:#121212,hl:#5f87af --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'

def 'pm select' [] { # -> Option<String>
    pm list
        | str collect "\n"
        | ^fzf --height='50%' --info=hidden --border=rounded --layout=reverse
        | str trim -r
}

def 'pm toggle-symlink' [] {
    let current_target = (
        ls -ld '~/.pm*'
            | where name =~ '.+/\.pm.yml'
            | get target
            | path basename
    ).0
    if $current_target == '.pm-real.yml' {
        ^ln -sf ~/.pm-tests.yml ~/.pm.yml
    } else if $current_target == '.pm-tests.yml' {
        ^ln -sf ~/.pm-real.yml ~/.pm.yml
    } else {
        error make {msg: 'Unexpected symlink target: ($current_target)'}
    }
    ls -ld ~/.pm* | where name =~ '.+/\.pm.yml' | select name target
}

def-env 'term switch' [name: string, dir: string] { # -> Void
    let window = (term get $name)
    let overlay_use_cmd = $'overlay use .pm.nu as ($name)'
    debug $'term switch: ($name) ($dir)'
    if ($window | is-empty) {
        debug $'term switch: to new window ($name)'
        tmux new-window -n $name -c $dir $"nu --execute '($overlay_use_cmd)'"
    } else {
        debug $'term switch: to existing window ($name)'
        tmux send-keys -t $name $overlay_use_cmd 'Enter'
        tmux select-window -t $window.id
    }
}

def 'term list' [] { # -> List<Window>
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
