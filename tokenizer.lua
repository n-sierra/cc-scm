require("utils")

function tokenizer(str)
  local pos, v, len, i
  local tokens = {}

  pos = 1
  len = string.len(str)
  i = 1

  while(pos <= len) do
    pos, v = nextToken(str, pos)
    if not v then
      error("cannot recognize token")
      return nil
    end
    tokens[i] = v
    i = i + 1
  end

  return tokens
end

function nextToken(str, pos)
  local v

  -- white space
  pos, _ = skip(str, "^%s*", pos)

  -- comment
  pos, _ = skip(str, "^;%a*", pos)

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
  pos, v = skip(str, "^([a-zA-Z!%$%%&*/:<=>%?%^_~%+%-][a-zA-Z!%$%%&*/:<=>%?%^_~%+%-0-9%.@]*)", pos)
  if v then return pos, {type = "id", value = v} end

  -- number
  pos, v = skip(str, "^([%+%-]?%d+)", pos)
  if v then return pos, {type = "number", value= tonumber(v)} end

  -- character

  -- string
  pos, v = skip(str, "^\"([^\"]*)\"", pos)
  if v then return pos, {type = "string", value = v} end

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

