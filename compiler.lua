require("utils")

function eval(data, env)
  local left, ret

  if data["type"] == "cons" then
    left = eval(data["left"], env)
    ret = apply(left, data["right"], env)
  elseif data["type"] == "id" then
    ret = get_var(env, data["value"])
    if not ret then
      dump(env)
      error("undefined variable is refered: " .. data["value"])
    end
  elseif data["type"] == "number" then
    ret = data
  elseif data["type"] == "string" then
    ret = data
  elseif data["type"] == "closure" then
    ret = data
  elseif data["type"] == "closure_lua" then
    ret = data
  else
    error("error in eval")
  end

  return ret
end

function apply(proc, e, env)
  local ret
  local rights
  local env0, freevars, i, var

  -- (#closure e1 e2 ...)
  if proc["type"] == "closure" then
    -- eval elementss of e
    rights = eval_list(e, env)

    env0 = new_env(proc["env"])
    freevars = proc["freevars"]
    if freevars["num"] ~= rights["num"] then
      error("invalid number of args")
    end
    for i, var in ipairs(freevars) do
      put_var(env0, var, rights[i])
    end
    ret = eval(proc["e"], env0)
  -- lua function
  elseif proc["type"] == "closure_lua" then
    func = proc["func"]
    ret = func(e, env)
  else
    error("Non-proc is not apply-able")
  end

  return ret
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
