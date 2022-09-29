use pm.nu *
use test-utils.nu *

def 'test pm list' [] {
    assert_eq (pm list | sort) ['A' 'B']
}

def 'test pm switch' [] {
    log 'starting'
    let xfer_file = '/private/tmp/pm-test/xfer.txt'
    rm -f $xfer_file
    assert_eq ($xfer_file | path exists) false
    pm switch 'A'
    pm switch 'A' $'$env.PWD | save ($xfer_file)'
    log 'waiting'
    sleep 1sec
    wait-until { ($xfer_file | path exists) }
    log 'asserting'
    assert_eq (open $xfer_file) '/private/tmp/pm-test/A'
    log 'done'
    pm switch 'B'
    pm switch 'B' '$env.PWD | save /private/tmp/pm-test-xfer.txt'
    assert_eq (open $xfer_file) '/private/tmp/pm-test/B'
}

def 'test term list' [] {
    let windows = (term list)
    let expected = [{id: 0, name: 'pm-test'}]
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
let OUTPUT_DIR = '/tmp/pm-test'
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
