module graphy.GraphyMain;

import cairo.cairo;

import graphy.platform.Platform;
import graphy.platform.Window;

void graphyMain(char[] exe, char[][] args, Platform platform)
{
    cairo_load();

    void paint(cairo_t* cr, cairo_surface_t* surface)
    {
        cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);
        cairo_paint(cr);
    }

    auto wnd = platform.openWindow;
    wnd.setTitle("Graphy");
    wnd.setOnDraw(&paint);
    wnd.setVisible(true);

    while( platform.pumpMessage )
        {}
}

