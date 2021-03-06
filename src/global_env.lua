require("basic_functions")
require("clos_functions")
require("lua_functions")

function make_global_env()
  local env = new_env(nil)
  local funcs

  funcs = {
    quote     = gf_quote,
    apply     = gf_apply,
    ["if"]    = gf_if,
    cond      = gf_cond,
    ["set!"]  = gf_set_ex,
    let       = gf_let,
    ["let*"]  = gf_let_as,
    letrec    = gf_letrec,
    ["do"]    = gf_do,
    begin     = gf_begin,
    lambda    = gf_lambda,
    define    = gf_define,
    ["and"]   = gf_and,
    ["or"]    = gf_or,
  }

  for name, func in pairs(funcs) do
    put_var(env, name, {type = "closure_lua", func = func})
  end

  for name, func in pairs(get_basic_funcs()) do
    put_var(env, name, {type = "closure_lua", func = func})
  end

  for name, func in pairs(get_clos_funcs()) do
    put_var(env, name, {type = "closure_lua", func = func})
  end

  for name, func in pairs(get_lua_funcs()) do
    put_var(env, name, {type = "closure_lua", func = func})
  end

  return env
end

-- (quote x) => x
function gf_quote(data, env)
  if not is_list(data, 1) then
    error("wrong number of args (required 1)")
  end

  return data["left"]
end

-- (apply cons '(a b)) => (cons a b) => (a . c)
function gf_apply(data, env)
  local args0, rest
  local args, i
  local list, proc, rights

  if not is_list(data, 2) then
    error("wrong number of args (required 2)")
  end

  proc = eval(data["left"], env)
  list = eval(data["right"]["left"], env)

  if not is_list(data, nil) then
    error("second arg should be list")
  end

  rest = list
  args0 = {}
  i = 1
  while rest["type"] == "cons" do
    args0[i] = rest["left"]
    rest = rest["right"]
    i = i + 1
  end
  n = i - 1

  args = {type = "null"}
  i = n
  while 1 <= i do
    args = make_cons(make_cons({type = "id", value = "quote"}, make_cons(args0[i], {type = "null"})), args)
    i = i - 1
  end

  return apply(proc, args, env)
end


-- (if e t f)
-- (if e t)
function gf_if(data, env)
  local tf

  if not is_list(data, function(x) return x==2 or x==3 end) then
    error("wrong number of args (required 2 or 3)")
  end

  tf = eval(data["left"], env)
  if tf["type"] == "boolean" and tf["value"] == "f" then
    -- false
    if is_list(data, 3) then
      return eval(data["right"]["right"]["left"], env)
    else
      -- undefined
      return {type = "id", value = "<undefined>"}
    end
  else
    -- true
    return eval(data["right"]["left"], env)
  end
end

-- (cond)
-- => <undefined>
-- (cond (test e1 e2) ...)
-- => (cond ...) if !test
--    (begin e1 e2) if test
-- (cond (test => e) ...)
-- => (cond ...) if !test
--    (e test) if test
-- (cond (else e1 e2) ...)
--    (begin e1 e2)
function gf_cond(data, env)
  local clause, tf

  if is_list(data, 0) then
    -- undefined
    return {type = "id", value = "<undefined>"}
  elseif not is_list(data, function(x) return x>=1 end) then
    error("wrong number of args (required >=1)")
  end

  clause = data["left"]
  if not is_list(clause, function(x) return x>=1 end) then
    error("wrong number of args in clause (required >=1)")
  end

  if clause["left"]["type"] == "id" and clause["left"]["value"] == "else" then
    -- (else ...)
    return gf_begin(clause["right"], env)
  end

  tf = eval(clause["left"], env)

  if tf["type"] == "boolean" and tf["value"] == "f" then
    -- false
    return gf_cond(data["right"], env)
  end

  -- true
  if is_list(clause, 3) and clause["right"]["left"]["type"] == "id" and clause["right"]["left"]["value"] == "=>" then
    -- (cond (test => e) ...) => (e test)
    local closure
    closure = eval(clause["right"]["right"]["left"], env)
    return apply(closure, make_cons(tf, {type = "null"}), env)
  else
    -- (cond (test e1 e2) ...) => (begin e1 e2)
    return gf_begin(clause["right"], env)
  end
end

-- (set! x v)
function gf_set_ex(data, env)
  local ret

  if not is_list(data, 2) then
    error("wrong number of args (required 2)")
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

-- (let ((x a) (y b)) e1 e2)
-- => ((lambda (x y) e1 e2) a b)
-- (let tag ((x a) (y b)) e1 e2)
-- => ((letrec ((tag (lambda (x y) e1 e2))) tag) a b)
function gf_let(data, env)
  local tag, rest, e, closure, xs, args
  local i, n, xs0, args0

  if is_list(data, function(x) return 1<=x end) and is_list(data["left"], nil) then
    tag = nil
    rest = data["left"]
    e = data["right"]
  elseif is_list(data, function(x) return 2<=x end) and data["left"]["type"] == "id" then
    tag = data["left"]
    rest = data["right"]["left"]
    e = data["right"]["right"]
  else
    error("invalid args")
  end

  xs0 = {}
  args0 = {}
  i = 1
  while rest["type"] == "cons" do
    local xa
    xa = rest["left"]
    if not is_list(xa, 2) then
      error("invalid args")
    end
    xs0[i] = xa["left"]
    args0[i] = xa["right"]["left"]
    rest = rest["right"]
    i = i + 1
  end
  n = i - 1

  xs = {type = "null"}
  args = {type = "null"}
  i = n
  while 0 < i do
    xs = make_cons(xs0[i], xs)
    args = make_cons(args0[i], args)
    i = i - 1
  end

  if tag == nil then
    closure = gf_lambda(make_cons(xs, e), env)
    return eval(make_cons(closure, args), env)
  else
    local a, letrec
    closure = make_cons({type = "id", value = "lambda"}, make_cons(xs, e))
    a = make_cons(make_cons(tag, make_cons(closure, {type = "null"})), {type = "null"})
    letrec = gf_letrec(make_cons(a, make_cons(tag, {type = "null"})), env)
    return apply(letrec, args, env)
  end
end

-- (let* ((x a) (y b)) e1 e2)
-- => (#closure>)
-- freevars: nil    restvar: nil    e: (e1 e2)    env: {x=a,y=b}
function gf_let_as(data, env)
  local rest, e, xs, args, env0, closure, freevars
  local i, n

  if not (is_list(data, function(x) return 1<=x end) and is_list(data["left"], nil)) then
    error("invalid args")
  end

  rest = data["left"]
  e = data["right"]
  freevars = {num = 0}
  env0 = new_env(env)
  closure = {type = "closure"}

  xs = {}
  args = {}
  i = 1
  while rest["type"] == "cons" do
    local xa
    xa = rest["left"]
    xs[i] = xa["left"]["value"]
    args[i] = xa["right"]["left"]
    rest = rest["right"]
    i = i + 1
  end
  n = i - 1

  -- update vars
  for i, x in ipairs(xs) do
    local a = eval(args[i], env0)
    put_var(env0, xs[i], a)
  end

  return apply({type = "closure", freevars = freevars, restvar = nil, e = e, env = env0}, {type = "null"}, env)
end

-- (letrec ((x a) (y b)) e1 e2)
-- => (#closure>)
-- freevars: nil    restvar: nil    e: (e1 e2)    env: {x=a,y=b}
function gf_letrec(data, env)
  local rest, e, xs, args, env0, closure, freevars
  local i, n

  if not (is_list(data, function(x) return 1<=x end) and is_list(data["left"], nil)) then
    error("invalid args")
  end

  rest = data["left"]
  e = data["right"]
  freevars = {num = 0}
  env0 = new_env(env)
  closure = {type = "closure"}

  xs = {}
  args = {}
  i = 1
  while rest["type"] == "cons" do
    xa = rest["left"]
    xs[i] = xa["left"]["value"]
    args[i] = xa["right"]["left"]
    rest = rest["right"]
    i = i + 1
  end
  n = i - 1

  -- put vars temporarily
  for i, x in ipairs(xs) do
    put_var(env0, xs[i], {type = "id", value = "<undefined>"})
  end
  -- update vars
  for i, x in ipairs(xs) do
    local a = eval(args[i], env0)
    put_var(env0, xs[i], a)
  end

  return apply({type = "closure", freevars = freevars, restvar = nil, e = e, env = env0}, {type = "null"}, env)
end

-- (do ((var1 init1 step1) (var2 init2 step2)) (test e1 e2) c1 c2)
-- => var1 <- init1, var2 <- init2
--    while(test == false) {
--      (begin c1 c2)
--      var1 <- step1, var2 <- step2
--    }
--    (begin e1 e2)
function gf_do(data, env)
  local env0, binds, test, e, c

  if not (is_list(data, function(x) return 2<=x end)
    and is_list(data["left"], nil)
    and is_list(data["right"]["left"], function(x) return 1<=x end)) then
    error("invalid args")
  end

  e = data["right"]["left"]["right"]
  c = data["right"]["right"]

  env0 = new_env(env)

  binds = data["left"]
  while binds["type"] == "cons" do
    local bind, v
    bind = binds["left"]
    if not (is_list(bind, 3) and bind["left"]["type"] == "id") then
      error("invalid args")
    end
    v = eval(bind["right"]["left"], env)
    put_var(env0, bind["left"]["value"], v)
    binds = binds["right"]
  end

  test = eval(data["right"]["left"]["left"], env0)
  while test["type"] == "boolean" and test["value"] == "f" do
    gf_begin(c, env0)
    binds = data["left"]
    while binds["type"] == "cons" do
      local bind, v
      bind = binds["left"]
      v = eval(bind["right"]["right"]["left"], env0)
      put_var(env0, bind["left"]["value"], v)
      binds = binds["right"]
    end
    test = eval(data["right"]["left"]["left"], env0)
  end

  return gf_begin(e, env0)
end

-- (begin e1 e2)
function gf_begin(data, env)
  local ret, rets

  if is_list(data, 0) then
    return {type = "id", value = "<undefined>"}
  elseif is_list(data, nil) then
    while data["type"] == "cons" do
      if data["right"]["type"] == "null" then
        -- tail recursion
        return eval(data["left"], env)
      end
      eval(data["left"], env)
      data = data["right"]
    end
  end

  -- non-list or unexpected condition
  error("invalid args")
end

-- (lambda (x y) e1 e2)
-- => freevars: x, y    restvar: nil  e: (e1 e2)
-- (lambda (x y . z) e1 e2)
-- => freevars: x, y    restvar: z    e: (e1 e2)
function gf_lambda(data, env)
  local freevars, restvar, e, env0
  local rest, i

  if not is_list(data, function(x) return 2<=x end) then
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

  if not is_list(data, function(x) return 2<=x end) then
    error("invalid args")
  end

  -- (define x e1 e2)
  if data["left"]["type"] == "id" then
    rets = eval_list(data["right"], env)
    ret = rets[rets["num"]]
    put_var(env, data["left"]["value"], ret)
    return data["left"]
  -- (define (f x y . z) e1 e2) => (define f (lambda (x y . z) e1 e2))
  elseif data["left"]["type"] == "cons" then
    local left, lambda
    left = data["left"]["left"]
    lambda = gf_lambda(make_cons(data["left"]["right"], data["right"]), env)
    ret = gf_define(make_cons(left, make_cons(lambda, {type = "null"})), env)
    return data["left"]["left"]
  else
    error("invalid first arg")
  end
end

-- (and t1 t2 t3)
function gf_and(data, env)
  local tf

  if not is_list(data, null) then
    error("invalid args")
  end

  tf = {type = "boolean", value = "t"}
  while data["type"] == "cons" do
    tf = eval(data["left"], env)
    if tf["type"] == "boolean" and tf["value"] == "f" then
      -- false
      return {type = "boolean", value = "f"}
    end
    data = data["right"]
  end

  return tf
end

-- (or t1 t2 t3)
-- (or) => #f
-- (or obj) => obj
function gf_or(data, env)
  if not is_list(data, nil) then
    error("invalid args")
  end

  while data["type"] == "cons" do
    if data["right"]["type"] == "null" then
      -- tail recursion
      return eval(data["left"], env)
    end

    local tf = eval(data["left"], env)
    if not (tf["type"] == "boolean" and tf["value"] == "f") then
      -- true
      return tf
    end
    data = data["right"]
  end

  return {type = "boolean", value = "f"}
end
