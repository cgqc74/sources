# Ejecutar como administrador
function Get-DotNetFrameworkVersions {
    Write-Host "=== .NET Framework Installed Versions ==="
    $regKeys = @(
        "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\NET Framework Setup\NDP\v4\Full"
    )
    foreach ($key in $regKeys) {
        if (Test-Path $key) {
            $release = (Get-ItemProperty -Path $key -Name Release -ErrorAction SilentlyContinue).Release
            if ($release) {
                $version = switch ($release) {
                    { $_ -ge 533320 } { "4.8.1" ; break }
                    { $_ -ge 528040 } { "4.8" ; break }
                    { $_ -ge 461808 } { "4.7.2" ; break }
                    { $_ -ge 461308 } { "4.7.1" ; break }
                    { $_ -ge 460798 } { "4.7" ; break }
                    { $_ -ge 394802 } { "4.6.2" ; break }
                    default { "Desconocida (Release: $_)" }
                }
                Write-Host "Versión instalada: $version (Release $release)"
            }
        }
    }
}

function Get-DotNetCoreSDKs {
    Write-Host "`n=== .NET Core / SDK Detected ==="
    $dotnet = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source
    if ($dotnet) {
        & $dotnet --list-sdks
    } else {
        Write-Warning "❌ .NET SDK no detectado en el PATH."
    }
}

function Update-DotNetRuntimes {
    Write-Host "`n🔄 Instalando actualizaciones de .NET Runtime..."

    $downloads = @(
        @{ Name = ".NET 6.0.29" ; Url = "https://download.visualstudio.microsoft.com/download/pr/2a94cce7-bfb7-4b37-9cf4-8b14f8755129/3a4c48f6474bc9269c0c43c9cbad8220/dotnet-runtime-6.0.29-win-x64.exe" },
        @{ Name = ".NET 7.0.18" ; Url = "https://download.visualstudio.microsoft.com/download/pr/b235f18c-9ce6-4ec1-bd0d-5ebf36e3e2d1/9ee148ca80c659ca09e9db46c1bb08e1/dotnet-runtime-7.0.18-win-x64.exe" },
        @{ Name = ".NET 8.0.4"  ; Url = "https://download.visualstudio.microsoft.com/download/pr/fe506e2f-b735-435c-a4ce-3276b960dd80/f1b6e7fda72f3e0dbdb546d2d1f96352/dotnet-runtime-8.0.4-win-x64.exe" }
    )

    foreach ($item in $downloads) {
        $file = "$env:TEMP\$($item.Name).exe"
        Invoke-WebRequest -Uri $item.Url -OutFile $file
        Start-Process -FilePath $file -ArgumentList "/quiet" -Wait
        Remove-Item $file -Force
        Write-Host "✅ $($item.Name) instalado."
    }
}

function Get-PowerShellVersion {
    Write-Host "`n=== PowerShell 7.x Detectado ==="
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        & $pwsh.Source --version
    } else {
        Write-Warning "❌ PowerShell 7 no está instalado."
    }
}

function Update-PowerShell {
    Write-Host "`n🔄 Instalando PowerShell 7.4.2..."

    $url = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi"
    $msi = "$env:TEMP\pwsh-7.4.2.msi"

    Invoke-WebRequest -Uri $url -OutFile $msi
    Start-Process "msiexec.exe" -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait
    Remove-Item $msi -Force
    Write-Host "✅ PowerShell actualizado a 7.4.2"
}

function Get-VisualStudioVersion {
    Write-Host "`n=== Visual Studio 2022 Detectado ==="
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        & $vswhere -latest -products * -format json | ConvertFrom-Json | ForEach-Object {
            Write-Host "Versión instalada: $($_.displayName) ($($_.installationVersion))"
        }
    } else {
        Write-Warning "❌ vswhere.exe no encontrado. No se pudo detectar Visual Studio."
    }
}

function Prompt-VisualStudioUpdate {
    Write-Host "`n🚨 Si tienes Visual Studio 2022, actualízalo manualmente desde el Installer a 17.4.18 / 17.6.14 / 17.9.6+ según tu versión."
    Start-Process "https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-history"
}

# 🛠️ EJECUCIÓN PRINCIPAL
Get-DotNetFrameworkVersions
Get-DotNetCoreSDKs
Get-PowerShellVersion
Get-VisualStudioVersion

$response = Read-Host "`n¿Deseas instalar actualizaciones seguras para .NET y PowerShell? (s/n)"
if ($response -eq "s") {
    Update-DotNetRuntimes
    Update-PowerShell
    Prompt-VisualStudioUpdate
} else {
    Write-Host "⏹️ Proceso cancelado por el usuario."
}
