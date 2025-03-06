# Instala los roles necesarios para FTP en Windows Server
Install-WindowsFeature -Name Web-Ftp-Server -IncludeManagementTools
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Import-Module WebAdministration

# Solicita los nombres de los grupos
$grupo1 = Read-Host "Ingresa el nombre del primer grupo"
$grupo2 = Read-Host "Ingresa el nombre del segundo grupo"

# Crea la estructura de carpetas para FTP
mkdir C:\FTP
mkdir C:\FTP\General
mkdir C:\FTP\$grupo1
mkdir C:\FTP\$grupo2
mkdir C:\FTP\LocalUser
mkdir C:\FTP\LocalUser\Public

# Crea un enlace simbólico para acceso rápido a la carpeta "General"
cmd /c mklink /D C:\FTP\LocalUser\Public\General C:\FTP\General

# Crea el sitio FTP
New-WebFTPSite -Name FTP -Port 21 -PhysicalPath "C:\FTP"

# Crea los grupos de usuarios
net localgroup "general" /add
net localgroup "$grupo1" /add
net localgroup "$grupo2" /add

# Configura autenticación en el FTP
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value 1
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value 1
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"

# Configura permisos generales en el FTP
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=3} -PSPath IIS:\ -Location "FTP"

# Elimina permisos previos en carpetas específicas
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/General" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$grupo1" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$grupo2" -Filter "system.ftpServer/security/authorization" -Name "."

# Asigna permisos a cada grupo
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=3} -PSPath IIS:\ -Location "FTP/General"
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="general";permissions=3} -PSPath IIS:\ -Location "FTP/General"
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="$grupo1";permissions=3} -PSPath IIS:\ -Location "FTP/$grupo1"
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="$grupo2";permissions=3} -PSPath IIS:\ -Location "FTP/$grupo2"

# Bucle para agregar usuarios
do {
    $nombreUsuario = Read-Host "Ingresa el nombre del usuario"
    
    # Verifica si el usuario ya existe
    $existe = net user $nombreUsuario 2>$null
    if ($existe) {
        Write-Host "El usuario $nombreUsuario ya existe. Intenta con otro nombre." -ForegroundColor Red
        continue
    }

    $contrasenaUsuario = Read-Host "Ingresa la contraseña del usuario" -AsSecureString
    $grupoAsignado = Read-Host "Ingresa el grupo al que pertenece (A: $grupo1 / B: $grupo2)"

    # Crea el usuario
    net user "$nombreUsuario" "$contrasenaUsuario" /add
    net localgroup "general" $nombreUsuario /add

    # Crea las carpetas para el usuario
    mkdir "C:\FTP\$nombreUsuario"
    mkdir "C:\FTP\LocalUser\$nombreUsuario"

    # Enlaces simbólicos a sus carpetas correspondientes
    cmd /c mklink /D "C:\FTP\LocalUser\$nombreUsuario\$nombreUsuario" "C:\FTP\$nombreUsuario"
    cmd /c mklink /D "C:\FTP\LocalUser\$nombreUsuario\General" "C:\FTP\General"

    # Elimina permisos previos en su carpeta
    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$nombreUsuario" -Filter "system.ftpServer/security/authorization" -Name "."

    # Asigna permisos al usuario en su carpeta
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="$nombreUsuario";permissions=3} -PSPath IIS:\ -Location "FTP/$nombreUsuario"
Write-Host "Valor de grupo asignado: '$grupoAsignado'"


    # Asigna el usuario a su grupo correspondiente
    if ($grupoAsignado -eq $grupo1) {
        net localgroup "$grupo1" "$nombreUsuario" /add
        cmd /c mklink /D "C:\FTP\LocalUser\$nombreUsuario\$grupo1" "C:\FTP\$grupo1"
    }
    elseif ($grupoAsignado -eq $grupo2) {
        net localgroup "$grupo2" "$nombreUsuario" /add
        cmd /c mklink /D "C:\FTP\LocalUser\$nombreUsuario\$grupo2" "C:\FTP\$grupo2"
    }
    else {
        Write-Host "Grupo inválido, el usuario no fue asignado a un grupo específico." -ForegroundColor Yellow
    }

    # Pregunta si se desea agregar otro usuario
    $continuar = Read-Host "¿Deseas agregar otro usuario? (s/n)"
} while ($continuar -eq "s")

# Configuración SSL deshabilitada para FTP
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0

# Reinicia el servicio FTP para aplicar cambios
Restart-WebItem "IIS:\Sites\FTP" -Verbose

# Desactiva el firewall en perfiles privado, dominio y público
Set-NetFireWallProfile -Profile Private,Domain,Public -Enabled False

Write-Host "Configuración del servidor FTP finalizada con éxito." -ForegroundColor Green