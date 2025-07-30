$capability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($capability.State -eq 'Installed') {
    $versionOutput = & "$env:ProgramFiles\OpenSSH\ssh.exe" -V 2>&1
    if ($versionOutput -match 'OpenSSH_([\d\.]+)') {
        $version = $Matches[1]
        Write-Host "🔍 OpenSSH detectado: versión $version"

        if ([version]$version -lt [version]"9.6") {
            Write-Warning "⚠️ Versión vulnerable detectada (CVE-2024-9143)"
            $confirm = Read-Host "¿Deseas desinstalar OpenSSH Server ahora? (s/n)"
            if ($confirm -eq 's') {
                Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
                Write-Host "✅ OpenSSH Server desinstalado."
            }
        } else {
            Write-Host "✅ Versión segura de OpenSSH."
        }
    } else {
        Write-Warning "No se pudo detectar la versión de OpenSSH."
    }
} else {
    Write-Host "✔️ OpenSSH Server no está instalado."
}
