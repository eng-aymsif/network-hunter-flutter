@echo off
chcp 65001 >nul
title Network Hunter Pro - Windows Desktop Builder
echo ============================================================================
echo    Network Hunter Pro ^| صائد الشبكة الذكي - تجهيز وبناء نسخة ويندوز (Windows)
echo ============================================================================
echo.

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VS_PATH="

if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        set "VS_PATH=%%i"
    )
)

if "%VS_PATH%"=="" (
    echo [!] أدوات البناء C++ الخاصة بويندوز ^(Visual Studio C++ Build Tools^) غير مثبتة بعد.
    echo [*] جاري تشغيل مثبت Visual Studio 2022 BuildTools تلقائياً...
    echo [*] يرجى الموافقة على نافذة صلاحيات المسؤول ^(UAC - Yes^) عند ظهورها.
    echo.
    if exist "%LOCALAPPDATA%\Temp\WinGet\Microsoft.VisualStudio.2022.BuildTools.17.14.45\vs_BuildTools.exe" (
        "%LOCALAPPDATA%\Temp\WinGet\Microsoft.VisualStudio.2022.BuildTools.17.14.45\vs_BuildTools.exe" --passive --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended
    ) else (
        winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" --accept-package-agreements --accept-source-agreements
    )
) else (
    echo [✓] تم العثور على أدوات البناء C++ في:
    echo     %VS_PATH%
)

echo.
echo [*] جاري استخراج وبناء نسخة ويندوز النهائية ^(flutter build windows --release^)...
call flutter config --enable-windows-desktop
call flutter build windows --release

if exist "build\windows\x64\runner\Release\networking.exe" (
    echo.
    echo [✓] اكتمل بناء نسخة ويندوز بنجاح!
    echo [✓] المسار: build\windows\x64\runner\Release\networking.exe
    explorer.exe "build\windows\x64\runner\Release"
) else (
    echo.
    echo [!] لم يكتمل بناء ملف .exe بعد. تأكد من اكتمال تثبيت Visual Studio C++ Build Tools ثم أعد تشغيل هذا الملف.
)
pause
