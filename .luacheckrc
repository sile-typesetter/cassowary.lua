std = "min"
include_files = {
  "cassowary/*.lua",
  "spec/*.lua",
  "*.rockspec",
  ".busted",
  ".luacov",
  ".luacheckrc"
}
files["spec"] = {
  std = "+busted"
}
max_line_length = false
-- vim: ft=lua
