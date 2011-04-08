module graphy.platform.win32.Util;

import tango.stdc.stringz : toString16z;
import tango.sys.win32.Types : DWORD;
import tango.sys.win32.UserGdi : GetLastError;
import tango.text.convert.Utf : toString16;
import tango.util.Convert : to;

struct ToLPTSTR(uint BufferSize = 64)
{
    wchar[BufferSize] buffer;

    wchar* opCall(char[] s)
    {
        auto s16 = toString16(s, buffer);

        if( s16.ptr == buffer.ptr && s16.length < buffer.length )
        {
            buffer[s16.length] = '\0';
            return s16.ptr;
        }
        else
            return toString16z(s16);
    }
}

struct ToLPCTSTR(uint BufferSize = 256)
{
    wchar[BufferSize] _buffer;
    wchar[] buffer;
    size_t offset = 0;

    void reset()
    {
        buffer = _buffer;
        offset = 0;
    }

    void append(wchar[] s)
    {
        if( s.ptr is &buffer[offset] )
        {
            // Easy.
            offset += s.length;
            return;
        }

        // Not so easy.  Expand buffer.
        if( buffer[offset..$].length < s.length )
        {
            auto newSize = buffer.length;
            while( newSize < s.length )
                newSize *= 2;

            auto newBuffer = new wchar[](newSize);
            newBuffer[0..offset] = buffer[0..offset];
            buffer = newBuffer;
        }

        // Append string
        buffer[offset..offset+s.length] = s[];
        offset += s.length;
    }

    void opCatAssign(char[] s)
    {
        auto s16 = toString16(s, buffer[offset..$]);
        append(s16);
        append("\0"w);
    }

    void terminate()
    {
        append("\0"w);
    }

    wchar* lpctstr()
    {
        return buffer.ptr;
    }
}

class Win32Exception : Exception
{
    this(DWORD code)
    {
        super("Win32 error "~to!(char[])(code));
    }
}

void chkNZ(int result)
{
    if( result == 0 )
        throw new Win32Exception(GetLastError());
}

void chkZ(int result)
{
    if( result != 0 )
        throw new Win32Exception(GetLastError());
}

void chkFail()
{
    throw new Win32Exception(GetLastError());
}

