@ECHO OFF
CALL dmdenv 1.057-tango-0.99.9

SET ARGS=
SET ARGS_DBG=
SET ARGS_REL=
SET ARGS=%ARGS% -g
SET ARGS=%ARGS% -I..\src
SET ARGS_REL=%ARGS% +D.xf\rdeps +O.xf\robjs
SET ARGS_DBG=%ARGS% +D.xf\ddeps +O.xf\dobjs
SET ARGS=%ARGS% -version=LuaJIT

SET ARGS_REL=%ARGS% -L/SU:WINDOWS
SET ARGS=%ARGS% -I..\src.platform\win32\src
SET ARGS=%ARGS% ..\src.platform\win32\src\graphy\platform\win32\Main.d
SET ARGS=%ARGS% ..\src.platform\win32\lib\lua51.lib
COPY ..\src.platform\win32\dist\*.* ..\bin\

ECHO graphy.exe
xfbuild %ARGS% %ARGS_REL% +o..\bin\graphy.exe

ECHO graphy-dbg.exe
xfbuild %ARGS% %ARGS_DBG% -debug +o..\bin\graphy-dbg.exe

