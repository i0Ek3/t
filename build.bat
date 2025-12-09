@echo off
REM Build script for Windows

echo Building t.exe...
echo.

REM Install dependencies
echo Installing dependencies...
mix deps.get
if errorlevel 1 (
    echo Error: Failed to install dependencies
    exit /b 1
)

echo.
echo Building executable...
mix escript.build
if errorlevel 1 (
    echo Error: Failed to build executable
    exit /b 1
)

echo.
echo ========================================
echo Build complete!
echo Executable: t.exe
echo ========================================
echo.
echo Run: t.exe --help
echo.
