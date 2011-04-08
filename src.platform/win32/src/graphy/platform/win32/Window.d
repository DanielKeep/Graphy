module graphy.platform.win32.Window;

import tango.core.Memory : GC;
import tango.stdc.stdlib : malloc, free;
import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;
import Utf = tango.text.convert.Utf;

import cairo.cairo;
import cairo.win32.cairo_win32;

import graphy.platform.Window;
import graphy.platform.win32.Util : ToLPTSTR, chkNZ, chkFail;

// The window class used for all windows we create.
const WndClassName = "GraphyWindow\0"w;

// Default title for graphy windows
const DefaultWndName = "Graphy\0"w;

static this()
{
    WNDCLASSEX clsWnd;
    with( clsWnd )
    {
        cbSize = WNDCLASSEX.sizeof;
        style = 0;
        lpfnWndProc = &wndProc;
        cbClsExtra = 0;
        cbWndExtra = (WndExtra*).sizeof;
        hInstance = cast(HINSTANCE) GetModuleHandleW(null);
        hIcon = LoadIconA(null, IDI_APPLICATION);
        hCursor = LoadCursorA(null, IDC_ARROW);
        hbrBackground = cast(HBRUSH)(COLOR_BTNFACE+1);
        lpszMenuName = null;
        lpszClassName = WndClassName.ptr;
        hIconSm = LoadIconA(null, IDI_APPLICATION);
    }

    chkNZ( RegisterClassExW(&clsWnd) );
}

class Win32Window : Window
{
    HWND hWnd;

    OnDrawCallback onDraw;
    OnCloseCallback onClose;

    this()
    {
        hWnd = CreateWindowExW(
            /*dwExStyle*/       0,
            /*lpClassName*/     WndClassName.ptr,
            /*lpWindowName*/    DefaultWndName.ptr,
            /*dwStyle*/         WS_OVERLAPPEDWINDOW,
            /*x*/               CW_USEDEFAULT,
            /*y*/               CW_USEDEFAULT,
            /*nWidth*/          CW_USEDEFAULT,
            /*nHeight*/         CW_USEDEFAULT,
            /*hWndParent*/      HWND_DESKTOP,
            /*hMenu*/           null,
            /*hInstance*/       cast(HINSTANCE) GetModuleHandleW(null),
            /*lpParam*/         null
        );

        if( hWnd is null )
            chkFail;

        {
            auto wndExtra = WndExtra.create(this);
            WndExtra.storeIn(hWnd, wndExtra);
        }
    }

    LRESULT wndProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
        switch( uMsg )
        {
            case WM_DESTROY:
                if( onClose !is null )
                    onClose();

                PostQuitMessage(0);
                break;

            case WM_PAINT:
                {
                    PAINTSTRUCT ps;
                    auto hDC = BeginPaint(hWnd, &ps);
                    scope(exit) EndPaint(hWnd, &ps);

                    auto csWnd = cairo_win32_surface_create(hDC);
                    auto cr = cairo_create(csWnd);
                    scope(exit) cairo_destroy(cr);

                    if( onDraw !is null )
                        onDraw(cr, csWnd);
                }
                break;

            default:
                return DefWindowProcW(hWnd, uMsg, wParam, lParam);
        }
    }

    override
    void setTitle(char[] title)
    {
        ToLPTSTR!() toLPTSTR;
        auto title16z = toLPTSTR(title);
        SetWindowTextW(hWnd, title16z);
    }

    override
    char[] getTitle()
    {
        wchar[128] _buffer;
        auto buffer = _buffer[];
        auto l = GetWindowTextLengthW(hWnd);
        if( l+1 > buffer.length )
            buffer = new wchar[](l+1);

        auto result = buffer[0 ..
            GetWindowTextW(hWnd, buffer.ptr, buffer.length)];

        if( result.length == 0 )
            chkFail();

        return Utf.toString(result);
    }

    override
    void setSize(int width, int height)
    {
        RECT rect;
        chkNZ( GetWindowRect(hWnd, &rect) );
        chkNZ( MoveWindow(hWnd, rect.left, rect.top, width, height, TRUE) );
    }

    override
    void getSize(out int width, out int height)
    {
        RECT rect;
        chkNZ( GetWindowRect(hWnd, &rect) );
        width = rect.right-rect.left;
        height = rect.bottom-rect.top;
    }

    override
    void setVisible(bool visible)
    {
        ShowWindow(hWnd, visible ? SW_SHOW : SW_HIDE);
        if( visible )
            UpdateWindow(hWnd);
    }

    override
    bool getVisible()
    {
        WINDOWPLACEMENT wndpl;
        chkNZ( GetWindowPlacement(hWnd, &wndpl) );
        return wndpl.showCmd != SW_HIDE;
    }

    void setOnDraw(OnDrawCallback onDraw)
    {
        this.onDraw = onDraw;
    }

    OnDrawCallback getOnDraw()
    {
        return onDraw;
    }

    void setOnClose(OnCloseCallback onClose)
    {
        this.onClose = onClose;
    }

    OnCloseCallback getOnClose()
    {
        return onClose;
    }
}

struct WndExtra
{
    const char[8] Tag = "WndExtr";

    char[8] tag = Tag;
    Win32Window obj;

    static
    WndExtra* create(Win32Window obj)
    {
        auto r = cast(WndExtra*) malloc(WndExtra.sizeof);
        *r = WndExtra.init;
        r.obj = obj;

        GC.addRange(r, (*r).sizeof);
        return r;
    }

    static
    void destroy(WndExtra* wndExtra)
    {
        GC.removeRange(wndExtra);
        free(wndExtra);
    }

    static
    void storeIn(HWND hWnd, WndExtra* wndExtra)
    {
        SetWindowLongW(hWnd, 0, cast(LONG) wndExtra);
    }

    static
    WndExtra* readFrom(HWND hWnd)
    {
        return cast(WndExtra*) GetWindowLongW(hWnd, 0);
    }
}

extern(Windows)
LRESULT wndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    auto wndExtra = WndExtra.readFrom(hWnd);
    // wndExtra will be NULL when we're first invoked because wndProc gets
    // called when the window is created, before we've had a chance to
    // associate the Window object.  In that case, just let the default
    // handler do its thing.
    if( wndExtra is null )
        return DefWindowProcW(hWnd, uMsg, wParam, lParam);

    // Double-check that the struct is what we expect it to be.
    assert( wndExtra.tag == WndExtra.Tag, "invalid window tag" );

    // Forward to the Win32Window object.
    return wndExtra.obj.wndProc(uMsg, wParam, lParam);
}

