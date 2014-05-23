require("parser")
require("tokenizer")
require("compiler")
require("global_env")
require("utils")

function cons_to_string(left, right)
  local s1 = data_to_string(left)
  local s2 = data_to_string(right)
  return string.format("(%s . %s)", s1, s2)
end

function data_to_string(data)
  if data["type"] == "cons" then
    return cons_to_string(data["left"], data["right"])
  elseif data["type"] == "id" then
    return data["value"]
  elseif data["type"] == "number" then
    if data["value"] == 0 then
      -- -0 is equal to 0
      return "0"
    else
      return tostring(data["value"])
    end
  elseif data["type"] == "string" then
    return data["value"]
  elseif data["type"] == "boolean" then
    if data["value"] == "t" then
      return "#t"
    else
      return "#f"
    end
  elseif data["type"] == "null" then
    return "()"
  elseif data["type"] == "closure" then
    return "#closure"
  elseif data["type"] == "closure_lua" then
    return "#closure_lua"
  else
    return "#unknown"
  end
end

function eval_str(str, env)
  local tokens, data, ans_data
  tokens = tokenizer(str)
  if tokens["num"] == 0 then
    return nil
  end
  data = parser(tokens)
  ans_data = eval(data, env)
  return ans_data
end

io.write("LUASCHEME INTERPRETER\n")

env = make_global_env()

while true do
  local str, success, data

  io.write("> ")
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
