ifiles = {
  "tokenize.lua",
  "parse.lua",
  "eval.lua",
  "basic_functions.lua",
  "clos_functions.lua",
  "lua_functions.lua",
  "global_env.lua",
  "utils.lua",
-- #if custom-made for ComputerCraft
  "cc_repl.lua",
-- #else
--  "repl.lua",
-- #end
}

for i, ifile in ipairs(ifiles) do
  for line in io.lines(ifile) do
    if not string.find(line, "^require%(") then
      -- slip requires
      io.write(line, "\n")
    end
  end
end
