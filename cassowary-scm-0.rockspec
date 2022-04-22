rockspec_format = "3.0"
package = "cassowary"
version = "scm-0"

source = {
   url = "git://github.com/sile-typesetter/cassowary.lua",
   branch = "master"
}

description = {
   summary = "The cassowary constraint solver",
   detailed = [[This is a Lua port of the Cassowary constraint solving toolkit.
      It allows you to use Lua to solve algebraic equations and inequalities
      and find the values of unknown variables which satisfy those
      inequalities.]],
   license = "Apache 2",
   homepage = "https://github.com/sile-typesetter/cassowary.lua",
   issues_url = "https://github.com/sile-typesetter/cassowary.lua/issues"
}

dependencies = {
   "lua >= 5.1",
   "penlight >= 1.5.4"
}

build = {
   type = "builtin",
   modules = {
      cassowary = "cassowary/init.lua"
   }
}
