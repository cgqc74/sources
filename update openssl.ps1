# Configuración
$SafeVersion = "3.5.1"
$ZipUrl = "https://tu-servidor/openssl-3.0.15.zip"   # ✅ Reemplazar con la URL real del ZIP seguro
$TempZip = "$env:TEMP\openssl-$SafeVersion.zip"
$ExtractDir = "$env:TEMP\openssl_secure_$SafeVersion"
$TargetFiles = @("libssl-3-x64.dll", "libcrypto-3-x64.dll")
$SearchDirs = @("C:\Program Files\", "C:\Program Files (x86)\", "C:\Windows\System32")

## 1. Descargar ZIP con las nuevas DLL
#Write-Host "🔽 Descargando OpenSSL seguro versión $SafeVersion..."
#Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing

# 2. Extraer ZIP
if (Test-Path $ExtractDir) { Remove-Item -Recurse -Force $ExtractDir }
Expand-Archive -Path $TempZip -DestinationPath $ExtractDir
Write-Host "✅ Librerías extraídas en: $ExtractDir"

# 3. Buscar archivos vulnerables en disco
Write-Host "`n🔍 Buscando archivos DLL vulnerables en el sistema..."
foreach ($target in $TargetFiles) {
    $matches = Get-ChildItem -Path $SearchDirs -Recurse -Include $target -ErrorAction SilentlyContinue

    foreach ($file in $matches) {
        Write-Host "`n⚠️ Encontrado: $($file.FullName)"

        # Crear respaldo del archivo
        $backupPath = "$($file.FullName).bak"
        Copy-Item -Path $file.FullName -Destination $backupPath -Force
        Write-Host "🗂️ Backup creado: $backupPath"

        # Reemplazar con versión segura
        $newFile = Join-Path $ExtractDir $target
        if (Test-Path $newFile) {
            Copy-Item -Path $newFile -Destination $file.FullName -Force
            Write-Host "🔄 Reemplazado con la versión segura: $target"
        } else {
            Write-Warning "🚫 No se encontró la nueva DLL para: $target"
        }
    }
}

# 4. Limpieza
Remove-Item $TempZip -Force
Remove-Item -Recurse -Force $ExtractDir

Write-Host "`n✅ Proceso completado. Reinicia cualquier aplicación que use OpenSSL para aplicar los cambios."
