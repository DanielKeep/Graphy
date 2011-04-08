module graphy.platform.Platform;

import graphy.platform.Window;

interface Platform
{
    enum MsgBoxType
    {
        Ok,
        OkCancel,
        YesNo,
        YesNoCancel,
    }

    enum MsgBoxIcon
    {
        Information,
        Warning,
        Error,
    }

    enum MsgBoxResponse
    {
        Ok,
        Cancel,
        Yes,
        No,
    }

    MsgBoxResponse msgBox(Window owner, char[], char[], MsgBoxType,
            MsgBoxIcon);

    struct FileDialog
    {
        Window owner;
        char[][2][] filters;
        size_t initialFilter = 0;
        char[] path;
        char[] title;
        char[] initialDir;
        bool changeCwd = true;
    }

    char[] openFileOpenDialog(FileDialog arg);
    char[] openFileSaveDialog(FileDialog arg);

    Window openWindow();
    bool pumpMessage();
}

