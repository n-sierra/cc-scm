require("parse")
require("tokenize")
require("eval")
require("global_env")
require("utils")

function eval_str(str, env)
  local tokens, data, ans_data, pos
  tokens = tokenize(str)
  if tokens["num"] == 0 then
    return nil
  end

  pos = 1
  while pos < tokens["num"] + 1 do
    data, pos = parse(tokens, pos)
    ans_data = eval(data, env)
  end

  return ans_data
end

io.write("LUASCHEME INTERPRETER\n")

env = make_global_env()
pcall(eval_str, "(load \"init.scm\")", env)

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
