function eval_str(str, env)
  local tokens, data, ans_data, pos
  tokens = tokenize(str)
  if tokens["num"] == 0 then
    return nil
  end

  pos = 1
  while pos < tokens["num"] + 1 do
    data, pos = parse(tokens, pos)
    ans_data = eval(data, env)
  end

  return ans_data
end

function readline(indent)
  local line = ""
  local cursor = 1
  local history_index = #history + 1

  local _, y = term.getCursorPos()
  local width, height = term.getSize()

  local onCtrl = false

  term.setCursorBlink(true)

  while true do
    -- calculate gap
    local gap
    if indent:len()+cursor <= width then
      gap = 0
    else
      gap = (indent:len()+cursor) - width
    end

    term.clearLine()

    -- print text with $gap, $cursor and $line
    term.setCursorPos(1, y)
    term.write(indent .. line:sub(1+gap, width-indent:len()+gap))

    -- set cursor
    term.setCursorPos(indent:len()+cursor-gap, y)

    local event, param1 = os.pullEvent()
    if event == "char" then
      line = line:sub(1, cursor-1) .. param1 .. line:sub(cursor)
      cursor = cursor + 1
    elseif event == "key" and param1 == 29 then
      -- Ctrl
      onCtrl = true
    elseif event == "key" then
      if param1 == 28 then
        -- Enter
        break
      elseif (param1 == 14 or (onCtrl and param1 == 35)) and 2 <= cursor then
        -- BS or ^H
        line = line:sub(1, cursor-2) .. line:sub(cursor)
        cursor = cursor - 1
      elseif (param1 == 211 or (onCtrl and param1 == 32)) and cursor <= line:len() then
        -- Del or ^D
        line = line:sub(1, cursor-1) .. line:sub(cursor+1)
      elseif onCtrl and param1 == 37 then
        -- ^K
        line = line:sub(1, cursor-1)
      elseif (param1 == 203 or (onCtrl and param1 == 48)) and 2 <= cursor then
        -- Left or ^B
        cursor = cursor - 1
      elseif (param1 == 205 or (onCtrl and param1 == 33)) and cursor <= line:len() then
        -- Right or ^F
        cursor = cursor + 1
      elseif onCtrl and param1 == 30 then
        -- ^A
        cursor = 1
      elseif onCtrl and param1 == 18 then
        -- ^E
        cursor = line:len()+1
      elseif (param1 == 200 or (onCtrl and param1 == 25)) and 2 <= history_index then
        -- Up or ^P
        history_index = history_index - 1
        line = history[history_index]
        cursor = line:len() + 1
      elseif (param1 == 208 or (onCtrl and param1 == 49)) and history_index + 1 <= #history then
        -- Down or ^N
        history_index = history_index + 1
        line = history[history_index]
        cursor = line:len() + 1
      end

      -- turn of ctrl
      onCtrl= false
    end
  end

  -- update history
  if line ~= "" then
    history[#history+1] = line
  end

  -- go next line
  if y <= height-1 then
    term.setCursorPos(1, y+1)
  else
    term.scroll(1)
    term.setCursorPos(1, y)
  end

  term.setCursorBlink(false)

  return line
end

io.write("LUASCHEME INTERPRETER\n")

env = make_global_env()
pcall(eval_str, "(load \"init.scm\")", env)

history = {}

while true do
  local line, success, data

  line = ""
  while line == "" do
    line = readline("scm> ")
  end

  if line == nil then
    break
  end

  success, data = pcall(eval_str, line, env)

  if not success then
    io.write("[error] ")
    io.write(data)
    io.write("\n")
  elseif data then
    io.write(data_to_string(data))
    io.write("\n")
  else
    io.write("\n")
  end
end

io.write("\nBYE\n")
