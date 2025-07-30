# Script para detectar versiones de .NET y actualizar las vulnerables (CVE-2024-21409)
# Ejecutar como administrador

function Get-DotNetFrameworkVersions {
    Write-Host "=== .NET Framework Detected ==="
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
    Write-Host "`n=== .NET Core / .NET SDKs Detected ==="
    $dotnet = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source
    if ($dotnet) {
        & $dotnet --list-sdks
    } else {
        Write-Warning ".NET Core/SDK no está instalado o no está en el PATH."
    }
}

function Update-DotNetRuntimes {
    Write-Host "`n=== Instalando actualizaciones recomendadas para .NET ==="

    # URLs oficiales de descarga de Microsoft para versiones actualizadas (puedes ajustar según tus necesidades)
    $downloads = @(
        @{ Name = ".NET 6.0.29" ; Url = "https://download.visualstudio.microsoft.com/download/pr/2a94cce7-bfb7-4b37-9cf4-8b14f8755129/3a4c48f6474bc9269c0c43c9cbad8220/dotnet-runtime-6.0.29-win-x64.exe" },
        @{ Name = ".NET 7.0.18" ; Url = "https://download.visualstudio.microsoft.com/download/pr/b235f18c-9ce6-4ec1-bd0d-5ebf36e3e2d1/9ee148ca80c659ca09e9db46c1bb08e1/dotnet-runtime-7.0.18-win-x64.exe" },
        @{ Name = ".NET 8.0.4"  ; Url = "https://download.visualstudio.microsoft.com/download/pr/fe506e2f-b735-435c-a4ce-3276b960dd80/f1b6e7fda72f3e0dbdb546d2d1f96352/dotnet-runtime-8.0.4-win-x64.exe" }
    )

    foreach ($item in $downloads) {
        $name = $item.Name
        $url = $item.Url
        $file = "$env:TEMP\$name.exe"

        Write-Host "Descargando $name..."
        Invoke-WebRequest -Uri $url -OutFile $file

        Write-Host "Instalando $name..."
        Start-Process -FilePath $file -ArgumentList "/quiet" -Wait
        Remove-Item $file -Force
    }

    Write-Host "✅ Actualizaciones completadas."
}

# Ejecutar funciones
Get-DotNetFrameworkVersions
Get-DotNetCoreSDKs

# Confirmar con el usuario antes de instalar
$response = Read-Host "`n¿Deseas instalar las últimas versiones seguras de .NET Runtime? (s/n)"
if ($response -eq "s") {
    Update-DotNetRuntimes
} else {
    Write-Host "❌ Instalación cancelada por el usuario."
}
