module graphy.platform.win32.Platform;

import tango.stdc.stringz : fromString16z;
import tango.sys.Environment;
import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;
import tango.text.convert.Utf : toString;

import graphy.platform.Platform;
import graphy.platform.Window;
import graphy.platform.win32.Window;
import graphy.platform.win32.Util : ToLPTSTR, ToLPCTSTR, chkNZ;

pragma(lib, "comdlg32");

class Win32Platform : Platform
{
    override
    MsgBoxResponse msgBox(Window genOwner, char[] title,
            char[] message, MsgBoxType type, MsgBoxIcon icon)
    {
        ToLPTSTR!()[2] toLPTSTR;

        auto owner = cast(Win32Window) genOwner;
        assert( owner !is null );

        auto hWnd = (owner !is null ? owner.hWnd : HWND.init);
        auto lpText = toLPTSTR[0](message);
        auto lpCaption = toLPTSTR[1](message);
        auto uType = UINT.init;

        switch( type )
        {
            case MsgBoxType.Ok:             uType |= MB_OK; break;
            case MsgBoxType.OkCancel:       uType |= MB_OKCANCEL; break;
            case MsgBoxType.YesNo:          uType |= MB_YESNO; break;
            case MsgBoxType.YesNoCancel:    uType |= MB_YESNOCANCEL; break;

            default:
                assert(false);
        }

        switch( icon )
        {
            case MsgBoxIcon.Information:    uType |= MB_ICONINFORMATION; break;
            case MsgBoxIcon.Warning:        uType |= MB_ICONWARNING; break;
            case MsgBoxIcon.Error:          uType |= MB_ICONERROR; break;

            default:
                assert(false);
        }

        auto button = MessageBoxW(hWnd, lpText, lpCaption, uType);
        MsgBoxResponse resp;

        switch( button )
        {
            case IDOK:      resp = MsgBoxResponse.Ok; break;
            case IDCANCEL:  resp = MsgBoxResponse.Cancel; break;
            case IDYES:     resp = MsgBoxResponse.Yes; break;
            case IDNO:      resp = MsgBoxResponse.No; break;

            default:
                assert(false);
        }

        return resp;
    }

    override
    char[] openFileOpenDialog(FileDialog arg)
    {
        // Generate filter string
        ToLPCTSTR!() bufFilter;
        foreach( pair ; arg.filters )
        {
            bufFilter ~= pair[0];
            bufFilter ~= pair[1];
        }
        bufFilter.terminate;

        // Buffer for the default file path.  Note that we use a larger buffer
        // here because this is ALSO where the result will be written to.
        ToLPTSTR!(256) bufFile;

        // Other buffers
        ToLPTSTR!() bufInitialDir, bufTitle;

        // Save/restore current working directory.
        auto cwd = Environment.cwd;
        scope(success)
            if( ! arg.changeCwd )
                Environment.cwd = cwd;

        auto w32owner = cast(Win32Window) arg.owner;
        assert( w32owner !is null );

        OPENFILENAME ofn;
        with( ofn )
        {
            lStructSize = ofn.sizeof;
            hwndOwner = (w32owner !is null ? w32owner.hWnd : HWND.init);
            hInstance = cast(HINSTANCE) GetModuleHandleW(null);

            lpstrFilter = bufFilter.lpctstr;
            nFilterIndex = arg.initialFilter;
            lpstrFile = bufFile(arg.path);
            nMaxFile = bufFile.buffer.length;
            lpstrInitialDir = (arg.initialDir != ""
                    ? bufInitialDir(arg.initialDir)
                    : null);
            lpstrTitle = (arg.title != ""
                    ? bufTitle(arg.title)
                    : null);
            Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;

            /*
            lpstrCustomFilter = null;
            nMaxCustFilter = 0;
            lpstrFileTitle = null;
            nMaxFileTitle = 0;
            nFileOffset = 0;
            nFileExtension = 0;
            lpstrDefExt = null; // NB: only allows max. of 3 characters
            lCustData = 0;
            lpfnHook = null;
            lpTemplateName = null;
            pvReserved = null;
            dwReserved = 0;
            FlagsEx = 0;
            */
        }

        if( GetOpenFileNameW(&ofn) )
            return .toString(fromString16z(ofn.lpstrFile));

        else
            // TODO: throw if an actual error occurred as opposed to the user
            // just cancelling the dialog.
            return null;
    }

    override
    char[] openFileSaveDialog(FileDialog arg)
    {
        // Generate filter string
        ToLPCTSTR!() bufFilter;
        foreach( pair ; arg.filters )
        {
            bufFilter ~= pair[0];
            bufFilter ~= pair[1];
        }
        bufFilter.terminate;

        // Buffer for the file path.
        ToLPTSTR!(256) bufFile;

        // Other buffers
        ToLPTSTR!() bufInitialDir, bufTitle;

        // Save/restore current working directory.
        auto cwd = Environment.cwd;
        scope(success)
            if( ! arg.changeCwd )
                Environment.cwd = cwd;

        auto w32owner = cast(Win32Window) arg.owner;
        assert( w32owner !is null );

        OPENFILENAME ofn;
        with( ofn )
        {
            lStructSize = ofn.sizeof;
            hwndOwner = (w32owner !is null ? w32owner.hWnd : HWND.init);
            hInstance = cast(HINSTANCE) GetModuleHandleW(null);

            lpstrFilter = bufFilter.lpctstr;
            nFilterIndex = arg.initialFilter;
            lpstrFile = bufFile(arg.path);
            nMaxFile = bufFile.buffer.length;
            lpstrInitialDir = (arg.initialDir != ""
                    ? bufInitialDir(arg.initialDir)
                    : null);
            lpstrTitle = (arg.title != ""
                    ? bufTitle(arg.title)
                    : null);
            Flags = OFN_OVERWRITEPROMPT;

            /*
            lpstrCustomFilter = null;
            nMaxCustFilter = 0;
            lpstrFileTitle = null;
            nMaxFileTitle = 0;
            nFileOffset = 0;
            nFileExtension = 0;
            lpstrDefExt = null; // NB: only allows max. of 3 characters
            lCustData = 0;
            lpfnHook = null;
            lpTemplateName = null;
            pvReserved = null;
            dwReserved = 0;
            FlagsEx = 0;
            */
        }

        if( GetSaveFileNameW(&ofn) )
            return .toString(fromString16z(ofn.lpstrFile));

        else
            // TODO: throw if an actual error occurred as opposed to the user
            // just cancelling the dialog.
            return null;
    }

    override
    Window openWindow()
    {
        return new Win32Window;
    }

    override
    bool pumpMessage()
    {
        MSG msg;
        if( GetMessageW(&msg, null, 0, 0) )
        {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
            return true;
        }
        else
            return false;
    }
}

