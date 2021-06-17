package = "prog"
version = "1.0.0"
source = {
   url = "https://github.com/dalygbarron/prog"
}
description = {
   summary = "Project scaffolder along the lines of Yeoman",
   detailed = [[
   Creates skeleton projects using plugins to be useful for any type of
   project, and is not just for the web.
   ]],
   homepage = "https://github.com/dalygbarron/prog", 
   license = "GPL" 
}
dependencies = {
   "lua >= 5.4"
}

build = {
   type = "builtin",
   modules = {
      ["prog"] = "prog.lua"
   }
}
