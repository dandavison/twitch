use pm.nu *

def 'test pm list' [] {
    assert_eq (pm list | sort) ['A' 'B']
}

def 'test pm switch' [] {
    pm switch 'A'
    assert_eq_paths (pwd) (PROJECTS | get 'A').dir
    pm switch 'B'
    assert_eq_paths (pwd) (PROJECTS | get 'B').dir
}

def 'test term list' [] {
    # tmux new-window -n 'window-1'
    let windows = (term list)
    let expected = [{id: 0, name: 'pm-tests'}]
    log $windows
}

def assert_eq_paths [p: string, q: string] {
    assert_eq ($p | path expand | str trim -r) ($q | path expand | str trim -r)
}

def assert_eq [result, expected] {
    if $result != $expected {
        log '❌'
        error make {msg: $'❌ Expected ($expected) but got ($result)'}
    } else {
        true
    }
}

# TODO: How to capture `print` output
let OUTPUT_DIR = '/tmp/pm-tests'
let STDOUT_FILE = $'($OUTPUT_DIR)/stdout.txt'
def log [obj: string] {
    echo $"($obj)\n" | save --append $STDOUT_FILE
}

def run-tests [outfile: string] {
    test pm list
    log '✅ test pm list'

    test pm switch
    log '✅ test pm switch'
}


def main [outfile: string, errfile: string] {
    let err = do -c { run-tests $outfile }
    if not ($err | is-empty) {
       $err | to text | save ($errfile)
    }
}
