rockspec_format = "1.0"
package = "cassowary"
version = "2.3.1-2"

source = {
   url = "git://github.com/sile-typesetter/cassowary.lua",
   tag = "v2.3.1",
   dir = "cassowary.lua"
}

description = {
   summary = "The cassowary constraint solver",
   detailed = [[This is a Lua port of the Cassowary constraint solving toolkit.
      It allows you to use Lua to solve algebraic equations and inequalities
      and find the values of unknown variables which satisfy those
      inequalities.]],
   license = "Apache 2",
   homepage = "https://github.com/sile-typesetter/cassowary.lua"
}

dependencies = {
   "lua >= 5.1",
   "penlight"
}

build = {
   type = "builtin",
   modules = {
      cassowary = "cassowary/init.lua"
   }
}
