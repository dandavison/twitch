`pm` (real name TBD) is a tool for working on multiple projects concurrently in [nushell](https://github.com/nushell/nushell).

The basic idea is that one project corresponds to one tmux window.
Within that window, the project may have multiple panes.
To focus on work in one of those panes, you use tmux's [zoom pane](https://github.com/tmux/tmux/wiki/Getting-Started#resizing-and-zooming-panes) feature to hide the other panes.

To switch to a different project, use `ctrl+space`.

Each project has a directory (often the root of a git repo).
You should not need to care about the absolute path to this directory: only about your current path _within_ that directory.
Therefore, your prompt will only show your path relative to the project root, and `cd` will take you to the project root (not to your home directory).
(If you need to know your absolute path location, use `pwd`).

Each project may need certain environment variables set, and other changes to the nushell environment.
Make these changes in a file named `.pm.nu` in the project root directory; this file will be loaded automatically as a nushell overlay.
