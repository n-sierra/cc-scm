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
  dump(ans)
end
