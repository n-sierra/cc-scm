require("parser")
require("tokenizer")
require("compiler")
require("global_env")
require("utils")

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
assert(data3["right"]["type"] == "id")
assert(data3["right"]["value"] == "sym")

-- Compiler

env = make_global_env()
ans = eval(data, env)
assert(ans["type"] == "number")
assert(ans["value"] == 3)

print("finished all tests")
