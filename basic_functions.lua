require("parse")
require("tokenize")
require("eval")

function get_basic_funcs()
  local basic_funcs = {
    -- number
    ["number?"] = bf_number_q,
    ["+"]     = bf_plus,
    ["-"]     = bf_minus,
    ["*"]     = bf_times,
    ["/"]     = bf_div,
    ["="]     = bf_eq,
    ["<"]     = bf_lt,
    ["<="]    = bf_le,
    [">"]     = bf_gt,
    [">="]    = bf_ge,
    -- list
    ["null?"] = bf_null_q,
    ["pair?"] = bf_pair_q,
    ["list?"] = bf_list_q,
    ["symbol?"] = bf_symbol_q,
    ["car"]   = bf_car,
    ["cdr"]   = bf_cdr,
    ["cons"]  = bf_cons,
    ["list"]  = bf_list,
    ["length"] = bf_length,
    ["memq"]  = bf_memq,
    ["last"]  = bf_last,
    ["append"] = bf_append,
    ["set-car!"] = bf_set_car_ex,
    ["set-cdr!"] = bf_set_cdr_ex,
    -- boolean
    ["boolean?"] = bf_boolean_q,
    ["not"]   = bf_not,
    -- string
    ["string?"] = bf_string_q,
    ["string-append"] = bf_string_append,
    ["string->symbol"] = bf_string_to_symbol,
    ["symbol->string"] = bf_symbol_to_string,
    ["string->number"] = bf_string_to_number,
    ["number->string"] = bf_number_to_string,
    -- procedure
    ["procedure?"] = bf_procedure_q,
    -- eq
    ["eq?"]   = bf_eq_q,
    ["neq?"]  = bf_neq_q,
    ["equal?"] = bf_equal_q,
    -- meta
    ["load"]  = bf_load,
    ["error"]  = bf_error,
  }

  return basic_funcs
end

-- (number? n)
function bf_number_q(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "number" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- (+ a) => a
-- (+ a b c) => a + b + c
function bf_plus(e, env)
  local rights, ans

  rights = eval_list(e, env)

  ans = fold_ary(rights,
    function(a, x)
      if x["type"] ~= "number" then
        error("args should be number")
      end
      return a + x["value"]
    end, 0)

  return {type = "number", value = ans}
end

-- (- a) => -a
-- (- a b c) => a - b - c
function bf_minus(e, env)
  local rights, ans

  rights = eval_list(e, env)

  if rights["num"] < 1 then
    error("invalid args")
  elseif rights["num"] == 1 then
    ans = - rights[1]["value"]
  else
    ans = fold_ary(rights,
      function(a, x)
        if x["type"] ~= "number" then
          error("args should be number")
        end
        if a == nil then
          return x["value"]
        else
          return a-x["value"]
        end
      end, nil)
  end

  return {type = "number", value = ans}
end

-- (* a) => a
-- (* a b c) => a * b * c
function bf_times(e, env)
  local rights, ans

  rights = eval_list(e, env)

  ans = fold_ary(rights,
    function(a, x)
      if x["type"] ~= "number" then
        error("args should be number")
      end
      return a * x["value"]
    end, 1)

  return {type = "number", value = ans}
end

-- (/ a) => 1 / a
-- (/ a b c) => a / b / c
function bf_div(e, env)
  local rights, ans

  rights = eval_list(e, env)

  if rights["num"] < 1 then
    error("invalid args")
  elseif rights["num"] == 1 then
    if rights[1]["value"] == 0 then
      error("0 divides something")
    end
    ans = 1 / rights[1]["value"]
    if ans < 0 then
      ans = math.ceil(ans)
    else
      ans = math.floor(ans)
    end
  else
    ans = fold_ary(rights,
      function(a, x)
        if x["type"] ~= "number" then
          error("args should be number")
        elseif a == nil then
          return x["value"]
        elseif x["value"] == 0 then
          error("0 divides something")
        else
          local ans = a / x["value"]
          if ans < 0 then
            ans = math.ceil(ans)
          else
            ans = math.floor(ans)
          end
          return ans
        end
      end, nil)
  end

  return {type = "number", value = ans}
end

-- sub function for create function(e, env)
function create_number_relation_function(r)
  return function(e, env)
    local rights, ans

    rights = eval_list(e, env)

    if rights["num"] < 2 then
      error("invalid args")
    end

    ans = fold_ary(rights,
      function(a, x)
        if x["type"] ~= "number" then
          error("args should be number")
        end
        if a[2] == nil then
          return {true, x["value"]}
        elseif a[1] == false then
          return {false, x["value"]}
        else
          return {r(a[2],x["value"]), x["value"]}
        end
      end, {true, nil})

    if ans[1] then
      ans = "t"
    else
      ans = "f"
    end

    return {type = "boolean", value = ans}
  end
end

-- (= a b) => a = b
-- (= a b c) => a = b and b = c
function bf_eq(e, env)
  local f = create_number_relation_function(function (x, y) return x == y end)
  return f(e, env)
end

-- (< a b) => a < b
-- (< a b c) => a < b and b < c
function bf_lt(e, env)
  local f = create_number_relation_function(function (x, y) return x < y end)
  return f(e, env)
end

-- (<= a b) => a <= b
-- (<= a b c) => a <= b and b <= c
function bf_le(e, env)
  local f = create_number_relation_function(function (x, y) return x <= y end)
  return f(e, env)
end

-- (> a b) => a > b
-- (> a b c) => a > b and b > c
function bf_gt(e, env)
  local f = create_number_relation_function(function (x, y) return x > y end)
  return f(e, env)
end

-- (>= a b) => a >= b
-- (>= a b c) => a >= b and b >= c
function bf_ge(e, env)
  local f = create_number_relation_function(function (x, y) return x >= y end)
  return f(e, env)
end

-- (null? '()) => #t
function bf_null_q(e, env)
  local ans
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "null" then
    ans = "t"
  else
    ans = "f"
  end

  return {type = "boolean", value = ans}
end

-- (pair? '()) => #f
-- (pair? '(1 . 2)) => #t
function bf_pair_q(e, env)
  local ans
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "cons" then
    ans = "t"
  else
    ans = "f"
  end

  return {type = "boolean", value = ans}
end

-- (list? '()) => #t
-- (list? '(1 . 2)) => #f
-- (list? '(1 2)) => #t
function bf_list_q(e, env)
  local ans
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if is_list(rights[1], nil) then
    ans = "t"
  else
    ans = "f"
  end

  return {type = "boolean", value = ans}
end

-- (symbol? '()) => #f
-- (symbol? 'a) => #t
-- (symbol? "foo") => #f
function bf_symbol_q(e, env)
  local ans
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "id" then
    ans = "t"
  else
    ans = "f"
  end

  return {type = "boolean", value = ans}
end

-- (car '(a b)) => a
function bf_car(e, env)
  local rights = eval_list(e, env)

  if not (rights["num"] == 1 and rights[1]["type"] == "cons") then
    error("invalid args")
  end

  return rights[1]["left"]
end

-- (cdr '(a b)) => (b)
function bf_cdr(e, env)
  local rights = eval_list(e, env)

  if not (rights["num"] == 1 and rights[1]["type"] == "cons") then
    error("invalid args")
  end

  return rights[1]["right"]
end

-- (cons a b) => (a b)
function bf_cons(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 2 then
    error("invalid args")
  end

  return make_cons(rights[1], rights[2])
end

-- (list) => ()
-- (list a b c) => (a b c)
function bf_list(e, env)
  local ans
  local rights = eval_list(e, env)

  ans = fold_ary_r(rights,
    function(a, x)
      return make_cons(x, a)
    end, {type = "null"})

  return ans
end

-- (length '()) => 0
-- (length '(1 2 3)) => 3
function bf_length(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  local i = 0
  local data = rights[1]

  while data["type"] == "cons" do
    i = i + 1
    data = data["right"]
  end

  if data["type"] ~= "null" then
    error("invalid args")
  end

  return {type = "number", value = i}
end

-- (memq 'a '(a b c)) => (a b c)
-- (memq 'b '(a b c)) => (b c)
-- (memq 'd '(a b c)) => #f
function bf_memq(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 2 and is_list(rights[2], nil)) then
    error("invalid args")
  end

  local data = rights[2]

  while data["type"] == "cons" do
    local t = is_eq(rights[1], data["left"])
    if t then
      return data
    end
    data = data["right"]
  end

  return {type = "boolean", value = "f"}
end

-- (last '(1 2)) => 2
function bf_last(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 1 and is_list(rights[1], function(x) return x>=1 end)) then
    error("invalid args")
  end

  local data = rights[1]

  while data["right"]["type"] ~= "null" do
    data = data["right"]
  end

  return data["left"]
end

-- sub function for append
function list_to_ary(e)
  local i = 1
  local ary = {}

  while e["type"] == "cons" do
    ary[i] = e["left"]
    e = e["right"]
    i = i + 1
  end

  if e["type"] ~= "null" then
    error("arg should be a list")
  end

  ary["num"] = i - 1

  return ary
end

-- (append '(1 2) '(3 4 5)) => (1 2 3 4 5)
function bf_append(e, env)
  local ret
  local rights = eval_list(e, env)

  if not(rights["num"] == 2
    and is_list(rights[1], nil)
    and is_list(rights[2], nil)) then
    error("invalid args")
  end

  local ary = list_to_ary(rights[1])

  ans = fold_ary_r(ary,
    function(a, x)
      return make_cons(x, a)
    end, rights[2])

  return ans
end

-- (set-car a 1)
function bf_set_car_ex(data, env)
  local l

  if not is_list(data, 2) then
    error("invalid args")
  end

  if data["left"]["type"] ~= "id" then
    error("first arg should be id")
  end

  -- get addr of var
  l = get_var(env, data["left"]["value"])
  if l == nil then
    error("this variable is undefined: " .. data["left"]["value"])
  end

  if l["type"] ~= "cons" then
    error("value of 1st arg should be pair")
  end

  -- update env
  l["left"] = data["right"]["left"]

  return {type = "id", value = "<undefined>"}
end

-- (set-cdr a 1)
function bf_set_cdr_ex(data, env)
  local l

  if not is_list(data, 2) then
    error("invalid args")
  end

  if data["left"]["type"] ~= "id" then
    error("first arg should be id")
  end

  -- get addr of var
  l = get_var(env, data["left"]["value"])
  if l == nil then
    error("this variable is undefined: " .. data["left"]["value"])
  end

  if l["type"] ~= "cons" then
    error("value of 1st arg should be pair")
  end

  -- update env
  l["right"] = data["right"]["left"]

  return {type = "id", value = "<undefined>"}
end

-- (boolean? #t)
function bf_boolean_q(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "boolean" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- (not #t)
function bf_not(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 1) then
    error("invalid args")
  end

  if rights[1]["type"] == "boolean" and rights[1]["value"] == "f" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- (string? "test")
function bf_string_q(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "string" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- (string-append "foo" "bar")
function bf_string_append(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 2
    and rights[1]["type"] == "string" and rights[2]["type"] == "string") then
    error("invalid args")
  end

  return {type = "string", value = rights[1]["value"] .. rights[2]["value"]}
end

-- sub function for string-symbol convertion
function is_valid_symbol(str)
  local p, q, v
  p, q, v = string.find(str, "^([a-zA-Z!%$%%&*/:<=>%?%^_~%+%-][a-zA-Z!%$%%&*/:<=>%?%^_~%+%-0-9%.@]*)", 1)
  if q == string.len(str) then
    return true
  end
  return false
end

function symbol_encode(str)
  -- WIP
  return str
end

function symbol_decode(str_en)
  -- WIP
  return str_en
end

-- (string->symbol "foo")
function bf_string_to_symbol(e, env)
  local ans
  local rights = eval_list(e, env)

  if not(rights["num"] == 1 and rights[1]["type"] == "string") then
    error("invalid args")
  end

  if not is_valid_symbol(rights[1]["value"]) then
    ans = "$" .. symbol_encode(rights[1]["value"]) .. "$"
  else
    ans = rights[1]["value"]
  end

  return {type = "id", value = ans}
end

-- (symbol->string 'foo)
function bf_symbol_to_string(e, env)
  local ans
  local rights = eval_list(e, env)

  if not(rights["num"] == 1 and rights[1]["type"] == "id") then
    error("invalid args")
  end

  if string.sub(rights[1]["value"], 1, 1) == "$" then
    ans = string.sub(rights[1]["value"], 2, -2)
  else
    ans = rights[1]["value"]
  end
  ans = symbol_decode(ans)

  return {type = "string", value = ans}
end

-- (string->number "100")
function bf_string_to_number(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 1 and rights[1]["type"] == "string") then
    error("invalid args")
  end

  local tokens = tokenize(rights[1]["value"])
  local data, pos
  data, pos = parse(tokens)
  if pos < tokens["num"] + 1 then
    error("parser finished before parsing all tokens")
  end

  if data["type"] == "number" then
    return data
  else
    return {type = "boolean", value = "f"}
  end
end

-- (number->string 100)
function bf_number_to_string(e, env)
  local rights = eval_list(e, env)

  if not(rights["num"] == 1 and rights[1]["type"] == "number") then
    error("invalid args")
  end

  return {type = "string", value = tostring(rights[1]["value"])}
end

-- (procedure? car)
function bf_procedure_q(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "closure" or rights[1]["type"] == "closure_lua" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- sub function for eq? and equal?
function is_eq(e1, e2)
  local ans

  if e1["type"] ~= e2["type"] then
    ans = false
  elseif e1["type"] == "null" then
    ans = true
  elseif e1["type"] == "id"
    or e1["type"] == "boolean"
    or e1["type"] == "string"
    or e1["type"] == "number" then
    ans = (e1["value"] == e2["value"])
  elseif e1["type"] == "cons" then
    -- same pointer?
    ans = (e1 == e2)
  elseif e1["type"] == "closure" then
    -- same pointer?
    ans = (e1 == e2)
  elseif e1["type"] == "closure_lua" then
    -- same pointer?
    ans = (e1 == e2)
  elseif e1["type"] == "clos-class" then
    -- same pointer?
    ans = (e1 == e2)
  elseif e1["type"] == "clos-instance" then
    -- same pointer?
    ans = (e1 == e2)
  else
    -- unknown type
    ans = false
  end

  return ans
end

function is_equal(e1, e2)
  local ans

  if e1["type"] == "cons" and e2["type"] == "cons" then
    ans = is_equal(e1["left"], e2["left"])
    if ans then
      ans = is_equal(e1["right"], e2["right"])
    end
  else
    ans = is_eq(e1, e2)
  end

  return ans
end

-- (eq? 'a 'a) => #t
-- (eq? '() '()) => #t
-- (eq? car car) => #t
-- (let ((x '(a))) (eq? x x)) => #t
function bf_eq_q(e, env)
  local ans

  local rights = eval_list(e, env)

  if rights["num"] ~= 2 then
    error("invalid args")
  end

  ans = is_eq(rights[1], rights[2])

  if ans then
    ret = {type = "boolean", value = "t"}
  else
    ret = {type = "boolean", value = "f"}
  end

  return ret
end

-- (neq? 'a 'b) =? #t
function bf_neq_q(e, env)
  local tf = bf_eq_q(e, env)
  local ret

  if tf["value"] == "t" then
    ret = {type = "boolean", value = "f"}
  else
    ret = {type = "boolean", value = "t"}
  end

  return ret
end

-- (equal? '(a b c) '(a b c)) => true
function bf_equal_q(e, env)
  local ret
  local rights = eval_list(e, env)

  if rights["num"] ~= 2 then
    error("invalid args")
  end

  ans = is_equal(rights[1], rights[2])

  if ans then
    ret = {type = "boolean", value = "t"}
  else
    ret = {type = "boolean", value = "f"}
  end

  return ret
end

-- (load filename)
function bf_load(data, env)
  local ret
  local fn, h

  if not is_list(data, 1) then
    error("invalid args")
  end

  fn = eval(data["left"], env)
  if fn["type"] ~= "string" then
    error("1st arg should be string")
  end

  h = io.open(fn["value"], "r")
  if h == nil then
    error("file does not exist: " .. fn["value"])
  end

  local str, tokens, data, pos
  str = h:read("*a")
  tokens = tokenize(str)
  pos = 1
  while pos < tokens["num"] + 1 do
    data, pos = parse(tokens, pos)
    -- return the last eval
    ret = eval(data, env)
  end

  h:close()

  return ret
end

-- (error "what happened")
function bf_error(data, env)
  if not is_list(data, 1) then
    error("invalid args")
  end

  local reason = eval(data["left"], env)
  if reason["type"] ~= "string" then
    error("1st arg should be string")
  end

  error(reason["value"])
end
