import subprocess
from collections import namedtuple
from pathlib import Path
from typing import Any, Iterator, List, Optional

from twitch.config import ENV_FILE

Window = namedtuple("Window", ["id", "name"])


def switch(name: str, dir: Path, cmd: Optional[str]):
    window = get_window(name)
    if not window:
        with open(ENV_FILE, "w") as file:
            file.write(f"export TWITCH_PROJECT_NAME={name} TWITCH_PROJECT_DIR={dir}")
        # user shell config must source ENV_FILE
        tmux("new-window", "-n", name, "-c", str(dir))
    else:
        if cmd:
            tmux("send-keys", "-t", name, "C-a", "C-k", cmd, "Enter")
        tmux("select-window", "-t", window.id)


def get_window(name: str) -> Optional[Window]:
    return next((w for w in list_windows() if w.name == name), None)


def list_windows() -> Iterator[Window]:
    for line in tmux("list-windows", "-F", "#I #W").splitlines():
        yield Window(*line.split())


def tmux(*args: str) -> str:
    return subprocess.check_output(["tmux", *args]).decode("utf-8").strip()
