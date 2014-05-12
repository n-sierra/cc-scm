require("parser")
require("tokenizer")
require("compiler")
require("global_env")
require("utils")

function eval_str(str)
  local tokens, data, env, ans
  tokens = tokenizer(str)
  data = parser(tokens)
  env = make_global_env()
  ans = eval(data, env)
  return ans
end

print("starting tests...")

--Tokenizer

tokens = tokenizer("(+ 1 2)")
assert(tokens[0] == nil)
assert(tokens[1]["type"] == "(")
assert(tokens[1]["value"] == nil)
assert(tokens[2]["type"] == "id")
assert(tokens[2]["value"] == "+")
assert(tokens[3]["type"] == "number")
assert(tokens[3]["value"] == 1)
assert(tokens[5]["type"] == ")")
assert(tokens[5]["value"] == nil)
assert(tokens[6] == nil)

tokens2 = tokenizer("\"str\"")
assert(tokens2[1]["type"] == "string")
assert(tokens2[1]["value"] == "str")

tokens3 = tokenizer("'sym")
assert(tokens3[1]["type"] == "'")
assert(tokens3[2]["type"] == "id")
assert(tokens3[2]["value"] == "sym")

tokens4 = tokenizer("()")
assert(tokens4[1]["type"] == "(")
assert(tokens4[2]["type"] == ")")

-- Parser

data = parser(tokens)
assert(data["type"] == "cons")
assert(data["left"]["type"] == "id")
assert(data["left"]["value"] == "+")
assert(data["type"] == "cons")
assert(data["right"]["left"]["type"] == "number")
assert(data["right"]["left"]["value"] == 1)
assert(data["right"]["right"]["right"]["type"] == "null")

data2 = parser(tokens2)
assert(data2["type"] == "string")
assert(data2["value"] == "str")

data3 = parser(tokens3)
assert(data3["left"]["type"] == "id")
assert(data3["left"]["value"] == "quote")
assert(data3["right"]["type"] == "cons")
assert(data3["right"]["left"]["type"] == "id")
assert(data3["right"]["left"]["value"] == "sym")
assert(data3["right"]["right"]["type"] == "null")

data4 = parser(tokens4)
assert(data4["type"] == "null")

-- Compiler

env = make_global_env()
ans = eval(data, env)
assert(ans["type"] == "number")
assert(ans["value"] == 3)

-- Global Environment

ans = eval_str("'var")
assert(ans["type"] == "id")
assert(ans["value"] == "var")

ans = eval_str("(quote (1 2))")
assert(ans["type"] == "cons")
assert(ans["left"]["value"] == 1)
assert(ans["right"]["left"]["value"] == 2)

ans = eval_str("(if #t 1 2)")
assert(ans["value"] == 1)
ans = eval_str("(if #f 1 2)")
assert(ans["value"] == 2)
ans = eval_str("(if #t 1)")
assert(ans["value"] == 1)

ans = eval_str("(begin (define x 1) (+ x 1))")
assert(ans["value"] == 2)
ans = eval_str("(begin (define (f x) (+ x 1)) (f 1))")
assert(ans["value"] == 2)
ans = eval_str("(begin (define (g x . y) y) (g 1 2 3))")
assert(ans["type"] == "cons")
assert(ans["left"]["value"] == 2)
assert(ans["right"]["left"]["value"] == 3)

ans = eval_str("(begin (define x 1) (set! x (+ x 1)) x)")
assert(ans["value"] == 2)

ans = eval_str("((lambda (x y) (+ x y)) 10 20)")
assert(ans["value"] == 30)
ans = eval_str("((lambda (x) 1 2 3) 4)")
assert(ans["value"] == 3)
ans = eval_str("((lambda (x . y) y) 1 2 3)")
assert(ans["type"] == "cons")
assert(ans["left"]["value"] == 2)
assert(ans["right"]["left"]["value"] == 3)

ans = eval_str("(begin (define x 1 2 3) x)")
assert(ans["value"] == 3)

ans = eval_str("(+ 10 20)")
assert(ans["value"] == 30)

-- Closure Test

ans = eval_str("(begin (define deposit ((lambda (amount) (lambda (x) (set! amount (+ amount x)) amount)) 100)) (deposit 200))")
assert(ans["value"] == 300)

print("finished all tests")
