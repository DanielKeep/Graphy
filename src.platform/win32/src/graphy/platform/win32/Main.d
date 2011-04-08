module graphy.platform.win32.Main;

import cairo.win32.cairo_win32;

import graphy.lua.Lua;
import graphy.platform.Platform;
import graphy.platform.Window;
import graphy.platform.win32.Platform;
import graphy.GraphyMain;

int main(char[][] args)
{
    cairo_win32_load();

    auto platform = cast(Platform) new Win32Platform;
    graphyMain(args[0], args[1..$], platform);

    return 0;
}

