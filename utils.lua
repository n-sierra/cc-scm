-- dump a table
function dump(t)
  dump_with_indent(t, 0)
end

function dump_with_indent(t, indent)
  local whites, i

  whites = ""
  for i = 1,indent do
    whites = " " .. whites
  end

  for k, v in pairs(t) do
    if(type(v) == "table") then
      print(whites .. tostring(k) .. " = " .. "<table>")
      dump_with_indent(v, indent+2)
    else
      print(whites .. tostring(k) .. " = " .. tostring(v))
    end
  end
end


