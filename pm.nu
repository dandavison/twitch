export def PM-CONFIG [] {
    {
        'PM_FZF_COLOR_THEME': 'light'
    }
}

export def PROJECTS-FILE [] { '~/.pm.yml' | path expand }
def LOG-FILE [] { '/tmp/pm.log' }
def DEBUG [] { true }

# type Window = {id: Int, name: String}

export def-env 'pm switch' [name?: string] { # -> Void
    let name = if ($name | is-empty) {
        pm select
    } else {
        $name
    }
    if not ($name | is-empty) {
        debug $'pm switch: got ($name)'
        let projects = (pm read-projects | pm bubble-up $name)
        $projects | pm write-projects
        let dir = (($projects | pm get $name).dir | path expand)
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

export def-env 'pm cd' [] {
    cd (pm read-projects | pm get (term current)).dir
}

export def 'pm list' [] { # -> List<String>
    pm read-projects | get name
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
      (pm read-projects | pm get (pm select)).dir
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

export def 'pm read-projects' [] { PROJECTS-FILE | path expand | open }

export def 'pm write-projects' [] { $in | to yaml | save --raw (PROJECTS-FILE) }

export def 'pm bubble-up' [name: string] {
    let projects = $in
    (($projects | where name != $name) | prepend ($projects | pm get $name))
}

def 'pm select' [] { # -> Option<String>
    let current = (term current)
    pm list | where $it != $current
        | str collect "\n"
        | ^fzf --layout reverse --height 50% --info hidden --prompt='  ' --border rounded --color (PM-CONFIG).PM_FZF_COLOR_THEME
        | str trim -r
}

export def 'pm get' [name: string] {
    $in | where name == $name | unwrap-only
}

def 'term switch' [name: string, dir: string] { # -> Void
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

export def 'term current' [] { # -> Window
    let id = (tmux display-message -p '#I' | str trim -r)
    term list | where id == $id
              | unwrap-only
              | get name
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
