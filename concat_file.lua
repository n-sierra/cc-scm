ifiles = {
  "tokenize.lua",
  "parse.lua",
  "eval.lua",
  "basic_functions.lua",
  "lua_functions.lua",
  "global_env.lua",
  "utils.lua",
-- #if CC
  "cc_interpreter.lua",
-- #else
--  "interpreter.lua",
-- #end
}

ofile = "cc_scm"

ofh = io.open(ofile, "w+")

for i, ifile in ipairs(ifiles) do
  for line in io.lines(ifile) do
    if not string.find(line, "^require%(") then
      -- slip requires
      ofh:write(line, "\n")
    end
  end
end

ofh:close()

io.write("Done.\n")
