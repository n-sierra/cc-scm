require("parser")
require("tokenizer")
require("compiler")

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
    -- boolean
    -- string
    -- procedure
    -- eq
    -- meta
    ["load"]  = bf_load,
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
    ans = 1 / rights[1]["value"]
  else
    ans = fold_ary(rights,
      function(a, x)
        if x["type"] ~= "number" then
          error("args should be number")
        end
        if a == nil then
          return x["value"]
        else
          return a / x["value"]
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

  do
    local str, tokens, data
    str = h:read("*a")
    tokens = tokenizer(str)
    data = parser(tokens)
    ret = eval(data, env)
  end

  h:close()

  return ret
end

function fold_ary(rights, func, init)
  local ans

  ans = init
  for i, x in ipairs(rights) do
    ans = func(ans, x)
  end

  return ans
end

