require("utils")

function parser(tokens)
  local data, pos

  data, pos = parse_data(tokens, 1)

  if tokens[pos] ~= nil then
    error("error at parsing")
  end

  return data
end

function parse_data(tokens, pos)
  local data, i

  if tokens[pos]["type"] == "(" then
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
    error("error at parsing")
  end

  return data, i
end

function parse_list(tokens, pos)
  local i, j
  local left, right

  left, i = parse_data(tokens, pos)

  if tokens[i]["type"] == ")" then
    right = {type = "null"}
    j = i + 1
  elseif tokens[i]["type"] == "." then
    right, j = parse_data(tokens, i+1)
    if tokens[j]["type"] ~= ")" then
      error("error at parsing")
    end
    j = j + 1
  else
    right, j = parse_list(tokens, i)
  end

  return {type = "cons", left = left, right = right}, j
end

