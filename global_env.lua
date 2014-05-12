function make_global_env()
  local env = new_env(nil)
  local funcs

  funcs = {
    quote     = gf_quote,
    ["if"]    = gf_if,
    ["set!"]  = gf_set_ex,
    begin     = gf_begin,
    lambda    = gf_lambda,
    define    = gf_define,
    ["+"]     = gf_plus,
  }

  for name, func in pairs(funcs) do
    put_var(env, name, {type = "closure_lua", func = func})
  end

  return env
end

-- (quote x) => x
function gf_quote(data, env)
  return data
end

-- (if e t f)
function gf_if(data, env)
  local tf, ret

  if data["type"] ~= "cons" or data["right"]["type"] ~= "cons" or data["right"]["right"]["type"] ~= "cons" then
    error("invalid args")
  end

  tf = eval(data["left"], env)
  if tf["type"] == "boolean" and tf["value"] == "f" then
    -- false
    ret = eval(data["right"]["right"]["left"], env)
  else
    -- true
    ret = eval(data["right"]["left"], env)
  end

  return ret
end

-- (set! x v)
function gf_set_ex(data, env)
  local ret

  if data["type"] ~= "cons" or data["right"]["type"] ~= "cons" then
    error("invalid args")
  end

  if data["left"]["type"] ~= "id" then
    error("first arg should be id")
  end

  ret = eval(data["right"]["left"], env)
  if update_var(env, data["left"]["value"], ret) == nil then
    error("this variable is undefined: " .. data["left"]["value"])
  end

  return ret
end

-- (begin e1 e2)
function gf_begin(data, env)
  local ret, rets

  if data["type"] ~= "cons" then
    error("invalid args")
  end

  rets = eval_list(data, env)
  ret = rets[rets["num"]]

  return ret
end

-- (lambda (x y) e1 e2)
-- freevars: x, y    e: (e1 e2)
function gf_lambda(data, env)
  local freevars, e, env0
  local rest, i

  if data["type"] ~= "cons" or data["right"]["type"] ~= "cons" then
    error("invalid args")
  end

  -- (x y) => {x y}
  freevars = {}
  rest = data["left"]
  i = 1
  while rest["type"] == "cons" do
    if rest["left"]["type"] ~= "id" then
      error("invalid args")
    end
    freevars[i] = rest["left"]["value"]
    rest = rest["right"]
    i = i + 1
  end
  freevars["num"] = i - 1

  e = data["right"]

  env0 = new_env(env)

  return {type = "closure", freevars = freevars, e = e, env = env0}
end

-- (define x e1 e2)
function gf_define(data, env)
  local ret, rets

  if data["type"] ~= "cons" or data["right"]["type"] ~= "cons" then
    error("invalid args")
  end

  if data["left"]["type"] ~= "id" then
    error("first arg should be id")
  end

  rets = eval_list(data["right"], env)
  ret = rets[rets["num"]]

  put_var(env, data["left"]["value"], ret)

  return data["left"]
end

-- (+ a b) => a+b
function gf_plus(e, env)
  local rights, a, ans, ret

  rights = eval_list(e, env)

  ans = 0
  for i, a in ipairs(rights) do
    if a["type"] ~= "number" then
      error("args should be number")
    end
    ans = ans + a["value"]
  end

  return {type = "number", value = ans}
end
