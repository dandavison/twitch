# type Window = {id: Int, name: String}

export def PROJECTS-FILE [] { '~/.projects.yml' }

export def PROJECTS [] { PROJECTS-FILE | path expand | open }

# Open a file or directory in VSCode.
# With no input, select a project file.
export def edit [path?: string] { # -> Void
  let path = (if $path == null {
      (PROJECTS | get (p select)).dir
    } else {
      $path
    }
  )
  if (not ($path | is-empty)) {
    ^code $path
  }
}

alias vscode = edit

export def 'p edit-projects' [] { # -> Void
    edit (PROJECTS-FILE)
}

export def 'p list' [] { # -> List<String>
    PROJECTS | transpose name | get name
}

export def 'p select' [] { # -> String
    p list | fzf-cmd
}

export def-env 'p switch' [name?: string] { # -> Void
    let name = if ($name | is-empty) {
        p select
    } else {
        $name
    }
    term switch $name (PROJECTS | get $name).dir
}

export def 'p toggle-symlink' [] {
    let current_target = (
        ls -ld '~/.projects*'
            | where name =~ '.+/\.projects.yml'
            | get target
            | path basename
    ).0
    if $current_target == '.projects-real.yml' {
        ^ln -sf ~/.projects-tests.yml ~/.projects.yml
    } else if $current_target == '.projects-tests.yml' {
        ^ln -sf ~/.projects-real.yml ~/.projects.yml
    } else {
        error make {msg: 'Unexpected symlink target: ($current_target)'}
    }
    ls -ld ~/.projects* | where name =~ '.+/\.projects.yml' | select name target
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
