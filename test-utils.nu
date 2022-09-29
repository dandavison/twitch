export def wait-until [cond: block, retry_interval: duration = 500ms, timeout: duration = 3sec] {
    if not (do $cond) {
        sleep $retry_interval
        if $timeout <= 0sec {
            false
        } else {
            wait-until $cond $retry_interval ($timeout - $retry_interval)
        }
    }
}
