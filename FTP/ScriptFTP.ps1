# Importar módulos necesarios
Import-Module WebAdministration
function Crear-SitioFTP {
    param (
        [string]$SitioFTPName = "SFTPSiteName",
        [string]$FTPRootDir = "C:\FTP",
        [int]$Puerto = 21
    )

    # Verificar si el sitio FTP ya existe
    if (-not (Get-WebSite -Name $SitioFTPName -ErrorAction SilentlyContinue)) {
        # Crear el sitio FTP
        New-WebSite -Name $SitioFTPName -PhysicalPath $FTPRootDir -Port $Puerto -Force
        Write-Host "Sitio FTP '$SitioFTPName' creado en '$FTPRootDir'."
    } else {
        Write-Host "El sitio FTP '$SitioFTPName' ya existe."
    }
}

# Función para crear el grupo FTP
function Crear-GrupoFTP {
    param (
        [string]$GrupoFTP = "SFTPUserGroupName"
    )

    # Verificar si el grupo ya existe
    if (-not (Get-LocalGroup -Name $GrupoFTP -ErrorAction SilentlyContinue)) {
        # Crear el grupo
        New-LocalGroup -Name $GrupoFTP
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

    # Habilitar autenticación básica
    $SFTPSitePath = "IIS:\Sites\$SitioFTPName"
    $BasicAuth = "ftpServer.security.authentication.basicAuthentication.enabled"
    Set-ItemProperty -Path $SFTPSitePath -Name $BasicAuth -Value $True
    Write-Host "Autenticación básica habilitada para el sitio FTP '$SitioFTPName'."

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
}

# Función para configurar políticas SSL
function Configurar-PoliticasSSL {
    param (
        [string]$SitioFTPName = "SFTPSiteName"
    )

    # Ruta del sitio FTP
    $FTPSitePath = "IIS:\Sites\$SitioFTPName"

    # Configurar políticas SSL
    $SSLPolicy = @(
        "ftpServer.security.ssl.controlChannelPolicy",
        "ftpServer.security.ssl.dataChannelPolicy"
    )

    Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[0] -Value $false
    Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[1] -Value $false

    Write-Host "Políticas SSL configuradas para permitir conexiones SSL en el sitio FTP '$SitioFTPName'."
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


# Función para verificar la instalación del FTP
function verificar_instalacion {
    if (Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue) {
        Write-Host "El servicio FTP está instalado y en ejecución."
    } else {
        Write-Host "El servicio FTP no está instalado o no está en ejecución."
    }
}

# Función para crear los grupos reprobados y recursadores
function crear_grupos {
    $grupos = @("reprobados", "recursadores")
    foreach ($grupo in $grupos) {
        if (-not (Get-LocalGroup -Name $grupo -ErrorAction SilentlyContinue)) {
            New-LocalGroup -Name $grupo
            Write-Host "Grupo '$grupo' creado."
        } else {
            Write-Host "El grupo '$grupo' ya existe."
        }
    }
}

# Función para crear un usuario
function crear_usuario {
    $username = Read-Host "Ingrese el nombre de usuario"
    $password = Read-Host "Ingrese la contraseña" -AsSecureString
    $grupo = Read-Host "Ingrese el grupo al que pertenecerá el usuario (reprobados/recursadores)"

    # Validar que el grupo sea válido
    if ($grupo -notin @("reprobados", "recursadores")) {
        Write-Host "El grupo ingresado no es válido. Debe ser 'reprobados' o 'recursadores'."
        return
    }

    # Validar que la contraseña no esté vacía
    if ($password.Length -eq 0) {
        Write-Host "La contraseña no puede estar vacía."
        return
    }

    # Crear el usuario si no existe
    try {
        New-LocalUser -Name $username -Password $password -FullName $username -ErrorAction Stop
        Write-Host "Usuario '$username' creado."
    } catch {
        Write-Host "Error al crear el usuario '$username': $_"
        return
    }

    # Agregar el usuario al grupo
    try {
        Add-LocalGroupMember -Group $grupo -Member $username -ErrorAction Stop
        Write-Host "Usuario '$username' agregado al grupo '$grupo'."
    } catch {
        Write-Host "Error al agregar el usuario '$username' al grupo '$grupo': $_"
        return
    }

    # Crear carpetas personales y asignar permisos
    $UserHomeDir = "C:\FTP\LocalUser\$username"
    $UserPublicDir = "$UserHomeDir\publica"
    $UserGroupDir = "$UserHomeDir\$grupo"
    $UserPersonalDir = "$UserHomeDir\$username"

    try {
        # Crear carpetas compartidas si no existen
        if (-not (Test-Path "C:\FTP\publica")) {
            New-Item -ItemType Directory -Path "C:\FTP\publica" -ErrorAction Stop
        }
        if (-not (Test-Path "C:\FTP\reprobados")) {
            New-Item -ItemType Directory -Path "C:\FTP\reprobados" -ErrorAction Stop
        }
        if (-not (Test-Path "C:\FTP\recursadores")) {
            New-Item -ItemType Directory -Path "C:\FTP\recursadores" -ErrorAction Stop
        }

        # Crear carpetas personales
        New-Item -ItemType Directory -Path $UserHomeDir -ErrorAction Stop
        New-Item -ItemType Directory -Path $UserPublicDir -ErrorAction Stop
        New-Item -ItemType Directory -Path $UserGroupDir -ErrorAction Stop
        New-Item -ItemType Directory -Path $UserPersonalDir -ErrorAction Stop

        # Asignar permisos exclusivos a la carpeta personal
        $Acl = Get-Acl $UserPersonalDir
        $Acl.SetAccessRuleProtection($true, $false)
        $Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$username", "FullControl", "Allow")))
        $Acl | Set-Acl $UserPersonalDir

        # Crear enlaces simbólicos
        New-Item -ItemType Junction -Path $UserPublicDir -Target "C:\FTP\publica" -ErrorAction Stop
        New-Item -ItemType Junction -Path $UserGroupDir -Target "C:\FTP\$grupo" -ErrorAction Stop

        Write-Host "Carpetas personales creadas y permisos asignados para el usuario '$username'."
    } catch {
        Write-Host "Error al crear carpetas o asignar permisos para el usuario '$username': $_"
    }
}
# Función para asignar un usuario a un grupo
function asignar_grupo {
    $username = Read-Host "Ingrese el nombre de usuario"
    $grupo = Read-Host "Ingrese el grupo al que desea asignar al usuario (reprobados/recursadores)"

    # Validar que el grupo sea válido
    if ($grupo -notin @("reprobados", "recursadores")) {
        Write-Host "El grupo ingresado no es válido. Debe ser 'reprobados' o 'recursadores'."
        return
    }

    # Verificar si el usuario existe
    if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
        Write-Host "El usuario '$username' no existe."
        return
    }

    # Agregar el usuario al grupo
    Add-LocalGroupMember -Group $grupo -Member $username
    Write-Host "Usuario '$username' asignado al grupo '$grupo'."

    # Actualizar enlace simbólico de la carpeta de grupo
    $UserGroupDir = "C:\FTP\LocalUser\$username\$grupo"
    if (Test-Path $UserGroupDir) {
        Remove-Item $UserGroupDir
    }
    New-Item -ItemType Junction -Path $UserGroupDir -Target "C:\FTP\$grupo"
    Write-Host "Enlace simbólico de la carpeta de grupo actualizado."
}

# Función para cambiar un usuario de grupo
function cambiar_grupo {
    $username = Read-Host "Ingrese el nombre de usuario"
    $nuevoGrupo = Read-Host "Ingrese el nuevo grupo para el usuario (reprobados/recursadores)"

    # Validar que el grupo sea válido
    if ($nuevoGrupo -notin @("reprobados", "recursadores")) {
        Write-Host "El grupo ingresado no es válido. Debe ser 'reprobados' o 'recursadores'."
        return
    }

    # Verificar si el usuario existe
    if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
        Write-Host "El usuario '$username' no existe."
        return
    }

    # Obtener el grupo actual del usuario
    $grupoActual = Get-LocalGroup | Where-Object { (Get-LocalGroupMember -Group $_).Name -eq "$env:COMPUTERNAME\$username" } | Select-Object -ExpandProperty Name

    if ($grupoActual -eq $nuevoGrupo) {
        Write-Host "El usuario '$username' ya está en el grupo '$nuevoGrupo'."
        return
    }

    # Cambiar el grupo del usuario
    Remove-LocalGroupMember -Group $grupoActual -Member $username
    Add-LocalGroupMember -Group $nuevoGrupo -Member $username
    Write-Host "Usuario '$username' cambiado del grupo '$grupoActual' al grupo '$nuevoGrupo'."

    # Actualizar enlace simbólico de la carpeta de grupo
    $UserGroupDir = "C:\FTP\LocalUser\$username\$nuevoGrupo"
    if (Test-Path $UserGroupDir) {
        Remove-Item $UserGroupDir
    }
    New-Item -ItemType Junction -Path $UserGroupDir -Target "C:\FTP\$nuevoGrupo"
    Write-Host "Enlace simbólico de la carpeta de grupo actualizado."
}

# Crear el sitio FTP si no existe
Crear-SitioFTP -SitioFTPName "SFTPSiteName" -FTPRootDir "C:\FTP" -Puerto 21

# Crear el grupo FTP si no existe
Crear-GrupoFTP -GrupoFTP "SFTPUserGroupName"

# Configurar autenticación y autorización
Configurar-AutenticacionYAutorizacion -SitioFTPName "SFTPSiteName" -GrupoFTP "SFTPUserGroupName"

# Configurar políticas SSL
Configurar-PoliticasSSL -SitioFTPName "SFTPSiteName"

# Configurar permisos NTFS y reiniciar el sitio FTP
Configurar-PermisosNTFSyReiniciarFTP -FTPRootDir "C:\FTP" -FTPUserGroupName "SFTPUserGroupName" -FTPSiteName "SFTPSiteName"

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