release 0.1

Bugs:
+ annoying automatic logout / session drops
- sluggish network syndrome - connections stay in (pending) state, WTF????
- editor do not loose edits on reload!!!
- console title does not change right
+ console "stop" is broken (when used twice)
- opening /proc/filesystems in editor crashes server
- renaming files no longer works
- refresh browser when returning from shell / find
- find: progressive display of results
- New Folder and Upload must select appropriate objects
- response and busy indicators still missing all over the place
- block input in navigationcontroler when animating
- doubleclick on icon when renaming should not open it
- doubleclick on toolbar buttons should not fire twice
+ bizzare multiple SET INFO stuff when opening a console
- browser broken on iPad 1 (iOS 5.1)
- last icon in browser is broken

Packaging:
- package compliant with node.js
- make install / GNU Coding Standards: Standard Targets
- github -> installer for dependancies
- tarball
-- certificates
- check for passwords, etc
- debian stuff
- raspbian stuff
- ubuntu stuff
-- fix npm crufty stuff
- vendor stuff (jquery at al)
- systemd stuff

Netty:
+ implement

Nodex:
+ implement "nodex" shell command
x login must fail if user != uid
x persistent sessions cookie foo
+ autoconfigure port
+ https

Shell:
+ can't upload big files 
+ better error reporting
+ nothings is happening when uploading: upload busy screen
+ show info on double-click
+ about box
+ new folder
+ rename a file
+ upload multiple files
- simple search interface (via find)
- download selected file/folder

Console:
- "watch" command does not work
- "top" command does not work
- "yes" command, curiously does work
- "cd .." is confusing, go to proper folder
+ kill process
+ use proper directory
+ preserve directory history
+ delete cell
+ tabs missing

Filer:
+ move file between filesystems after upload (milci test)
- backup a file (when saving, etc...)
