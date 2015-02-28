# cc-scm

cc-scm is a scheme interpreter, which is implemented by Lua.

You can run it on [ComputerCraft](http://www.computercraft.info/)(a modification for [Minecraft](https://minecraft.net/)).

## Usage (on \*nix/Windows)

    % git clone https://github.com/n-sierra/cc-scm.git
    % cd cc-scm
    % lua repl.lua
    LUASCHEME INTERPRETER
    scm> (+ 1 2)
    3
    scm> ((lambda (x) (* x x)) 16)
    256
    scm>

Lua 5.1.4 is recommended, while it stil works fine at 5.2.0,

## Usage (on Minecraft)

1. Create *cc-scm*.

    % lua concat_file.lua > cc-scm

2. Put *cc-scm* into your [computer](http://computercraft.info/wiki/Computer) in Minecraft.

3. HAVE FUN!

## Screenshots

![screenshot 01](https://github.com/n-sierra/cc-scm/raw/master/img/screenshot01.gif)

![screenshot 02](https://github.com/n-sierra/cc-scm/raw/master/img/screenshot02.gif)

## Differences from R5RS

- Supports only integer for number
- Doesn't support 'Char' or 'Vector' type
- Doesn't support several procedures/features
  + caar, eqv?, map, string-\*, lazy eval, call/cc, ...
- Supports CLOS-like procedures
  + make-class, make-instance, refer-slot, ...
- Supports operations for dealing Lua object
  + Convert: scm->lua, lua->scm
  + Call: lua-call
  + Get: lua-get-g
  + Table-operation: lua-gettable

## License

This software is released under the MIT License, see LICENSE.txt.
