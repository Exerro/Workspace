# Workspace
Workspace management for ComputerCraft

### Description
Ever had a few different projects going on the same computer? Maybe you've got an OS that you want to keep partitioned, or a client and server being developed on the same computer with a shared API.
Workspace makes this easy to deal with. It allows you to work on multiple, separate projects at once on a single computer, by creating individual folders for projects, which you can open using `workspace open WorkspaceName`.
When you run a workspace, the filesystem is sandboxed, allowing your programs to run as they would normally, just with a different set of files to those in the computer's root.
It even launches the shell in the workspace, so the startup program and any settings you have are respected, and individual to that workspace!

### Usage
First of all, run `workspace init`. This will add auto-complete so you can tab through options using the shell's autocomplete feature. This is optional but really helps. This can be done in startup, just once.
After that, creating a workspace is very simple. Use `workspace create WorkspaceName`.
You might want to add a root folder or file to the workspace, using `workspace link add WorkspaceName LinkName /path`. After that, the folder or file named LinkName in the workspace will point to /path. This works the same for files too.
To open your workspace, use `workspace open WorkspaceName`. You can get back to the parent shell using `workspace close` in the running workspace. Note, you'll have to run `workspace init` again in the sub-shell to get completion, so maybe put it at the top of a startup file.
There's fairly detailed help in-game, as well as a full command list, just use `workspace help` for more info.

### Install
`pastebin get 5tuchQr2 workspace.lua` (https://pastebin.com/5tuchQr2)

You should be able to name the file anything.
Note, this was built using a WIP preprocessor I've developed ([Amend](https://github.com/Exerro/Amend)). Build instructions will come soon, but the compiled output is perfectly readable.
In addition, this has been tested on CCEmuX using the latest CC build (from the GitHub source). This should work on all recent(ish) versions of CC, however, although as some functionality has had to be copied (e.g. os.loadAPI) the functions will behave like the newer implementations.

### Screenies
![](http://i.imgur.com/I9Bocjs.png)
![](http://i.imgur.com/TBaa7QR.gif)
![](http://i.imgur.com/jAklXZT.png)
![](http://i.imgur.com/cUgq1Wj.png)

### Todo
* Implement --interactive flag
* Nice installer with option to move all files into a workspace and set up startup to `workspace init`
* Use @WorkspaceName in links to refer to other workspaces e.g. `link add server clientAPI.lua @client/api.lua`
* More config options for workspaces and the program/API itself e.g. run `workspace init` on startup
* Temporary sessions e.g. for testing a program in a blank environment
* Encrypted/compressed workspace directories
