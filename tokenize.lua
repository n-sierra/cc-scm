function tokenize(str)
  local pos, v, len, i
  local tokens = {}

  pos = 1
  len = string.len(str)
  i = 1

  pos = skip_ws(str, pos)

  while pos <= len do
    pos, v = nextToken(str, pos)
    if not v then
      error("cannot recognize token")
    end
    pos = skip_ws(str, pos)
    tokens[i] = v
    i = i + 1
  end

  tokens["num"] = i - 1

  return tokens
end

function skip_ws(str, pos)
  -- white space
  pos, _ = skip(str, "^%s*", pos)

  -- comment
  pos, _ = skip(str, "^;%a*", pos)

  return pos
end

function nextToken(str, pos)
  local v

  --
  v = nil
  pos, v = skip(str, "^(%()", pos)
  if v then return pos, {type = "("} end
  pos, v = skip(str, "^(%))", pos)
  if v then return pos, {type = ")"} end
  pos, v = skip(str, "^(#%()", pos)
  if v then return pos, {type = "#("} end
  pos, v = skip(str, "^(')", pos)
  if v then return pos, {type = "'"} end
  pos, v = skip(str, "^(%.)", pos)
  if v then return pos, {type = "."} end

  -- identifier
  pos, v = skip(str, "^([a-zA-Z!%$%%&*/:<=>%?%^_~][a-zA-Z!%$%%&*/:<=>%?%^_~%+%-0-9%.@]*)", pos)
  if v then return pos, {type = "id", value = v} end

  -- number
  pos, v = skip(str, "^([%+%-]?%d+)", pos)
  if v then return pos, {type = "number", value= tonumber(v)} end

  -- identifier 2
  pos, v = skip(str, "^([%+%-])", pos)
  if v then return pos, {type = "id", value = v} end

  -- character

  -- string
  pos, v = skip(str, "^(\")", pos)
  if v then return skip_string(str, pos) end

  -- boolean
  pos, v = skip(str, "^(%#t)", pos)
  if v then return pos, {type = "boolean", value = "t"} end
  pos, v = skip(str, "^(%#f)", pos)
  if v then return pos, {type = "boolean", value = "f"} end

  return pos, nil
end

function skip(str, pattern, pos)
  local p, q, v
  p, q, v = string.find(str, pattern, pos)
  if p then
    return q+1, v
  end
  return pos, nil
end

function skip_string(str, pos)
  local ret, v

  ret = ""
  while true do
    if str:len() < pos then
      error("cant find \" after " .. str:sub(pos-1, pos-1))
    elseif str:sub(pos, pos+1)  == "\\\\" then
      ret = ret .. "\\"
      pos = pos + 2
    elseif str:sub(pos, pos+1)  == "\\n" then
      ret = ret .. "\n"
      pos = pos + 2
    elseif str:sub(pos, pos+1)  == "\\\"" then
      ret = ret .. "\""
      pos = pos + 2
    elseif str:sub(pos, pos)  == "\\" then
      if pos < str:len() then
        ret = ret .. str:sub(pos+1, pos+1)
        pos = pos + 2
      else
        error("cant find \" after " .. str:sub(pos,pos))
      end
    elseif str:sub(pos, pos)  == "\"" then
      pos = pos + 1
      return pos, {type = "string", value = ret}
    else
      ret = ret .. str:sub(pos, pos)
      pos = pos + 1
    end
  end
end

