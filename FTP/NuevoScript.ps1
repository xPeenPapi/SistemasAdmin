function Crear-SitioFTP {
    $FTPSiteName = "FTP"
    $FTPRootDir = "C:\FTP"
    $FTPPort = 21

    New-WebSite -Name $FTPSiteName -Port $FTPPort -PhysicalPath $FTPRootDir
    Write-Output "Sitio FTP '$FTPSiteName' creado en el puerto $FTPPort con directorio raíz '$FTPRootDir'."
}

function Get-ADSI {
    return [ADSI]"WinNT://$env:ComputerName"
}

function Crear-GrupoFTP {
    $FTPUserGroupName = "FTP Usuarios"
    $Description = "Los usuarios del grupo pueden conectarse a través del FTP"

    $ADSI = Get-ADSI
    $FTPUserGroup = $ADSI.Create("Group", "$FTPUserGroupName")
    $FTPUserGroup.SetInfo()
    $FTPUserGroup.Description = $Description
    $FTPUserGroup.SetInfo()
    Write-Output "Grupo de usuarios FTP '$FTPUserGroupName' creado con descripción '$Description'."
}

function Configurar-FTPSite {
    $FTPSiteName = "FTP"
    $FTPUserGroupName = "FTP Usuarios"

    $FTPSitePath = "IIS:\Sites\$FTPSiteName"
    $BasicAuth = "ftpServer.security.authentication.basicAuthentication.enabled"
    Set-ItemProperty -Path $FTPSitePath -Name $BasicAuth -Value $True

    $Param = @{
        Filter = "/system.ftpServer/security/authorization"
        Value = @{
            accessType = "Allow"
            roles = "$FTPUserGroupName"
            permissions = 1  # 1 = Lectura, 3 = Lectura y Escritura
        }
        PSPath = "IIS:\"
        Location = $FTPSiteName
    }

    Add-WebConfiguration @Param
    Write-Output "Sitio FTP '$FTPSiteName' configurado con autenticación básica y autorización para el grupo '$FTPUserGroupName'."
}

function Configurar-SSLPolicy {
    $FTPSiteName = "FTP"

    $FTPSitePath = "IIS:\Sites\$FTPSiteName"
    $SSLPolicy = @(
        "ftpServer.security.ssl.controlChannelPolicy",
        "ftpServer.security.ssl.dataChannelPolicy"
    )
    Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[0] -Value $false
    Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[1] -Value $false
    Write-Output "Políticas de SSL deshabilitadas para el sitio FTP '$FTPSiteName'."
}

function ConfigurarPermisosNTFS {
    param (
        [string]$username  # Nombre del usuario que se está creando
    )

    # Directorios
    $FTPRootDir = "C:\FTP"
    $UserHomeDir = "C:\FTP\LocalUser\$username"
    $UserPersonalDir = "$UserHomeDir\$username"

    # Asignar permisos al directorio raíz del FTP para el grupo "FTP Usuarios"
    $GroupAccount = New-Object System.Security.Principal.NTAccount("FTP Usuarios")
    $GroupAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $GroupAccount,
        "ReadAndExecute",  # Permisos de lectura y ejecución
        "ContainerInherit,ObjectInherit",  # Herencia de permisos
        "None",  # Propagación de permisos
        "Allow"  # Tipo de acceso (Allow o Deny)
    )
    $ACL = Get-Acl -Path $FTPRootDir
    $ACL.AddAccessRule($GroupAccessRule)
    Set-Acl -Path $FTPRootDir -AclObject $ACL
    Write-Output "Permisos NTFS configurados para el grupo 'FTP Usuarios' en el directorio '$FTPRootDir'."

    # Asignar permisos a la carpeta personal del usuario
    $UserAccount = New-Object System.Security.Principal.NTAccount("$username")
    $UserAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $UserAccount,
        "FullControl",  # Permisos completos
        "ContainerInherit,ObjectInherit",  # Herencia de permisos
        "None",  # Propagación de permisos
        "Allow"  # Tipo de acceso (Allow o Deny)
    )
    $ACL = Get-Acl -Path $UserPersonalDir
    $ACL.SetAccessRuleProtection($true, $false)  # Deshabilitar la herencia de permisos
    $ACL.AddAccessRule($UserAccessRule)
    Set-Acl -Path $UserPersonalDir -AclObject $ACL
    Write-Output "Permisos NTFS configurados para el usuario '$username' en el directorio '$UserPersonalDir'."

    # Reiniciar el sitio FTP
    Restart-WebItem "IIS:\Sites\FTP" -Verbose
    Write-Output "Sitio FTP reiniciado."
}

function crear_usuario {
    # Solicitar nombre de usuario y contraseña
    $username = Read-Host "Ingrese el nombre de usuario"
    $password = Read-Host "Ingrese la contraseña" -AsSecureString

    # Validar el nombre de usuario
    if ($username.Length -gt 20) {
        Write-Host "Error: El nombre de usuario no puede tener más de 20 caracteres."
        return
    }
    if ($username -match "[^a-zA-Z0-9]") {
        Write-Host "Error: El nombre de usuario no puede contener caracteres especiales o puntos."
        return
    }

    # Validar la contraseña
    $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )
    if ($passwordPlainText.Length -ne 8) {
        Write-Host "Error: La contraseña debe tener exactamente 8 caracteres."
        return
    }

    # Crear el usuario utilizando ADSI
    try {
        $ADSI = [ADSI]"WinNT://$env:COMPUTERNAME"
        $CreateUserFTPUser = $ADSI.Create("User", "$username")
        $CreateUserFTPUser.SetInfo()
        $CreateUserFTPUser.SetPassword("$passwordPlainText")
        $CreateUserFTPUser.SetInfo()
        Write-Host "Usuario '$username' creado."
    } catch {
        Write-Host "Error al crear el usuario '$username': $_"
        return
    }

    # Crear carpetas personales y asignar permisos
    $UserHomeDir = "C:\FTP\LocalUser\$username"
    $UserPublicDir = "$UserHomeDir\publica"
    $UserPersonalDir = "$UserHomeDir\$username"

    try {
        # Crear carpeta compartida pública si no existe
        if (-not (Test-Path "C:\FTP\publica")) {
            New-Item -ItemType Directory -Path "C:\FTP\publica" -ErrorAction Stop
        }

        # Crear carpeta principal del usuario
        New-Item -ItemType Directory -Path $UserHomeDir -ErrorAction Stop

        # Crear carpeta personal del usuario
        New-Item -ItemType Directory -Path $UserPersonalDir -ErrorAction Stop

        # Asignar permisos exclusivos a la carpeta personal
        $Acl = Get-Acl $UserPersonalDir
        $Acl.SetAccessRuleProtection($true, $false)
        $Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$username", "FullControl", "Allow")))
        $Acl | Set-Acl $UserPersonalDir

        # Crear enlace simbólico para la carpeta pública
        New-Item -ItemType Junction -Path $UserPublicDir -Target "C:\FTP\publica" -ErrorAction Stop

        Write-Host "Carpetas personales creadas y permisos asignados para el usuario '$username'."
    } catch {
        Write-Host "Error al crear carpetas o asignar permisos para el usuario '$username': $_"
    }
}
function mostrar_menu {
    Clear-Host
    Write-Host "===================================="
    Write-Host "          Menú Principal           "
    Write-Host "===================================="
    Write-Host "1. Crear un nuevo usuario FTP"
    Write-Host "2. Listar usuarios FTP"
    Write-Host "3. Salir"
    Write-Host "===================================="
}



# Ejemplo de uso:
Crear-SitioFTP
Crear-GrupoFTP
Configurar-FTPSite
Configurar-SSLPolicy
ConfigurarPermisosNTFS

do {
    mostrar_menu
    $opcion = Read-Host "Seleccione una opción (1-4)"

    switch ($opcion) {
        1 { crear_usuario }
        2 { Write-Host "Saliendo del menú..."; break }
        default { Write-Host "Opción no válida. Intente nuevamente." }
    }

    if ($opcion -ne 4) {
        Write-Host "Presione Enter para continuar..."
        Read-Host
    }
} while ($opcion -ne 4)