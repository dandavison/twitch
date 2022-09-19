# type Window = {id: Int, name: String}

export def PROJECTS-FILE [] { '~/.pm.yml' }

export def PROJECTS [] { PROJECTS-FILE | path expand | open | sort }

# Open a file or directory in VSCode.
# With no input, select a project file.
export def edit [path?: string] { # -> Void
  let path = (if $path == null {
      (PROJECTS | get (pm select)).dir
    } else {
      $path
    }
  )
  if (not ($path | is-empty)) {
    ^code $path
  }
}

alias vscode = edit

export def 'pm edit-projects' [] { # -> Void
    edit (PROJECTS-FILE)
}

export def 'pm list' [] { # -> List<String>
    PROJECTS | transpose name | get name
}

# let-env FZF_DEFAULT_OPTS = '--color=fg:#d0d0d0,bg:#121212,hl:#5f87af --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'

export def 'pm select' [] { # -> Option<String>
    pm list
        | str collect "\n"
        | ^fzf --height=10 --info=hidden --border=rounded --layout=reverse
        | str trim -r
}

export def-env 'pm switch' [name?: string] { # -> Void
    let name = if ($name | is-empty) {
        pm select
    } else {
        $name
    }
    if not ($name | is-empty) {
        term switch $name (PROJECTS | get $name).dir
    }
}

export def 'pm toggle-symlink' [] {
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

export def-env 'term switch' [name: string, dir: string] { # -> Void
    let window = (term get $name)
    if ($window | is-empty) {
        tmux new-window -n $name -c $dir
    } else {
        tmux select-window -t $window.id
    }
    cd $dir
}

export def 'term list' [] { # -> List<Window>
    tmux-list-windows
}

export def 'term clean' [] { # -> Void
    term list | get name | uniq -d | par-each { |window|
        let active = (tmux display-message -p '#I')
        term list | where name == $window | where id != $active | skip 1 | get id | par-each { |id|
            print $'tmux kill-window -t ($id)'
            tmux kill-window -t $id
        }
    }
}

export def 'term delete' [name: string] { # -> Void
    tmux kill-window -t (term get $name).id
}

export def 'term get' [name: string, --no-validate] { # -> Option<Window>
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

export def tmux-list-windows [] {  # -> List<Window>
    tmux list-windows -F '#I #W'
        | lines
        | split column ' ' id name
}
