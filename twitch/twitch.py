import os
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path
from typing import Iterable, Optional

import yaml

# TODO: why not `from twitch import config`
import twitch.config as config
import twitch.tmux as term


def twitch(name: Optional[str], cmd: Optional[str]):
    projects = Projects.read()
    if name is None:
        name = projects.select()
    if name:
        projects.move_to_end(name, False)
        projects.write()
        dir = projects.get_dir(name)
        dir.mkdir(parents=True, exist_ok=True)
        term.switch(name, dir, cmd)


class Projects(OrderedDict[str, Path]):
    @classmethod
    def read(cls) -> "Projects":
        with open(config.PROJECTS_FILE) as file:
            return cls((p["name"], p["dir"]) for p in yaml.safe_load(file))

    def write(self):
        with open(config.PROJECTS_FILE, "w") as file:
            file.write(
                yaml.dump(
                    [{"name": k, "dir": v} for k, v in self.items()], sort_keys=True
                )
            )

    def get_dir(self, project: str) -> Path:
        return Path(self[project]).expanduser()

    def select(self) -> str:
        names = self.keys()
        if name := os.getenv("TWITCH_PROJECT_NAME"):
            names = [n for n in names if n != name]
        return fzf(names)


def fzf(items: Iterable[str]) -> str:
    return (
        subprocess.check_output(
            [
                "fzf",
                "--layout",
                "reverse",
                "--exact",
                "--cycle",
                "--height",
                "50%",
                "--info",
                "hidden",
                "--prompt",
                "  ",
                "--border",
                "rounded",
                "--color",
                config.FZF_COLOR_THEME,
            ],
            input="\n".join(items).encode("utf-8"),
        )
        .decode("utf-8")
        .strip()
    )


def main():
    args = (sys.argv[1:] + [None, None])[:2]
    try:
        twitch(*args)
    except subprocess.CalledProcessError:
        pass
