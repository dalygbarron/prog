# Prog
Prog is a Program Progenitor. In less wankery language it's like yeoman but
written in lua with less dependencies and it's not just aimed at web stuff.

It works by taking a plugin of your choice and using that to create files and
folders within a project folder. Plugins consist of a lua file that returns
a table containing information about where to create folders and what to put in
files. Although what is returned is just a table full of data, because you have
got a lua script from which to return this data, you can produce portions of it
programmatically if you are writing your own plugin and think it would be
useful.

## Installing plugins
Plugins can be in either /usr/local/prog/ or ~/.prog/ and can either be
a single lua file or a folder with the same name as the plugin containing a
file with the same name as the plugin (but with .lua extension). If you use
a folder then you can also include template files and assets and stuff there.

## Usage
```
 -h, --help shows help
 -I... (string) extra search directory for plugins
 <plugin> (string) Determines the type of project to generate.
 <folder> (string) The folder to create the project in (must be empty or not
                   currently existent).
```
