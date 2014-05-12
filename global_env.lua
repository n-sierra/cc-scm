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
  if data["type"] ~= "cons" or data["right"]["type"] ~= "null" then
    error("invalid args")
  end

  return data["left"]
end

-- (if e t f)
function gf_if(data, env)
  local tf, ret

  if data["type"] ~= "cons" or data["right"]["type"] ~= "cons"
    or (data["right"]["right"]["type"] ~= "cons" and data["right"]["right"]["type"] ~= "null") then
    error("invalid args")
  end

  tf = eval(data["left"], env)
  if tf["type"] == "boolean" and tf["value"] == "f" then
    -- false
    if data["right"]["right"]["type"] == "cons" then
      ret = eval(data["right"]["right"]["left"], env)
    else
      -- undefined
      ret = {type = "null"}
    end
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
-- freevars: x, y    restvar: nil  e: (e1 e2)
-- (lambda (x y . z) e1 e2)
-- freevars: x, y    restvar: z    e: (e1 e2)
function gf_lambda(data, env)
  local freevars, restvar, e, env0
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

  if rest["type"] == "id" then
    restvar = rest["value"]
  elseif rest["type"] == "null" then
    restvar = nil
  else
    error("invalid args")
  end

  e = data["right"]

  env0 = new_env(env)

  return {type = "closure", freevars = freevars, restvar = restvar, e = e, env = env0}
end

-- (define x e1 e2)
-- (define (f x y . z) e1 e2) => (define f (lambda (x y . z) e1 e2))
function gf_define(data, env)
  local ret, rets

  if data["type"] ~= "cons" or data["right"]["type"] ~= "cons" then
    error("invalid args")
  end

  -- (define x e1 e2)
  if data["left"]["type"] == "id" then
    rets = eval_list(data["right"], env)
    ret = rets[rets["num"]]

    put_var(env, data["left"]["value"], ret)
  -- (define (f x y . z) e1 e2) => (define f (lambda (x y . z) e1 e2))
  elseif data["left"]["type"] == "cons" then
    local left, lambda
    left = data["left"]["left"]
    lambda = gf_lambda(make_cons(data["left"]["right"], data["right"]), env)
    ret = gf_define(make_cons(left, make_cons(lambda, {type = "null"})), env)
  else
    error("invalid first arg")
  end

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

function make_cons(left, right)
  return {type = "cons", left = left, right = right}
end
