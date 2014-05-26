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
  elseif data["type"] == "lua-object" then
    return "#lua-obj<" .. tostring(data["value"]) .. ">"
  else
    return "#unknown"
  end
end

-- dump a table
function dump(t)
  dump_with_indent(t, 0)
end

function dump_with_indent(t, indent)
  local whites, i

  whites = ""
  for i = 1,indent do
    whites = " " .. whites
  end

  for k, v in pairs(t) do
    if(type(v) == "table") then
      print(whites .. tostring(k) .. " = " .. "<table>")
      dump_with_indent(v, indent+2)
    else
      print(whites .. tostring(k) .. " = " .. tostring(v))
    end
  end
end


