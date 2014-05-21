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
    return tostring(data["value"])
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

env = make_global_env()

while true do
  io.write("> ")
  str = io.read()

  tokens = tokenizer(str)
  data = parser(tokens)
  ans_data = eval(data, env)

  io.write(data_to_string(ans_data))
  io.write("\n")
end
