function make_global_env()
  local env = new_env(nil)

  put_var(env, "+", {type = "closure_lua", func = gf_plus})
  put_var(env, "lambda", {type = "closure_lua", func = gf_lambda})

  return env
end

-- (+ a b) => a+b
function gf_plus(e,  env)
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

-- (lambda (x y) e)
-- freevars: x, y    e: e
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

  e = data["right"]["left"]

  env0 = new_env(env)

  return {type = "closure", freevars = freevars, e = e, env = env0}
end
