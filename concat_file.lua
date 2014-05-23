ifiles = {
  "tokenizer.lua",
  "parser.lua",
  "compiler.lua",
  "basic_functions.lua",
  "lua_functions.lua",
  "global_env.lua",
  "interpreter.lua",
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
