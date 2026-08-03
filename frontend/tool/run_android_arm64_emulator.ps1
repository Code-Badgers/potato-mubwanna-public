[CmdletBinding()]
param(
    [string]$DeviceId = "emulator-5554",
    [string]$EnvFile,
    [string]$FlutterPath,
    [string]$AdbPath
)

$ErrorActionPreference = "Stop"

function Resolve-ToolPath {
    param(
        [string]$ExplicitPath,
        [string]$CommandName,
        [string[]]$FallbackPaths
    )

    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath -PathType Leaf)) {
            throw "$CommandName executable not found: $ExplicitPath"
        }
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($fallbackPath in $FallbackPaths) {
        if ($fallbackPath -and (Test-Path -LiteralPath $fallbackPath -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $fallbackPath).Path
        }
    }

    throw "$CommandName executable not found. Pass its path explicitly."
}

function Import-DotEnv {
    param([string]$Path)

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith("#")) {
            continue
        }
        if ($line.StartsWith("export ")) {
            $line = $line.Substring(7).Trim()
        }

        $separator = $line.IndexOf("=")
        if ($separator -lt 1) {
            continue
        }

        $name = $line.Substring(0, $separator).Trim()
        if ($name -notmatch "^[A-Za-z_][A-Za-z0-9_]*$") {
            throw "Invalid environment variable name in $Path"
        }

        $value = $line.Substring($separator + 1).Trim()
        if ($value.Length -ge 2) {
            $first = $value[0]
            $last = $value[$value.Length - 1]
            if (($first -eq '"' -and $last -eq '"') -or
                ($first -eq "'" -and $last -eq "'")) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }

        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

function Invoke-Checked {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)"
    }
}

$frontendRoot = Split-Path -Parent $PSScriptRoot
if (-not $EnvFile) {
    $EnvFile = Join-Path $frontendRoot ".env"
}
if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf)) {
    throw "Environment file not found: $EnvFile"
}
$EnvFile = (Resolve-Path -LiteralPath $EnvFile).Path

$flutterFallbacks = @(
    "C:\src\flutter\bin\flutter.bat",
    "C:\flutter\bin\flutter.bat"
)
$adbFallbacks = @(
    $(if ($env:LOCALAPPDATA) {
        Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    }),
    "C:\Android\Sdk\platform-tools\adb.exe"
)

$flutter = Resolve-ToolPath $FlutterPath "flutter" $flutterFallbacks
$adb = Resolve-ToolPath $AdbPath "adb" $adbFallbacks
Import-DotEnv $EnvFile

$requiredVariables = @("API_BASE_URL", "KAKAO_NATIVE_APP_KEY")
$missingVariables = @(
    foreach ($variableName in $requiredVariables) {
        if (-not [Environment]::GetEnvironmentVariable($variableName, "Process")) {
            $variableName
        }
    }
)
if ($missingVariables.Count -gt 0) {
    throw "Missing required environment variables: $($missingVariables -join ', ')"
}

$apiBaseUrl = [Environment]::GetEnvironmentVariable("API_BASE_URL", "Process")
$apiUri = $null
if (-not [Uri]::TryCreate($apiBaseUrl, [UriKind]::Absolute, [ref]$apiUri)) {
    throw "API_BASE_URL must be an absolute URL"
}
$usesHostLoopback = $apiUri.Host -in @("localhost", "127.0.0.1", "::1")

$deviceLines = & $adb devices
if ($LASTEXITCODE -ne 0 -or
    -not ($deviceLines | Select-String -SimpleMatch "$DeviceId`tdevice")) {
    throw "Android device is not ready: $DeviceId"
}

$abiList = (& $adb -s $DeviceId shell getprop ro.product.cpu.abilist).Trim()
if ($LASTEXITCODE -ne 0 -or
    -not (($abiList -split ",") -contains "arm64-v8a")) {
    throw "Device $DeviceId does not support arm64-v8a (reported: $abiList)"
}

$apkPath = Join-Path $frontendRoot "build\app\outputs\flutter-apk\app-debug.apk"
$packageName = "com.gamjamubwatna.frontend"
$activityName = "$packageName/.MainActivity"

Push-Location $frontendRoot
try {
    Write-Host "Building the Flutter debug APK for arm64-v8a..."
    Invoke-Checked $flutter @(
        "build",
        "apk",
        "--debug",
        "--target-platform",
        "android-arm64",
        "--dart-define-from-file=$EnvFile"
    ) "Flutter ARM64 build failed"

    if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "ARM64 APK was not created: $apkPath"
    }

    Write-Host "Installing the APK as arm64-v8a while preserving app data..."
    Invoke-Checked $adb @(
        "-s",
        $DeviceId,
        "install",
        "-r",
        "-t",
        "--abi",
        "arm64-v8a",
        $apkPath
    ) "ARM64 APK installation failed"

    $packageDump = & $adb -s $DeviceId shell dumpsys package $packageName
    if ($LASTEXITCODE -ne 0 -or
        -not ($packageDump | Select-String -SimpleMatch "primaryCpuAbi=arm64-v8a")) {
        throw "Installed package did not select arm64-v8a"
    }

    if ($usesHostLoopback) {
        $tcpEndpoint = "tcp:$($apiUri.Port)"
        Write-Host "Connecting emulator localhost port $($apiUri.Port) to the local backend..."
        Invoke-Checked $adb @(
            "-s",
            $DeviceId,
            "reverse",
            $tcpEndpoint,
            $tcpEndpoint
        ) "Failed to connect the emulator to the local backend"
    }

    Invoke-Checked $adb @(
        "-s",
        $DeviceId,
        "shell",
        "am",
        "force-stop",
        $packageName
    ) "Failed to stop the existing app process"
    Invoke-Checked $adb @(
        "-s",
        $DeviceId,
        "shell",
        "am",
        "start",
        "-n",
        $activityName
    ) "Failed to start the ARM64 app"

    Write-Host "ARM64 app started on $DeviceId. Do not overwrite it with a normal x86_64 flutter run."
}
finally {
    Pop-Location
}
