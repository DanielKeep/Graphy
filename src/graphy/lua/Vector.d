module graphy.lua.Vector;

import tango.math.Math : sqrt;

import lua.lua;
import lua.lauxlib;

const VECTOR_XY_TYPE = "vector_xy";

union vector_xy
{
    struct { double x, y; }
    double[2] xy;
}

vector_xy* vector_xy_create_push(lua_State* L,
        double x = double.init, double y = double.init)
{
    auto v = cast(vector_xy*) lua_newuserdata(L, vector_xy.sizeof);
    luaL_getmetatable(L, VECTOR_XY_TYPE.ptr);
    lua_setmetatable(L, -2);

    v.x = x;
    v.y = y;

    return v;
}

vector_xy* checkvector_xy(lua_State* L, int ud)
{
    return cast(vector_xy*) luaL_checkudata(L, ud, VECTOR_XY_TYPE.ptr);
}

bool is_vector_xy(lua_State* L, int index)
{
    auto v = cast(vector_xy*) lua_touserdata(L, index);
    if( v !is null )
    {
        if( lua_getmetatable(L, index) )
        {
            lua_getfield(L, LUA_REGISTRYINDEX, VECTOR_XY_TYPE.ptr);
            if( lua_rawequal(L, -1, -2) )
            {
                lua_pop(L, 2);
                return true;
            }
            lua_pop(L, 2);
        }
    }
    
    return false;
}

extern(C) int vector_xy_create(lua_State* L)
{
    auto top = lua_gettop(L);
    double x,y;

    if( top == 2 )
    {
        x = luaL_checknumber(L, 1);
        y = luaL_checknumber(L, 2);
    }
    else if( top != 0 )
    {
        lua_pushstring(L, "can only create vectors with zero or two numbers");
        lua_error(L);
        assert(0);
    }

    vector_xy_create_push(L, x, y);

    return 1;
}

extern(C) int vector_xy_add(lua_State* L)
{
    auto a = cast(vector_xy*) luaL_checkudata(L, 1, VECTOR_XY_TYPE.ptr);
    auto b = cast(vector_xy*) luaL_checkudata(L, 2, VECTOR_XY_TYPE.ptr);
    auto c = vector_xy_create_push(L);

    c.xy[] = a.xy[] + b.xy[];

    return 1;
}

extern(C) int vector_xy_div(lua_State* L)
{
    auto v1 = is_vector_xy(L, 1);
    auto v2 = is_vector_xy(L, 2);
    auto n1 = lua_isnumber(L, 1);
    auto n2 = lua_isnumber(L, 2);

    if( v1 && v2 )
    {
        auto a = cast(vector_xy*) lua_touserdata(L, 1);
        auto b = cast(vector_xy*) lua_touserdata(L, 2);
        auto c = vector_xy_create_push(L);

        c.xy[] = a.xy[] / b.xy[];

        return 1;
    }
    else if( v1 && n2 )
    {
        auto a = cast(vector_xy*) lua_touserdata(L, 1);
        auto bf = lua_tonumber(L, 2);
        double[2] b; b[] = bf;
        auto c = vector_xy_create_push(L);

        c.xy[] = a.xy[] / b[];

        return 1;
    }
    else if( n1 && v2 )
    {
        auto af = lua_tonumber(L, 2);
        double[2] a; a[] = af;
        auto b = cast(vector_xy*) lua_touserdata(L, 1);
        auto c = vector_xy_create_push(L);

        c.xy[] = a[] / b.xy[];

        return 1;
    }
    else
    {
        lua_pushstring(L, "expected at least one vector argument");
        lua_error(L);
        assert(0);
    }
}

extern(C) int vector_xy_mul(lua_State* L)
{
    auto v1 = is_vector_xy(L, 1);
    auto v2 = is_vector_xy(L, 2);
    auto n1 = lua_isnumber(L, 1);
    auto n2 = lua_isnumber(L, 2);

    if( v1 && v2 )
    {
        auto a = cast(vector_xy*) lua_touserdata(L, 1);
        auto b = cast(vector_xy*) lua_touserdata(L, 2);
        auto c = vector_xy_create_push(L);

        c.xy[] = a.xy[] * b.xy[];

        return 1;
    }
    else if( v1 && n2 )
    {
        auto a = cast(vector_xy*) lua_touserdata(L, 1);
        auto bf = lua_tonumber(L, 2);
        double[2] b; b[] = bf;
        auto c = vector_xy_create_push(L);

        c.xy[] = a.xy[] * b[];

        return 1;
    }
    else if( n1 && v2 )
    {
        auto af = lua_tonumber(L, 2);
        double[2] a; a[] = af;
        auto b = cast(vector_xy*) lua_touserdata(L, 1);
        auto c = vector_xy_create_push(L);

        c.xy[] = a[] * b.xy[];

        return 1;
    }
    else
    {
        lua_pushstring(L, "expected at least one vector argument");
        lua_error(L);
        assert(0);
    }
}

extern(C) int vector_xy_sub(lua_State* L)
{
    auto a = cast(vector_xy*) luaL_checkudata(L, 1, VECTOR_XY_TYPE.ptr);
    auto b = cast(vector_xy*) luaL_checkudata(L, 2, VECTOR_XY_TYPE.ptr);
    auto c = vector_xy_create_push(L);

    c.xy[] = a.xy[] - b.xy[];

    return 1;
}

extern(C) int vector_xy_tostring(lua_State* L)
{
    auto v = cast(vector_xy*) luaL_checkudata(L, 1, VECTOR_XY_TYPE.ptr);
    lua_pushfstring(L, "(%f, %f)".ptr, v.x, v.y);
    return 1;
}

extern(C) int vector_xy_dot(lua_State* L)
{
    auto a = cast(vector_xy*) luaL_checkudata(L, 1, VECTOR_XY_TYPE.ptr);
    auto b = cast(vector_xy*) luaL_checkudata(L, 2, VECTOR_XY_TYPE.ptr);
    double[2] c; c[] = a.xy[] * b.xy[];
    lua_pushnumber(L, c[0]+c[1]);
    return 1;
}

extern(C) int vector_xy_index(lua_State* L)
{
    auto v = cast(vector_xy*) luaL_checkudata(L, 1, VECTOR_XY_TYPE.ptr);
    luaL_checkany(L, 2);

    if( lua_isnumber(L, 2) )
    {
        int k = lua_tointeger(L, 2);
        if( k<1 || k>2 )
        {
            lua_pushstring(L, "vector index must in [1,2]");
            lua_error(L);
            assert(0);
        }
        lua_pushnumber(L, v.xy[k-1]);
        return 1;
    }
    else if( lua_isstring(L, 2) )
    {
        size_t kl;
        char* kp = lua_tolstring(L, 2, &kl);
        auto k = kp[0..kl];
        switch( k.length )
        {
            case 1:
                switch( k )
                {
                    case "x":
                        lua_pushnumber(L, v.x);
                        return 1;

                    case "y":
                        lua_pushnumber(L, v.y);
                        return 1;

                    default:
                }
                break;

            case 2:
                switch( k )
                {
                    case "xx":
                        vector_xy_create_push(L, v.x, v.x);
                        return 1;
                    case "xy":
                        vector_xy_create_push(L, v.x, v.y);
                        return 1;
                    case "yx":
                        vector_xy_create_push(L, v.y, v.x);
                        return 1;
                    case "yy":
                        vector_xy_create_push(L, v.y, v.y);
                        return 1;

                    default:
                }
                break;

            default:
                switch( k )
                {
                    /* TODO:

                       * angle

                    */

                    case "dot":
                        lua_pushcfunction(L, &vector_xy_dot);
                        return 1;

                    case "mag":
                        lua_pushnumber(L, sqrt(v.x*v.x+v.y*v.y));
                        return 1;

                    case "norm":
                        auto m = sqrt(v.x*v.x+v.y*v.y);
                        if( m != 0.0 )
                            vector_xy_create_push(L, v.x/m, v.y/m);
                        else
                            vector_xy_create_push(L, 0.0, 0.0);
                        return 1;

                    case "totable":
                        lua_createtable(L, 2, 0);
                        lua_pushinteger(L, 1);
                        lua_pushnumber(L, v.x);
                        lua_settable(L, -3);
                        lua_pushinteger(L, 2);
                        lua_pushnumber(L, v.y);
                        lua_settable(L, -3);
                        return 1;

                    default:
                }
        }

        lua_pushstring(L, "expected number or string key to vector");
        lua_error(L);
        assert(0);
    }
    else
    {
        lua_pushstring(L, "expected number or string key to vector");
        lua_error(L);
        assert(0);
    }
}

extern(C) int vector_xy_newindex(lua_State* L)
{
    auto v = cast(vector_xy*) luaL_checkudata(L, 1, VECTOR_XY_TYPE.ptr);
    auto f = luaL_checknumber(L, 3);
    luaL_checkany(L, 2);

    if( lua_isnumber(L, 2) )
    {
        auto k = lua_tointeger(L, 2);
        if( k<1 || k>2 )
        {
            lua_pushstring(L, "vector index must be in [1,2]");
            lua_error(L);
            assert(0);
        }
        v.xy[k-1] = f;
        return 0;
    }
    else if( lua_isstring(L, 2) )
    {
        size_t kl;
        char* kp = lua_tolstring(L, 2, &kl);
        auto k = kp[0..kl];
        switch( k )
        {
            case "x":
                v.x = f;
                return 0;

            case "y":
                v.y = f;
                return 0;

            case "mag":
                if( f == 0 )
                {
                    v.x = 0.0;
                    v.y = 0.0;
                }
                else
                {
                    auto mag = sqrt(v.x*v.x+v.y*v.y) / f;
                    if( mag != 0.0 )
                    {
                        v.x /= mag;
                        v.y /= mag;
                    }
                }
                return 0;

            default:
                lua_pushstring(L, "vector key must be 'x' or 'y'");
                lua_error(L);
                assert(0);
        }
        assert(0);
    }
    else
    {
        lua_pushstring(L, "expected number or string key to vector");
        lua_error(L);
        assert(0);
    }
}

void openlib(lua_State* L)
{
    // Create vector_xy type
    luaL_newmetatable(L, VECTOR_XY_TYPE.ptr);

    lua_pushstring(L, "tag".ptr);
    lua_pushstring(L, VECTOR_XY_TYPE.ptr);
    lua_settable(L, -3);

    /* TODO:

       * unm
       * len
       * eq

    */

    lua_pushstring(L, "__add".ptr);
    lua_pushcfunction(L, &vector_xy_add);
    lua_settable(L, -3);

    lua_pushstring(L, "__div".ptr);
    lua_pushcfunction(L, &vector_xy_div);
    lua_settable(L, -3);

    lua_pushstring(L, "__mul".ptr);
    lua_pushcfunction(L, &vector_xy_mul);
    lua_settable(L, -3);

    lua_pushstring(L, "__sub".ptr);
    lua_pushcfunction(L, &vector_xy_sub);
    lua_settable(L, -3);

    lua_pushstring(L, "__index".ptr);
    lua_pushcfunction(L, &vector_xy_index);
    lua_settable(L, -3);

    lua_pushstring(L, "__newindex".ptr);
    lua_pushcfunction(L, &vector_xy_newindex);
    lua_settable(L, -3);

    lua_pushstring(L, "__tostring".ptr);
    lua_pushcfunction(L, &vector_xy_tostring);
    lua_settable(L, -3);

    lua_createtable(L, 0, 1);
    lua_pushstring(L, "xy".ptr);
    lua_pushcfunction(L, &vector_xy_create);
    lua_settable(L, -3);

    lua_setglobal(L, "vector");
}

