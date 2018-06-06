#!/usr/bin/env lua

-- this is a comment

--- But this is documentation
-- and so is this, now.

--[[ this is a block comment ]]

--[==[
  This is also a block comment
  ]==]

--[=[-
  But this is documentation
  ]=]

if arg[1] == nil
    then name = "world"
    else name = arg[1]
    end
print( "Hello " .. name .. "!" );
