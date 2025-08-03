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
                Write-Host "Versión .NET Framework instalada: $version (Release $release)"
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

function Install-IfAvailable {
    param (
        [string]$Name,
        [string]$Url
    )
    $file = "$env:TEMP\$($Name.Replace(' ', '_')).exe"
    
    Write-Host "`n▶ Verificando disponibilidad de $Name..."
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "⬇️ Descargando $Name..."
            Invoke-WebRequest -Uri $Url -OutFile $file -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop

            Write-Host "🛠️ Instalando $Name..."
            Start-Process -FilePath $file -ArgumentList "/quiet" -Wait
            Remove-Item $file -Force
            Write-Host "✅ Instalación de $Name completada."
        }
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.Value__
        }

        $errorMessage = $_.Exception.Message
        Write-Warning "❌ No se pudo descargar o instalar $Name"
        Write-Warning "   Motivo: $errorMessage"

        if ($statusCode -in 502, 504) {
            Write-Error "🚫 Error tipo Gateway ($statusCode): El servidor no respondió correctamente. Intenta más tarde o revisa tu conexión."
        }
    }
}

function Update-DotNetRuntimes {
    Write-Host "`n=== Actualizando .NET Runtimes a versiones seguras ==="

    $downloads = @(
        @{ Name = ".NET 6.0.29 Runtime"; Url = "https://builds.dotnet.microsoft.com/dotnet/Runtime/6.0.29/dotnet-runtime-6.0.29-win-x64.exe" },
        @{ Name = ".NET 7.0.18 Runtime"; Url = "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/7.0.18/windowsdesktop-runtime-7.0.18-win-x64.exe" },
        @{ Name = ".NET 8.0.4 Runtime" ; Url = "https://builds.dotnet.microsoft.com/dotnet/Runtime/8.0.4/dotnet-runtime-8.0.4-win-x64.exe" }
    )

    foreach ($item in $downloads) {
        Install-IfAvailable -Name $item.Name -Url $item.Url
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
    Write-Host "`n=== Instalando PowerShell 7.5.2 ==="
    $url = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.msi"
    $msi = "$env:TEMP\pwsh-7.5.2.msi"
    try {
        Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing -TimeoutSec 60
        Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait
        Remove-Item $msi -Force
        Write-Host "✅ PowerShell actualizado a 7.5.2"
    } catch {
        Write-Warning "❌ Error al actualizar PowerShell: $($_.Exception.Message)"
    }
}

function Get-VisualStudioVersion {
    Write-Host "`n=== Visual Studio 2022 Detectado ==="
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        & $vswhere -latest -products * -format json | ConvertFrom-Json | ForEach-Object {
            Write-Host "Visual Studio: $($_.displayName) ($($_.installationVersion))"
        }
    } else {
        Write-Warning "❌ vswhere.exe no encontrado. No se detectó Visual Studio."
    }
}

function Prompt-VisualStudioUpdate {
    Write-Host "`n🚨 Para actualizar Visual Studio 2022 manualmente visita:"
    Start-Process "https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-history"
}

# 🛠️ EJECUCIÓN PRINCIPAL
Get-DotNetFrameworkVersions
Get-DotNetCoreSDKs
Get-PowerShellVersion
Get-VisualStudioVersion

$response = Read-Host "`n¿Deseas instalar las actualizaciones disponibles? (s/n)"
if ($response -eq "s") {
    Update-DotNetRuntimes
    Update-PowerShell
    Prompt-VisualStudioUpdate
} else {
    Write-Host "⏹️ Proceso cancelado por el usuario."
}

