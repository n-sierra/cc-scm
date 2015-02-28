require("eval")

function get_clos_funcs()
  local clos_funcs = {
    ["class?"] = cf_class_q,
    ["instance?"] = cf_instance_q,
    ["class-of"] = cf_class_of,
    ["superclass-of"] = cf_superclass_of,
    ["make-class"] = cf_make_class,
    ["make-instance"] = cf_make_instance,
    ["register-slot"] = cf_register_slot,
    ["set-slot!"] = cf_set_slot_ex,
    ["refer-slot"] = cf_refer_slot,
  }

  return clos_funcs
end

-- (class? obj)
function cf_class_q(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "clos-class" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- (instance? obj)
function cf_instance_q(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] == "clos-instance" then
    return {type = "boolean", value = "t"}
  else
    return {type = "boolean", value = "f"}
  end
end

-- (class-of obj)
function cf_class_of(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] ~= "clos-instance" then
    error("invalid args")
  end

  return rights[1]["class"]
end

-- (superclass-of class)
function cf_superclass_of(e, env)
  local rights = eval_list(e, env)

  if rights["num"] ~= 1 then
    error("invalid args")
  end

  if rights[1]["type"] ~= "clos-class" then
    error("invalid args")
  end

  return rights[1]["super"]
end

-- (make-class super)
-- => {type = "clos-class", super = super}
function cf_make_class(data, env)
  if not(is_list(data, 1)) then
    error("invalid args")
  end

  local super = eval(data["left"], env)
  if not(super["type"] == "clos-class" or super["type"] == "null") then
    error("invalid second arg")
  end

  local class_data = {type = "clos-class", super = super}

  return class_data
end

-- (make-instance class)
-- => {type = "clos-instance", class = class, slots = {}}
function cf_make_instance(data, env)
  if not(is_list(data, 1)) then
    error("invalid args")
  end

  local class = eval(data["left"], env)
  if class["type"] ~= "clos-class" then
    error("invalid first arg")
  end

  local slots = new_env(nil)

  return {type = "clos-instance", class = class, slots = slots}
end

-- (refer-slot m slot)
function cf_refer_slot(data, env)
  if not(is_list(data, 2)) then
    error("invalid args")
  end

  local instance = eval(data["left"], env)
  if instance["type"] ~= "clos-instance" then
    error("invalid first arg")
  end

  local slot = data["right"]["left"]
  if slot["type"] ~= "id" then
    error("invalid args")
  end

  local ret =  get_var(instance["slots"], slot["value"])
  if not ret then
    error("undefined variable is refered: " .. slot["value"])
  end

  return ret
end

-- (register-slot m slot x)
function cf_register_slot(data, env)
  if not(is_list(data, 3)) then
    error("invalid args")
  end

  local instance = eval(data["left"], env)
  if instance["type"] ~= "clos-instance" then
    error("invalid first arg")
  end

  local slot = data["right"]["left"]
  if slot["type"] ~= "id" then
    error("invalid args")
  end

  local ret = eval(data["right"]["right"]["left"], env)
  put_var(instance["slots"], slot["value"], ret)

  return instance
end

-- (set-slot! m slot x)
function cf_set_slot_ex(data, env)
  if not(is_list(data, 3)) then
    error("invalid args")
  end

  local instance = eval(data["left"], env)
  if instance ~= "clos-instance" then
    error("invalid first arg")
  end

  local slot = data["right"]["left"]
  if slot["type"] ~= "id" then
    error("invalid args")
  end

  local ret = eval(data["right"]["right"]["left"], env)
  if update_var(instance["slots"], slot["value"], ret) == nil then
    error("this variable is undefined: " .. slot["value"])
  end

  return ret
end
