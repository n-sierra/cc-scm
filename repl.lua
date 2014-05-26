require("parse")
require("tokenize")
require("eval")
require("global_env")
require("utils")

io.write("LUASCHEME INTERPRETER\n")

env = make_global_env()

while true do
  local str, success, data

  io.write("scm> ")
  str = io.read()

  if str == nil then
    break
  end

  success, data = pcall(eval_str, str, env)

  if not success then
    io.write("[error] ")
    io.write(data)
    io.write("\n")
  elseif data then
    io.write(data_to_string(data))
    io.write("\n")
  else
    -- nothing
  end
end

io.write("\nBYE\n")
