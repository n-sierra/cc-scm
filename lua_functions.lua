require("parser")
require("tokenizer")
require("compiler")

function get_lua_funcs()
  local lua_funcs = {
    ["lua-get-g"] = lf_lua_get_g,
    ["lua-object?"] = lf_lua_object_q,
    ["lua-call"] = lf_lua_call,
    ["lua-gettable"] = lf_lua_gettable,
    ["scm->lua"] = lf_scm_to_lua,
    ["lua->scm"] = lf_lua_to_scm,
  }

  return lua_funcs
end

-- (lua-get-g)
function lf_lua_get_g(e, env)
  return {type = "lua-object", value = _G}
end


-- (lua-object? obj)
function lf_lua_object_q(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "lua-object" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- (lua-call type tf) => ({type="boolean", value="t"} .())
function lf_lua_call(e, env)
  local rights, ans, i

  rights = eval_list(e, env)

  if rights["num"] < 1 then
    error("invalid args")
  end

  if not (rights[1]["type"] == "lua-object" and type(rights[1]["value"]) == "function") then
    error("first arg should be lua function")
  end

  i = 2
  args = {}
  while i <= rights["num"] do
    if rights[i]["type"] ~= "lua-object" then
      error("args should be lua-object")
    end
    args[i-1] = rights[i]["value"]
    i = i + 1
  end

  ret = {pcall(rights[1]["value"], unpack(args))}

  if not ret[1] then
    error("exeption arised: " .. ret[2])
  end

  return {type = "lua-object", value = {unpack(ret, 2)}}
end

-- (lua-gettable table key) => value
function lf_lua_gettable(e, env)
  local rights, ans, i, key, ret

  rights = eval_list(e, env)

  if rights["num"] ~= 2 then
    error("invalid args")
  end

  if not (rights[1]["type"] == "lua-object" and type(rights[1]["value"]) == "table") then
    error("first arg should be lua table")
  end

  if not (rights[2]["type"] == "lua-object") then
    error("second arg should be lua table")
  end

  key = rights[2]["value"]
  ret = rights[1]["value"][key]

  return {type = "lua-object", value = ret}
end

-- (scm->lua 100)
function lf_scm_to_lua(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 1) then
    error("invalid args")
  end

  if rights[1]["type"] == "number" or rights[1]["type"] == "string" then
    return {type = "lua-object", value = rights[1]["value"]}
  elseif rights[1]["type"] == "boolean" then
    if rights[1]["value"] == "t" then
      return {type = "lua-object", value = true}
    else
      return {type = "lua-object", value = false}
    end
  elseif rights[1]["type"] == "null" then
    return {type = "lua-object", value = nil}
  else
    error("cant convert this type into lua-object: " .. rights[1]["type"])
  end
end

-- (lua->scm lua100)
function lf_lua_to_scm(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 1 and rights[1]["type"] == "lua-object") then
    error("invalid args")
  end

  local obj = rights[1]["value"]

  if type(obj) == "nil" then
    return {type = "null"}
  elseif type(obj) == "number" then
    if obj < 0 then
      return {type = "number", value = math.ceil(obj)}
    else
      return {type = "number", value = math.floor(obj)}
    end
  elseif type(obj) == "string" then
    return {type = "string", value = obj}
  elseif type(obj) == "boolean" then
    if obj then
      return {type = "boolean", value = "t"}
    else
      return {type = "boolean", value = "f"}
    end
  else
    error("cant convert this type into scheme object: " .. type(obj))
  end
end
