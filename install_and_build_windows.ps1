$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "   Network Hunter Pro - Windows Desktop Toolchain & Builder" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vcInstalled = $false

if (Test-Path $vswhere) {
    $vcPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if (-not [string]::IsNullOrWhiteSpace($vcPath)) {
        $vcInstalled = $true
        Write-Host "[OK] Visual Studio C++ Build Tools found at: $vcPath" -ForegroundColor Green
    }
}

if (-not $vcInstalled) {
    Write-Host "[*] Installing Visual Studio 2022 C++ Build Tools (Desktop development with C++)..." -ForegroundColor Yellow
    Write-Host "[*] Please click 'Yes' on the Windows UAC Administrator prompt if shown." -ForegroundColor Yellow

    $cachedInstaller = "$env:LOCALAPPDATA\Temp\WinGet\Microsoft.VisualStudio.2022.BuildTools.17.14.45\vs_BuildTools.exe"
    if (-not (Test-Path $cachedInstaller)) {
        $cachedInstaller = "$env:TEMP\vs_BuildTools.exe"
        Write-Host "[*] Downloading Visual Studio 2022 Build Tools bootstrapper..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_BuildTools.exe" -OutFile $cachedInstaller -UseBasicParsing
    }

    $installArgs = @(
        "--passive",
        "--wait",
        "--norestart",
        "--add", "Microsoft.VisualStudio.Workload.VCTools",
        "--includeRecommended"
    )

    $proc = Start-Process -FilePath $cachedInstaller -ArgumentList $installArgs -Verb RunAs -PassThru -Wait
    Write-Host "[*] Installer exited with code: $($proc.ExitCode)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[*] Ensuring Windows C++ dependencies & offline WIL package are staged..." -ForegroundColor Cyan
$wilSource = Join-Path $PSScriptRoot "windows\packages\Microsoft.Windows.ImplementationLibrary"
$wilTarget = Join-Path $PSScriptRoot "build\windows\x64\packages\Microsoft.Windows.ImplementationLibrary"
if (Test-Path $wilSource) {
    if (-not (Test-Path $wilTarget)) {
        New-Item -ItemType Directory -Path $wilTarget -Force | Out-Null
    }
    Copy-Item -Path "$wilSource\*" -Destination $wilTarget -Recurse -Force
    Write-Host "[OK] Staged Microsoft.Windows.ImplementationLibrary from local repository cache." -ForegroundColor Green
}

# Auto-patch audioplayers_windows CMakeLists.txt in pub-cache if needed
$audioCMake = "$env:PUB_CACHE\hosted\pub.dev\audioplayers_windows-4.4.1\windows\CMakeLists.txt"
if (Test-Path $audioCMake) {
    $cContent = [System.IO.File]::ReadAllText($audioCMake)
    if ($cContent -notmatch "if \(NOT EXISTS `"\$\{CMAKE_BINARY_DIR\}/packages/Microsoft.Windows.ImplementationLibrary") {
        $cContent = $cContent.Replace(
            "execute_process(COMMAND`r`n    `${NUGET} install Microsoft.Windows.ImplementationLibrary",
            "if (NOT EXISTS `"`${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.ImplementationLibrary/build/native/Microsoft.Windows.ImplementationLibrary.targets`")`r`nexecute_process(COMMAND`r`n    `${NUGET} install Microsoft.Windows.ImplementationLibrary"
        )
        $cContent = $cContent.Replace(
            "message(FATAL_ERROR `"Failed to install nuget package Microsoft.Windows.ImplementationLibrary.`${WIL_VERSION}`")`r`nendif()",
            "message(FATAL_ERROR `"Failed to install nuget package Microsoft.Windows.ImplementationLibrary.`${WIL_VERSION}`")`r`nendif()`r`nendif()"
        )
        [System.IO.File]::WriteAllText($audioCMake, $cContent)
        Write-Host "[OK] Patched audioplayers_windows to bypass remote NuGet calls when package is present." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[*] Building Network Hunter Pro for Windows Desktop (flutter build windows --release)..." -ForegroundColor Cyan
Set-Location $PSScriptRoot
& flutter config --enable-windows-desktop
& flutter build windows --release

$exePath = Join-Path $PSScriptRoot "build\windows\x64\runner\Release\networking.exe"
if (Test-Path $exePath) {
    Write-Host ""
    Write-Host "[SUCCESS] Windows Desktop build completed successfully!" -ForegroundColor Green
    Write-Host "[SUCCESS] Output: $exePath" -ForegroundColor Green
    Start-Process "explorer.exe" -ArgumentList "/select,`"$exePath`""
} else {
    Write-Host ""
    Write-Host "[!] Build did not produce networking.exe yet. Please verify C++ Build Tools installation completed." -ForegroundColor Red
}
