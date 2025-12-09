@echo off
REM Installation script for Windows

echo ========================================
echo Installing t - Translation Tool
echo ========================================
echo.

REM Run build script
call build.bat
if errorlevel 1 (
    echo.
    echo Installation failed!
    exit /b 1
)

echo.
echo ========================================
echo Installation complete!
echo ========================================
echo.
echo To use t globally, add this directory to your PATH:
echo   1. Press Win + X and select "System"
echo   2. Click "Advanced system settings"
echo   3. Click "Environment Variables"
echo   4. Under "User variables", select "Path" and click "Edit"
echo   5. Click "New" and add: %CD%
echo   6. Click "OK" to save
echo.
echo Or run t.exe from this directory: %CD%\t.exe
echo.
echo Quick start:
echo   t.exe --help
echo   t.exe "Hello" --to=zh
echo.
