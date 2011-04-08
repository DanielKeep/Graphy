module graphy.lua.Lua;

import lua.lua;
import lua.lauxlib;
import lua.lualib;

static import graphy.lua.Cairo;
static import graphy.lua.Vector;

lua_State* initenv()
{
    auto L = luaL_newstate();
    luaopen_base(L);
    luaopen_table(L);
    luaopen_string(L);
    luaopen_math(L);
    luaopen_debug(L);
    version( LuaJIT )
        luaopen_jit(L);

    graphy.lua.Cairo.openlib(L);
    graphy.lua.Vector.openlib(L);

    return L;
}

