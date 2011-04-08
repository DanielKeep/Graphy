/*

TODO:

* Do error checking.  :P
* Change the way surfaces work.  The __index metamethod should ask cairo what
  kind of surface it has, and adjust what it'll return accordingly.

*/
module graphy.lua.Cairo;

import graphy.lua.Vector : vector_xy, is_vector_xy, checkvector_xy;

import cairo.cairo;
import cairo.png.cairo_png;
import lua.lua;
import lua.lauxlib;

const CONTEXT_TYPE = "cairo_context";
const SURFACE_TYPE = "cairo_surface";
const IMAGE_SURFACE_TYPE = "cairo_image_surface";
const WIN32_SURFACE_TYPE = "cairo_win32_surface";

cairo_t* context_create_push(lua_State* L, cairo_surface_t* target)
{
    auto cr = cast(cairo_t**) lua_newuserdata(L, (void*).sizeof);
    luaL_getmetatable(L, CONTEXT_TYPE.ptr);
    lua_setmetatable(L, -2);

    *cr = cairo_create(target);

    return *cr;
}

cairo_surface_t* image_surface_create_push(lua_State* L,
        cairo_format_t format, int width, int height)
{
    auto surface = cast(cairo_surface_t**) lua_newuserdata(L, (void*).sizeof);
    luaL_getmetatable(L, IMAGE_SURFACE_TYPE.ptr);
    lua_setmetatable(L, -2);

    *surface = cairo_image_surface_create(format, width, height);

    return *surface;
}

cairo_t* checkcontext(lua_State* L, int ud)
{
    return *(cast(cairo_t**) luaL_checkudata(L, ud, CONTEXT_TYPE.ptr));
}

cairo_surface_t* checksurface(lua_State* L, int ud)
{
    auto v = cast(void*) lua_touserdata(L, ud);
    if( v !is null )
    {
        if( lua_getmetatable(L, ud) )
        {
            lua_getfield(L, LUA_REGISTRYINDEX, SURFACE_TYPE.ptr);
            if( lua_rawequal(L, -1, -2) )
            {
                lua_pop(L, 2);
                return *(cast(cairo_surface_t**) v);
            }
            lua_pop(L, 1);
            lua_getfield(L, LUA_REGISTRYINDEX, IMAGE_SURFACE_TYPE.ptr);
            if( lua_rawequal(L, -1, -2) )
            {
                lua_pop(L, 2);
                return *(cast(cairo_surface_t**) v);
            }
            lua_pop(L, 1);
            lua_getfield(L, LUA_REGISTRYINDEX, WIN32_SURFACE_TYPE.ptr);
            if( lua_rawequal(L, -1, -2) )
            {
                lua_pop(L, 2);
                return *(cast(cairo_surface_t**) v);
            }
            lua_pop(L, 1);
        }
    }
    luaL_typerror(L, ud, "surface");
    assert(0);
}

cairo_surface_t* checkimagesurface(lua_State* L, int ud)
{
    auto surface = checksurface(L, ud);
    // TODO: check surface type ID from cairo.
    return surface;
}

cairo_format_t checkformat(lua_State* L, int ud)
{
    // Pull out string argument
    size_t sl;
    char* sz = luaL_checklstring(L, ud, &sl);
    auto s = sz[0..sl];

    // Check that's a valid format.
    switch( s )
    {
        case "argb32":  return cairo_format_t.CAIRO_FORMAT_ARGB32;
        case "rgb24":   return cairo_format_t.CAIRO_FORMAT_RGB24;
        case "a8":      return cairo_format_t.CAIRO_FORMAT_A8;
        case "a1":      return cairo_format_t.CAIRO_FORMAT_A1;
        default:
            luaL_argerror(L, ud, sz);
            assert(0);
    }
    assert(0);
}

extern(C) int context_create(lua_State* L)
{
    auto target = checksurface(L, 1);
    context_create_push(L, target);
    return 1;
}

extern(C) int context_gc(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_destroy(cr);
    return 0;
}

extern(C) int context_set_source_rgb(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    auto r = luaL_checknumber(L, 2);
    auto g = luaL_checknumber(L, 3);
    auto b = luaL_checknumber(L, 4);

    cairo_set_source_rgb(cr, r, g, b);

    return 0;
}

extern(C) int context_move_to(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    if( is_vector_xy(L, 2) )
    {
        auto v = checkvector_xy(L, 2);
        cairo_move_to(cr, v.x, v.y);
    }
    else
    {
        auto x = luaL_checknumber(L, 2);
        auto y = luaL_checknumber(L, 3);
        cairo_move_to(cr, x, y);
    }
    return 0;
}

extern(C) int context_line_to(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    if( is_vector_xy(L, 2) )
    {
        auto v = checkvector_xy(L, 2);
        cairo_line_to(cr, v.x, v.y);
    }
    else
    {
        auto x = luaL_checknumber(L, 2);
        auto y = luaL_checknumber(L, 3);
        cairo_line_to(cr, x, y);
    }
    return 0;
}

extern(C) int context_paint(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_paint(cr);
    return 0;
}

extern(C) int context_stroke(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_stroke(cr);
    return 0;
}

extern(C) int context_stroke_preserve(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_stroke_preserve(cr);
    return 0;
}

extern(C) int context_fill(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_fill(cr);
    return 0;
}

extern(C) int context_fill_preserve(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_fill_preserve(cr);
    return 0;
}

extern(C) int context_translate(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    if( is_vector_xy(L, 2) )
    {
        auto v = checkvector_xy(L, 2);
        cairo_translate(cr, v.x, v.y);
    }
    else
    {
        auto x = luaL_checknumber(L, 2);
        auto y = luaL_checknumber(L, 3);
        cairo_translate(cr, x, y);
    }
    return 0;
}

extern(C) int context_scale(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    if( is_vector_xy(L, 2) )
    {
        auto v = checkvector_xy(L, 2);
        cairo_scale(cr, v.x, v.y);
    }
    else
    {
        auto x = luaL_checknumber(L, 2);
        auto y = luaL_checknumber(L, 3);
        cairo_scale(cr, x, y);
    }
    return 0;
}

extern(C) int context_rotate(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    auto angle = luaL_checknumber(L, 2);
    cairo_rotate(cr, angle);
    return 0;
}

extern(C) int context_save(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_save(cr);
    return 0;
}

extern(C) int context_restore(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_restore(cr);
    return 0;
}

extern(C) int context_identity_matrix(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_identity_matrix(cr);
    return 0;
}

extern(C) int context_close_path(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    cairo_close_path(cr);
    return 0;
}

extern(C) int context_select_font_face(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    size_t sl; auto sz = luaL_checklstring(L, 2, &sl);
    auto family = sz[0..sl];
    // TODO: allow the slant and weight to be specified

    cairo_select_font_face(cr, (family~"\0").ptr,
            cairo_font_slant_t.CAIRO_FONT_SLANT_NORMAL,
            cairo_font_weight_t.CAIRO_FONT_WEIGHT_NORMAL);

    return 0;
}

extern(C) int context_show_text(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    size_t sl; auto sz = luaL_checklstring(L, 2, &sl);
    auto text = sz[0..sl];

    cairo_show_text(cr, (text~"\0").ptr);

    return 0;
}

extern(C) int context_index(lua_State* L)
{
    auto cr = checkcontext(L, 1);
    luaL_checkany(L, 2);

    if( lua_isstring(L, 2) )
    {
        size_t kl; auto kz = luaL_checklstring(L, 2, &kl);
        auto k = kz[0..kl];

        switch( k )
        {
            case "translate":
                lua_pushcfunction(L, &context_translate);
                return 1;

            case "scale":
                lua_pushcfunction(L, &context_scale);
                return 1;

            case "rotate":
                lua_pushcfunction(L, &context_rotate);
                return 1;

            case "save":
                lua_pushcfunction(L, &context_save);
                return 1;

            case "restore":
                lua_pushcfunction(L, &context_restore);
                return 1;

            case "identity_matrix":
                lua_pushcfunction(L, &context_identity_matrix);
                return 1;

            case "close_path":
                lua_pushcfunction(L, &context_close_path);
                return 1;

            case "move_to":
                lua_pushcfunction(L, &context_move_to);
                return 1;

            case "line_to":
                lua_pushcfunction(L, &context_line_to);
                return 1;

            case "paint":
                lua_pushcfunction(L, &context_paint);
                return 1;

            case "set_source_rgb":
                lua_pushcfunction(L, &context_set_source_rgb);
                return 1;

            case "stroke":
                lua_pushcfunction(L, &context_stroke);
                return 1;

            case "stroke_preserve":
                lua_pushcfunction(L, &context_stroke_preserve);
                return 1;

            case "fill":
                lua_pushcfunction(L, &context_fill);
                return 1;

            case "fill_preserve":
                lua_pushcfunction(L, &context_fill_preserve);
                return 1;

            case "select_font_face":
                lua_pushcfunction(L, &context_select_font_face);
                return 1;

            case "show_text":
                lua_pushcfunction(L, &context_show_text);
                return 1;

            default:
        }
    }
    
    lua_pushnil(L);
    return 1;
}

extern(C) int surface_gc(lua_State* L)
{
    auto surface = checksurface(L, 1);
    cairo_surface_destroy(surface);
    return 0;
}

extern(C) int surface_write_to_png(lua_State* L)
{
    auto surface = checksurface(L, 1);
    size_t filenamel; auto filenamez = luaL_checklstring(L, 2, &filenamel);
    auto filename = filenamez[0..filenamel];

    cairo_surface_write_to_png(surface, (filename~"\0").ptr);

    return 0;
}

extern(C) int surface_index(lua_State* L)
{
    auto surface = checksurface(L, 1);
    luaL_checkany(L, 2);

    if( lua_isstring(L, 2) )
    {
        size_t kl; auto kz = luaL_checklstring(L, 2, &kl);
        auto k = kz[0..kl];

        switch( k )
        {
            case "write_to_png":
                lua_pushcfunction(L, &surface_write_to_png);
                return 1;

            default:
        }
    }
    
    lua_pushnil(L);
    return 1;
}

extern(C) int image_surface_create(lua_State* L)
{
    auto format = checkformat(L, 1);
    auto width = luaL_checkinteger(L, 2);
    auto height = luaL_checkinteger(L, 3);
    image_surface_create_push(L, format, width, height);
    return 1;
}

extern(C) int image_surface_index(lua_State* L)
{
    auto surface = checksurface(L, 1);
    luaL_checkany(L, 2);

    if( lua_isstring(L, 2) )
    {
        size_t kl; auto kz = luaL_checklstring(L, 2, &kl);
        auto k = kz[0..kl];

        switch( k )
        {
            default:
        }
    }

    return surface_index(L);
}

version( Windows )
{
    import cairo.win32.cairo_win32;
    import tango.sys.win32.UserGdi : GetDeviceCaps;
    import tango.sys.win32.Types : HDC, HORZRES, VERTRES;

    cairo_surface_t* checkwin32surface(lua_State* L, int ud)
    {
        auto surface = checksurface(L, ud);
        // TODO: check surface type ID from cairo.
        return surface;
    }

    cairo_surface_t* win32_surface_create_push(lua_State* L, HDC hdc)
    {
        auto surface = cast(cairo_surface_t**) lua_newuserdata(L,
                (void*).sizeof);
        luaL_getmetatable(L, WIN32_SURFACE_TYPE.ptr);
        lua_setmetatable(L, -2);

        *surface = cairo_win32_surface_create(hdc);

        return *surface;
    }

    /+
    // TODO: Upgrade cairo binding to include ..._surface_get_dc.
    extern(C) int win32_surface_get_width(lua_State* L, HDC hdc)
    {
        auto surface = checkwin32surface(L, 1);
        auto hdc = cairo_win32_surface_get_dc(surface);
        lua_pushinteger(L, GetDeviceCaps(hcd, HORZRES));
        return 1;
    }

    extern(C) int win32_surface_get_height(lua_State* L, HDC hdc)
    {
        auto surface = checkwin32surface(L, 1);
        auto hdc = cairo_win32_surface_get_dc(surface);
        lua_pushinteger(L, GetDeviceCaps(hcd, VERTRES));
        return 1;
    }
    +/

    extern(C) int win32_surface_index(lua_State* L)
    {
        auto surface = checksurface(L, 1);
        luaL_checkany(L, 2);

        if( lua_isstring(L, 2) )
        {
            size_t kl; auto kz = luaL_checklstring(L, 2, &kl);
            auto k = kz[0..kl];

            switch( k )
            {
                default:
            }
        }

        return surface_index(L);
    }
}

void openlib(lua_State* L)
{
    //
    // Create cairo_context type
    //
    luaL_newmetatable(L, CONTEXT_TYPE.ptr);

    lua_pushstring(L, "tag");
    lua_pushstring(L, CONTEXT_TYPE.ptr);
    lua_settable(L, -3);

    lua_pushstring(L, "__index");
    lua_pushcfunction(L, &context_index);
    lua_settable(L, -3);

    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, &context_gc);
    lua_settable(L, -3);

    //
    // Create cairo_surface type
    //
    luaL_newmetatable(L, SURFACE_TYPE.ptr);

    lua_pushstring(L, "tag");
    lua_pushstring(L, SURFACE_TYPE.ptr);
    lua_settable(L, -3);

    lua_pushstring(L, "__index");
    lua_pushcfunction(L, &surface_index);
    lua_settable(L, -3);

    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, &surface_gc);
    lua_settable(L, -3);

    //
    // Create cairo_image_surface type
    //
    luaL_newmetatable(L, IMAGE_SURFACE_TYPE.ptr);

    lua_pushstring(L, "tag");
    lua_pushstring(L, IMAGE_SURFACE_TYPE.ptr);
    lua_settable(L, -3);

    lua_pushstring(L, "__index");
    lua_pushcfunction(L, &image_surface_index);
    lua_settable(L, -3);

    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, &surface_gc);
    lua_settable(L, -3);

    //
    // Create cairo_win32_surface type
    //
    luaL_newmetatable(L, WIN32_SURFACE_TYPE.ptr);

    lua_pushstring(L, "tag");
    lua_pushstring(L, WIN32_SURFACE_TYPE.ptr);
    lua_settable(L, -3);

    lua_pushstring(L, "__index");
    lua_pushcfunction(L, &win32_surface_index);
    lua_settable(L, -3);

    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, &surface_gc);
    lua_settable(L, -3);

    //
    // Create cairo table
    //
    lua_createtable(L, 0, 2);
    
    // cairo.context
    lua_pushstring(L, "context");
    lua_createtable(L, 0, 1);

    lua_pushstring(L, "create");
    lua_pushcfunction(L, &context_create);
    lua_settable(L, -3);
    
    lua_settable(L, -3);

    // cairo.image_surface
    lua_pushstring(L, "image_surface");
    lua_createtable(L, 0, 1);

    lua_pushstring(L, "create");
    lua_pushcfunction(L, &image_surface_create);
    lua_settable(L, -3);

    lua_settable(L, -3);

    // Fix to global
    lua_setglobal(L, "cairo");
}

