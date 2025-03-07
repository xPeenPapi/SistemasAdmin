Import-Module WebAdministration

# Función para crear el sitio FTP
function Crear-SitioFTP {
    param (
        [string]$SitioFTPName = "SFTPSiteName",
        [string]$FTPRootDir = "C:\FTP",
        [int]$Puerto = 21
    )

    if (-not (Get-WebSite -Name $SitioFTPName -ErrorAction SilentlyContinue)) {
        New-WebSite -Name $SitioFTPName -PhysicalPath $FTPRootDir -Port $Puerto -Force
        Write-Host "Sitio FTP '$SitioFTPName' creado en '$FTPRootDir'."
    } else {
        Write-Host "El sitio FTP '$SitioFTPName' ya existe."
    }
}

# Función para obtener el objeto ADSI
function Get-ADSI {
    return [ADSI]"WinNT://$env:ComputerName"
}

# Función para crear el grupo FTP
function Crear-GrupoFTP {
    param (
        [string]$GrupoFTP = "SFTPUserGroupName",
        [string]$descripcion = "Los usuarios del grupo se pueden conectar por FTP"
    )

    # Verificar si el grupo ya existe
    if (-not (Get-LocalGroup -Name $GrupoFTP -ErrorAction SilentlyContinue)) {
        $ADSI = Get-ADSI
        $FTPUserGroup = $ADSI.Create("Group", "$GrupoFTP")
        $FTPUserGroup.SetInfo()
        $FTPUserGroup.Description = $descripcion
        $FTPUserGroup.SetInfo()
        Write-Host "Grupo '$GrupoFTP' creado."
    } else {
        Write-Host "El grupo '$GrupoFTP' ya existe."
    }
}

# Función para configurar autenticación y autorización
function Configurar-AutenticacionYAutorizacion {
    param (
        [string]$SitioFTPName = "SFTPSiteName",
        [string]$GrupoFTP = "SFTPUserGroupName"
    )

    # Verificar si el sitio FTP existe
    $SFTPSitePath = "IIS:\Sites\$SitioFTPName"
    if (-not (Test-Path $SFTPSitePath)) {
        Write-Host "El sitio FTP '$SitioFTPName' no existe en IIS."
        return
    }

    # Habilitar autenticación básica
    $BasicAuth = "ftpServer.security.authentication.basicAuthentication.enabled"
    Set-ItemProperty -Path $SFTPSitePath -Name $BasicAuth -Value $True
    Write-Host "Autenticación habilitada para el sitio FTP '$SitioFTPName'."

    # Verificar si la regla de autorización ya existe
    $reglas = Get-WebConfiguration -Filter "/system.ftpServer/security/authorization" -PSPath "IIS:\" -Location $SitioFTPName
    $reglaExistente = $reglas | Where-Object { $_.roles -eq $GrupoFTP }

    if (-not $reglaExistente) {
        # Agregar regla de autorización para el grupo FTP
        $Param = @{
            Filter = "/system.ftpServer/security/authorization"
            Value = @{
                accessType = "Allow"
                roles = "$GrupoFTP"
                permissions = 1  # 1 = Lectura, 2 = Escritura, 3 = Lectura y Escritura
            }
            PSPath = "IIS:\"
            Location = $SitioFTPName
        }
        Add-WebConfiguration @Param
        Write-Host "Regla de autorización agregada para el grupo '$GrupoFTP' en el sitio FTP '$SitioFTPName'."
    } else {
        Write-Host "La regla de autorización para el grupo '$GrupoFTP' ya existe."
    }
}

# Función para configurar políticas SSL
function Configurar-PoliticasSSL {
    param (
        [string]$SitioFTPName = "SFTPSiteName"
    )

    # Verificar si el sitio FTP existe
    $FTPSitePath = "IIS:\Sites\$SitioFTPName"
    if (-not (Test-Path $FTPSitePath)) {
        Write-Host "El sitio FTP '$SitioFTPName' no existe en IIS."
        return
    }

    # Configurar políticas SSL
    $SSLPolicy = @(
        "ftpServer.security.ssl.controlChannelPolicy",
        "ftpServer.security.ssl.dataChannelPolicy"
    )

    try {
        Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[0] -Value $false -ErrorAction Stop
        Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[0] -Value $false -ErrorAction Stop
        Write-Host "Políticas SSL configuradas para permitir conexiones SSL en el sitio FTP '$SitioFTPName'."
    } catch {
        Write-Host "Error al configurar las políticas SSL: $_"
    }
}

# Función para configurar permisos NTFS y reiniciar el sitio FTP
function Configurar-PermisosNTFSyReiniciarFTP {
    param (
        [string]$FTPRootDir = "C:\FTP",
        [string]$FTPUserGroupName = "SFTPUserGroupName",
        [string]$FTPSiteName = "SFTPSiteName"
    )

    # Crear una regla de acceso para el grupo
    $UserAccount = New-Object System.Security.Principal.NTAccount("$FTPUserGroupName")
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $UserAccount,
        'ReadAndExecute',  # Permisos de lectura y ejecución
        'ContainerInherit,ObjectInherit',  # Heredar a subcarpetas y archivos
        'None',  # No propagar
        'Allow'  # Tipo de permiso (Permitir)
    )

    # Obtener la ACL (Lista de Control de Acceso) del directorio raíz del FTP
    $ACL = Get-Acl -Path $FTPRootDir

    # Agregar la regla de acceso a la ACL
    $ACL.SetAccessRule($AccessRule)

    # Aplicar la ACL actualizada al directorio raíz del FTP
    $ACL | Set-Acl -Path $FTPRootDir

    Write-Host "Permisos NTFS configurados para el grupo '$FTPUserGroupName' en el directorio '$FTPRootDir'."

    # Reiniciar el sitio FTP para aplicar los cambios
    Restart-WebItem "IIS:\Sites\$FTPSiteName" -Verbose
    Write-Host "Sitio FTP '$FTPSiteName' reiniciado."
}

# Crear el sitio FTP si no existe
Crear-SitioFTP

# Crear el grupo FTP si no existe
Crear-GrupoFTP

# Configurar autenticación y autorización
Configurar-AutenticacionYAutorizacion -SitioFTPName "SFTPSiteName" -GrupoFTP "SFTPUserGroupName"

# Configurar políticas SSL
Configurar-PoliticasSSL -SitioFTPName "SFTPSiteName"

# Configurar permisos NTFS y reiniciar el sitio FTP
Configurar-PermisosNTFSyReiniciarFTP -FTPRootDir "C:\FTP" -FTPUserGroupName "SFTPUserGroupName" -FTPSiteName "SFTPSiteName"

# Menú interactivo
while ($true) {
    Write-Host "Seleccione una opción:"
    Write-Host "1. Verificar instalación del FTP"
    Write-Host "2. Crear los grupos reprobados y recursadores"
    Write-Host "3. Crear un usuario"
    Write-Host "4. Asignar un usuario a un grupo"
    Write-Host "5. Cambiar un usuario de grupo"
    Write-Host "6. Salir"
    $opcion = Read-Host "Opción"

    switch ($opcion) {
        1 { verificar_instalacion }
        2 { crear_grupos }
        3 { crear_usuario }
        4 { asignar_grupo }
        5 { cambiar_grupo }
        6 {
            Write-Host "Saliendo..."
            break
        }
        default {
            Write-Host "Opción no válida. Intente de nuevo."
        }
    }
}