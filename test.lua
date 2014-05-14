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

-- \"\\str
tokens2 = tokenizer("\"\\\"\\\\str\"")
assert(tokens2[1]["type"] == "string")
assert(tokens2[1]["value"] == "\"\\str")

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
assert(data2["value"] == "\"\\str")

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

ans = eval_str("(cond (#t 10) (#t 20))")
assert(ans["value"] == 10)
ans = eval_str("(cond (#t 10) (#f 20))")
assert(ans["value"] == 10)
ans = eval_str("(cond (#f 10) (#t 20))")
assert(ans["value"] == 20)
ans = eval_str("(cond (#t 10) (else 20))")
assert(ans["value"] == 10)
ans = eval_str("(cond (#f 10) (else 20))")
assert(ans["value"] == 20)
ans = eval_str("(cond (10 => (lambda (x) x)) (else 20))")
assert(ans["value"] == 10)
ans = eval_str("(cond (#f => (lambda (x) x)) (else 20))")
assert(ans["value"] == 20)

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

ans = eval_str("(let ((x 10) (y 20)) (+ x y))")
assert(ans["value"] == 30)
ans = eval_str("(let ittr ((x 0) (y 0)) (if (< x 10) (ittr (+ x 1) (+ y x)) y))")
assert(ans["value"] == 45)


ans = eval_str("(let* ((x 10) (y (+ x 10))) (+ x y))")
assert(ans["value"] == 30)

ans = eval_str("(letrec ((double (lambda (x) (+ x x)))) (double 30))")
assert(ans["value"] == 60)

ans = eval_str("((lambda () 10))")
assert(ans["value"] == 10)
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

ans = eval_str("(and)")
assert(ans["type"] == "boolean")
assert(ans["value"] == "t")
ans = eval_str("(and 10)")
assert(ans["value"] == 10)
ans = eval_str("(and #f)")
assert(ans["value"] == "f")
ans = eval_str("(and 10 20)")
assert(ans["value"] == 20)
ans = eval_str("(and #f 20)")
assert(ans["value"] == "f")
ans = eval_str("(and #f x)")
assert(ans["value"] == "f")

ans = eval_str("(or)")
assert(ans["type"] == "boolean")
assert(ans["value"] == "f")
ans = eval_str("(or 10)")
assert(ans["value"] == 10)
ans = eval_str("(or #f)")
assert(ans["value"] == "f")
ans = eval_str("(or 10 20)")
assert(ans["value"] == 10)
ans = eval_str("(or #f 20)")
assert(ans["value"] == 20)
ans = eval_str("(or #t x)")
assert(ans["value"] == "t")

ans = eval_str("(+ 10 20)")
assert(ans["value"] == 30)

ans = eval_str("(< 10 20)")
assert(ans["type"] == "boolean")
assert(ans["value"] == "t")
ans = eval_str("(< 30 20)")
assert(ans["value"] == "f")

-- Closure Test

ans = eval_str("(begin (define deposit ((lambda (amount) (lambda (x) (set! amount (+ amount x)) amount)) 100)) (deposit 200))")
assert(ans["value"] == 300)

print("finished all tests")
