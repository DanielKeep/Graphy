module graphy.platform.Window;

import cairo.cairo : cairo_t, cairo_surface_t;

interface Window
{
    alias void delegate(cairo_t*, cairo_surface_t*) OnDrawCallback;
    alias void delegate() OnCloseCallback;

    void setTitle(char[]);
    char[] getTitle();

    void setSize(int width, int height);
    void getSize(out int width, out int height);

    void setVisible(bool visible);
    bool getVisible();

    void setOnDraw(OnDrawCallback);
    OnDrawCallback getOnDraw();

    void setOnClose(OnCloseCallback);
    OnCloseCallback getOnClose();
}

