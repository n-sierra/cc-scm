function eval(data, env)
  local left, ret

  if data["type"] == "cons" then
    left = eval(data["left"], env)
    -- tail recursion
    return apply(left, data["right"], env)
  elseif data["type"] == "id" then
    ret =  get_var(env, data["value"])
    if not ret then
      error("undefined variable is refered: " .. data["value"])
    end
  elseif data["type"] == "number" then
    ret = data
  elseif data["type"] == "string" then
    ret = data
  elseif data["type"] == "boolean" then
    ret = data
  elseif data["type"] == "null" then
    ret = data
  elseif data["type"] == "closure" then
    ret = data
  elseif data["type"] == "closure_lua" then
    ret = data
  elseif data["type"] == "lua-object" then
    ret = data
  else
    error("unknown type is found in eval: " .. data["type"])
  end

  return ret
end

function apply(proc, e, env)
  local ret, rets
  local rights, rests
  local env0, freevars, restvar, i

  -- (#closure e1 e2 ...)
  if proc["type"] == "closure" then
    -- eval elementss of e
    rights = eval_list(e, env)

    env0 = new_env(proc["env"])
    freevars = proc["freevars"]
    restvar = proc["restvar"]
    if (restvar == nil and freevars["num"] ~= rights["num"])
      or (restvar ~= nil and freevars["num"] > rights["num"]) then
      error("wrong number of args "
        .. "(required " .. tostring(freevars["num"]) .. ", got " .. tostroing(rights["num"]))
    end

    -- put freevars into env0
    for i, var in ipairs(freevars) do
      put_var(env0, var, rights[i])
    end

    -- put restvar into env0
    if restvar ~= nil then
      i = rights["num"]
      rests = {type = "null"}
      while freevars["num"] < i do
        rests = {type = "cons", left = rights[i], right = rests}
        i = i - 1
      end
      put_var(env0, restvar, rests)
    end

    local rest = proc["e"]
    while rest["type"] == "cons" do
      if rest["right"]["type"] == "null" then
        -- tail recursion
        return eval(rest["left"], env0)
      end
      eval(rest["left"], env0)
      rest = rest["right"]
    end

    -- null
    return {type = "id", value = "<undefined>"}

  -- lua function
  elseif proc["type"] == "closure_lua" then
    func = proc["func"]
    return func(e, env)
  else
    error("Non-proc is not apply-able")
  end
end

function eval_list(e, env)
  local i = 1
  local rights = {}

  while e["type"] == "cons" do
    rights[i] = eval(e["left"], env)
    e = e["right"]
    i = i + 1
  end

  if e["type"] ~= "null" then
    error("arg should be a list")
  end

  rights["num"] = i - 1

  return rights
end

function new_env(below)
  return {below = below, vs = {}}
end

function get_var(env, name)
  while(env ~= nil) do
    if env["vs"][name] ~= nil then
      return env["vs"][name]
    end
    env = env["below"]
  end

  return nil
end

function put_var(env, name, data)
  env["vs"][name] = data
end

function update_var(env, name, data)
  while(env ~= nil) do
    if env["vs"][name] ~= nil then
      env["vs"][name] = data
      return name
    end
    env = env["below"]
  end

  return nil
end

function get_global_env(env)
  while(env["below"] ~= nil) do
    env = env["below"]
  end

  return env
end
