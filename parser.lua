require("utils")

function parser(tokens, start)
  local data, pos

  if start == nil then
    pos = 1
  else
    pos = start
  end

  data, pos = parse_data(tokens, pos)

  if tokens["num"]+1 < pos then
    error("end of tokens is found before finishing parser")
--  elseif pos < tokens["num"]+1 then
--    error("parser finished before parsing all tokens")
  end

  -- return result of parsing and position where parser ended
  return data, pos
end

function parse_data(tokens, pos)
  local data, i

  if tokens[pos] == nil then
    error("end of tokens is found before finishing parser")
  elseif tokens[pos]["type"] == "(" then
    if tokens[pos+1]["type"] == ")" then
      data = {type = "null"}
      i = pos + 2
    else
      data, i = parse_list(tokens, pos+1)
    end
  elseif tokens[pos]["type"] == "'" then
    local left, right_left, right
    left = {type = "id", value = "quote"}
    right_left, i = parse_data(tokens, pos+1)
    right = {type = "cons", left = right_left, right = {type = "null"}}
    data =  {type = "cons", left = left, right = right}
  elseif tokens[pos]["type"] == "id" then
    data = tokens[pos]
    i = pos + 1
  elseif tokens[pos]["type"] == "number" then
    data = tokens[pos]
    i = pos + 1
  elseif tokens[pos]["type"] == "string" then
    data = tokens[pos]
    i = pos + 1
  elseif tokens[pos]["type"] == "boolean" then
    data = tokens[pos]
    i = pos + 1
  else
    error("unknown type is found at parsing: " .. tokens[pos]["type"])
  end

  return data, i
end

function parse_list(tokens, pos)
  local i, j
  local left, right

  left, i = parse_data(tokens, pos)

  if tokens[i] == nil then
    error("cant find ) or .")
  elseif tokens[i]["type"] == ")" then
    right = {type = "null"}
    j = i + 1
  elseif tokens[i]["type"] == "." then
    right, j = parse_data(tokens, i+1)
    if not(tokens[j] ~= nil and tokens[j]["type"] == ")") then
      error("cant find )")
    end
    j = j + 1
  else
    right, j = parse_list(tokens, i)
  end

  return {type = "cons", left = left, right = right}, j
end

