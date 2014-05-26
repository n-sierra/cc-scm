require("parse")
require("tokenize")
require("eval")
require("global_env")

function eval_str(str)
  local tokens, data, env, ans
  tokens = tokenize(str)
  data = parse(tokens)
  env = make_global_env()
  ans = eval(data, env)
  return ans
end

function eval_assert(str)
  local ans = eval_str(str)
  assert(ans["type"] == "boolean" and ans["value"] == "t")
end


print("starting tests...")

--Tokenize

tokens = tokenize("(+ 1 2) ")
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
tokens2 = tokenize("\"\\\"\\\\str\"")
assert(tokens2[1]["type"] == "string")
assert(tokens2[1]["value"] == "\"\\str")

tokens3 = tokenize("'sym")
assert(tokens3[1]["type"] == "'")
assert(tokens3[2]["type"] == "id")
assert(tokens3[2]["value"] == "sym")

tokens4 = tokenize("()")
assert(tokens4[1]["type"] == "(")
assert(tokens4[2]["type"] == ")")

-- Parse

data = parse(tokens)
assert(data["type"] == "cons")
assert(data["left"]["type"] == "id")
assert(data["left"]["value"] == "+")
assert(data["type"] == "cons")
assert(data["right"]["left"]["type"] == "number")
assert(data["right"]["left"]["value"] == 1)
assert(data["right"]["right"]["right"]["type"] == "null")

data2 = parse(tokens2)
assert(data2["type"] == "string")
assert(data2["value"] == "\"\\str")

data3 = parse(tokens3)
assert(data3["left"]["type"] == "id")
assert(data3["left"]["value"] == "quote")
assert(data3["right"]["type"] == "cons")
assert(data3["right"]["left"]["type"] == "id")
assert(data3["right"]["left"]["value"] == "sym")
assert(data3["right"]["right"]["type"] == "null")

data4 = parse(tokens4)
assert(data4["type"] == "null")

-- Eval

env = make_global_env()
ans = eval(data, env)
assert(ans["type"] == "number")
assert(ans["value"] == 3)

-- Some useful functions
do
  local data1 = eval_str("'(a b c)")
  local data2 = eval_str("'()")
  local data3 = eval_str("'a")
  local data4 = eval_str("'(a . b)")
  assert(is_list(data1, nil) == true)
  assert(is_list(data1, 0)   == false)
  assert(is_list(data1, 2)   == false)
  assert(is_list(data1, 3)   == true)
  assert(is_list(data1, 4)   == false)
  assert(is_list(data1, function(x) return x == 3 end) == true)
  assert(is_list(data1, function(x) return x ~= 3 end) == false)
  assert(is_list(data2, nil) == true)
  assert(is_list(data2, 0)   == true)
  assert(is_list(data2, 1)   == false)
  assert(is_list(data3, nil) == false)
  assert(is_list(data3, 0)   == false)
  assert(is_list(data4, nil) == false)
  assert(is_list(data4, 0)   == false)
  assert(is_list(data4, 1)   == false)
end

-- Global Environment

ans = eval_str("'var")
assert(ans["type"] == "id")
assert(ans["value"] == "var")

ans = eval_str("(quote (1 2))")
assert(ans["type"] == "cons")
assert(ans["left"]["value"] == 1)
assert(ans["right"]["left"]["value"] == 2)

eval_assert("(equal? (apply cons '(a ())) '(a))")

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
ans = eval_str("(cond (#t 10 20))")
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

ans = eval_str("(do ((i 0 (+ i 1)) (j 0 (+ j 2))) ((< 9 i) (+ i j)))")
assert(ans["value"] == 30)
ans = eval_str("(let ((i 0)) (do ((j 0 (+ j 1))) ((< 9 j) i) (set! i (+ i j))))")
assert(ans["value"] == 45)

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

-- load

do
  local fn = "test.scm"
  local h = io.open(fn, "r")
  if h == nil then
    error("the test file does not exist: " .. fn)
  end
  h:close()

  ans = eval_str("(load \"test.scm\")")
  assert(ans["value"] == "t")
end

-- number

ans = eval_str("(+ 10)")
assert(ans["value"] == 10)
ans = eval_str("(+ 10 20)")
assert(ans["value"] == 30)

ans = eval_str("(- 20)")
assert(ans["value"] == -20)
ans = eval_str("(- 20 10 10)")
assert(ans["value"] == 0)

ans = eval_str("(* 20)")
assert(ans["value"] == 20)
ans = eval_str("(* 20 10 10)")
assert(ans["value"] == 2000)

ans = eval_str("(/ 1)")
assert(ans["value"] == 1)
ans = eval_str("(/ 4 2 1)")
assert(ans["value"] == 2)

ans = eval_str("(= (+ 1 2) (+ 2 1))")
assert(ans["value"] == "t")

ans = eval_str("(< 10 20)")
assert(ans["type"] == "boolean")
assert(ans["value"] == "t")
ans = eval_str("(< 30 20)")
assert(ans["value"] == "f")
ans = eval_str("(< 0 10 20)")
assert(ans["value"] == "t")

ans = eval_str("(<= 30 20)")
assert(ans["value"] == "f")

ans = eval_str("(> 30 20)")
assert(ans["value"] == "t")

ans = eval_str("(>= 30 20)")
assert(ans["value"] == "t")

-- list

ans = eval_str("(null? 10)")
assert(ans["value"] == "f")
ans = eval_str("(null? '())")
assert(ans["value"] == "t")

ans = eval_str("(pair? 10)")
assert(ans["value"] == "f")
ans = eval_str("(pair? '())")
assert(ans["value"] == "f")
ans = eval_str("(pair? '(a . b))")
assert(ans["value"] == "t")
ans = eval_str("(pair? '(a b))")
assert(ans["value"] == "t")

ans = eval_str("(list? 10)")
assert(ans["value"] == "f")
ans = eval_str("(list? '())")
assert(ans["value"] == "t")
ans = eval_str("(list? '(a b))")
assert(ans["value"] == "t")

ans = eval_str("(symbol? 'a)")
assert(ans["value"] == "t")
ans = eval_str("(symbol? 10)")
assert(ans["value"] == "f")
ans = eval_str("(symbol? '())")
assert(ans["value"] == "f")

ans = eval_str("(car '(a . b))")
assert(ans["value"] == "a")
ans = eval_str("(cdr '(a . b))")
assert(ans["value"] == "b")
ans = eval_str("(car (cons 'a 'b))")
assert(ans["value"] == "a")
ans = eval_str("(cdr (cons 'a 'b))")
assert(ans["value"] == "b")

ans = eval_str("(list)")
assert(ans["type"] == "null")
ans = eval_str("(car (list 'a 'b))")
assert(ans["value"] == "a")
ans = eval_str("(car (cdr (list 'a 'b)))")
assert(ans["value"] == "b")

ans = eval_str("(length '(1 2 3))")
assert(ans["value"] == 3)

ans = eval_str("(equal? (memq 'a '(a b c)) '(a b c))")
assert(ans["value"] == "t")
ans = eval_str("(equal? (memq 'b '(a b c)) '(b c))")
assert(ans["value"] == "t")

ans = eval_str("(last '(1 2 3))")
assert(ans["value"] == 3)

ans = eval_str("(equal? (append '(1 2) '(3 4 5)) '(1 2 3 4 5))")
assert(ans["value"] == "t")

ans = eval_str("(begin (define a '(10 20)) (set-car! a 30) (car a))")
assert(ans["value"] == 30)
ans = eval_str("(begin (define a '(10 20)) (set-cdr! a 30) (cdr a))")
assert(ans["value"] == 30)

-- boolean

eval_assert("(eq? (boolean? #t) #t)")
eval_assert("(eq? (boolean? #f) #t)")
eval_assert("(eq? (boolean? 10) #f)")

eval_assert("(eq? (not #t) #f)")
eval_assert("(eq? (not #f) #t)")
eval_assert("(eq? (not 10) #f)")

-- string

eval_assert("(eq? (string? 'a) #f)")
eval_assert("(eq? (string? \"foo\") #t)")

eval_assert("(equal? (string-append \"foo\" \"bar\") \"foobar\")")

eval_assert("(equal? (string->symbol \"foo\") 'foo)")
eval_assert("(equal? (string->symbol \"10\") '$10$)")

eval_assert("(equal? (symbol->string 'foo) \"foo\")")
eval_assert("(equal? (symbol->string '$10$) \"10\")")

eval_assert("(equal? (string->number \"100\") 100)")
eval_assert("(equal? (string->number \"abc\") #f)")

eval_assert("(equal? (number->string 100) \"100\")")

-- procedure

eval_assert("(eq? (procedure? car) #t)")
eval_assert("(eq? (procedure? (lambda (x) (+ x 1))) #t)")
eval_assert("(eq? (procedure? 10) #f)")

-- eq

ans = eval_str("(eq? 'a 'a)")
assert(ans["value"] == "t")
ans = eval_str("(eq? 'a 'b)")
assert(ans["value"] == "f")
ans = eval_str("(eq? '() '())")
assert(ans["value"] == "t")
ans = eval_str("(eq? '(a b c) '(a b c))")
assert(ans["value"] == "f")
ans = eval_str("(eq? car car)")
assert(ans["value"] == "t")
ans = eval_str("(eq? car cdr)")
assert(ans["value"] == "f")
ans = eval_str("(let ((x '(a))) (eq? x x))")
assert(ans["value"] == "t")

ans = eval_str("(neq? 'a 'a)")
assert(ans["value"] == "f")
ans = eval_str("(neq? 'a 'b)")
assert(ans["value"] == "t")

ans = eval_str("(equal? 'a 'a)")
assert(ans["value"] == "t")
ans = eval_str("(equal? '(a b c) '(a b c))")
assert(ans["value"] == "t")
ans = eval_str("(equal? '(a b) '(a b c))")
assert(ans["value"] == "f")
ans = eval_str("(equal? '(a b . c) '(a b . c))")
assert(ans["value"] == "t")
ans = eval_str("(equal? '(a (b) c) '(a (b) c))")
assert(ans["value"] == "t")
ans = eval_str("(equal? 10 10)")
assert(ans["value"] == "t")
ans = eval_str("(equal? 10 20)")
assert(ans["value"] == "f")
ans = eval_str("(equal? \"test\" \"test\")")
assert(ans["value"] == "t")
ans = eval_str("(equal? \"test!\" \"test?\")")
assert(ans["value"] == "f")

-- lua
ans = eval_str("(lua-get-g)")
assert(ans["value"] == _G)

eval_assert("(lua-object? (lua-get-g))")
eval_assert("(lua-object? (scm->lua 100))")
eval_assert("(not (lua-object? 100))")

eval_assert([[
(begin
  (define type (lua-gettable (lua-get-g) (scm->lua "type")))
  (define t (lua-call type (scm->lua 100)))
  (define u (lua->scm (lua-gettable t (scm->lua 1))))
  (equal? u "number"))
]])

-- Closure Test

ans = eval_str("(begin (define deposit ((lambda (amount) (lambda (x) (set! amount (+ amount x)) amount)) 100)) (deposit 200))")
assert(ans["value"] == 300)

print("finished all tests")
