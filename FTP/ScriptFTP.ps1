# Función para instalar el servidor FTP (IIS)
function Install-FTPServer {
    Write-Host "Instalando el servidor FTP..."
    Install-WindowsFeature -Name Web-FTP-Server -IncludeManagementTools
    Start-Service ftpsvc
    Set-Service ftpsvc -StartupType Automatic
    Write-Host "Servidor FTP instalado y en ejecución."
}

# Función para crear un usuario
function Create-User {
    $username = Read-Host "Ingrese el nombre de usuario"
    $password = Read-Host "Ingrese la contraseña para $username" -AsSecureString

    # Crear el usuario
    New-LocalUser -Name $username -Password $password -FullName $username -Description "Usuario FTP"
    Write-Host "Usuario $username creado."

    # Crear el directorio del usuario
    $userDir = "C:\FTP\$username"
    New-Item -ItemType Directory -Path $userDir
    Write-Host "Directorio $userDir creado."

    # Asignar permisos al directorio
    $acl = Get-Acl $userDir
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl -Path $userDir -AclObject $acl
    Write-Host "Permisos asignados al directorio $userDir."

    # Crear carpetas públicas y privadas
    New-Item -ItemType Directory -Path "$userDir\publica"
    New-Item -ItemType Directory -Path "$userDir\$username"
    Write-Host "Carpetas públicas y privadas creadas."

    # Asignar permisos a las carpetas
    $aclPublic = Get-Acl "$userDir\publica"
    $rulePublic = New-Object System.Security.AccessControl.FileSystemAccessRule("Todos", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $aclPublic.SetAccessRule($rulePublic)
    Set-Acl -Path "$userDir\publica" -AclObject $aclPublic

    $aclPrivate = Get-Acl "$userDir\$username"
    $rulePrivate = New-Object System.Security.AccessControl.FileSystemAccessRule($username, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $aclPrivate.SetAccessRule($rulePrivate)
    Set-Acl -Path "$userDir\$username" -AclObject $aclPrivate
    Write-Host "Permisos asignados a las carpetas públicas y privadas."
}

# Función para asignar un usuario a un grupo
function Assign-Group {
    $username = Read-Host "Escriba el nombre de usuario a asignar a un grupo"
    $group = Read-Host "Escriba el nombre del grupo a asignar"

    # Verificar si el grupo existe, si no, crearlo
    if (-not (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue)) {
        New-LocalGroup -Name $group
        Write-Host "Grupo $group creado."
    }

    # Asignar el usuario al grupo
    Add-LocalGroupMember -Group $group -Member $username
    Write-Host "Usuario $username asignado al grupo $group."

    # Crear la carpeta del grupo y asignar permisos
    $groupDir = "C:\FTP\$group"
    New-Item -ItemType Directory -Path $groupDir -ErrorAction SilentlyContinue
    $acl = Get-Acl $groupDir
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl -Path $groupDir -AclObject $acl
    Write-Host "Carpeta del grupo $group creada y permisos asignados."
}

# Función para cambiar un usuario de grupo
function Change-Group {
    $username = Read-Host "Escriba el usuario a quien desea cambiar de grupo"
    $newGroup = Read-Host "Escriba el nuevo grupo de ese usuario"

    # Obtener el grupo actual del usuario
    $currentGroup = (Get-LocalUser -Name $username | Get-LocalGroup).Name

    if ($currentGroup -eq $newGroup) {
        Write-Host "El usuario $username ya está en el grupo $newGroup. No se realizaron cambios."
        return
    }

    # Remover al usuario del grupo actual
    Remove-LocalGroupMember -Group $currentGroup -Member $username
    Write-Host "Usuario $username removido del grupo $currentGroup."

    # Agregar al usuario al nuevo grupo
    Add-LocalGroupMember -Group $newGroup -Member $username
    Write-Host "Usuario $username asignado al grupo $newGroup."

    # Mover la carpeta del grupo
    $oldGroupDir = "C:\FTP\$currentGroup"
    $newGroupDir = "C:\FTP\$newGroup"
    Move-Item -Path $oldGroupDir -Destination $newGroupDir -ErrorAction SilentlyContinue
    Write-Host "Carpeta del grupo movida de $oldGroupDir a $newGroupDir."
}

# Menú principal
while ($true) {
    Write-Host "Seleccione una opción:"
    Write-Host "1. Crear un usuario"
    Write-Host "2. Asignar un usuario a un grupo"
    Write-Host "3. Cambiar un usuario de grupo"
    Write-Host "4. Salir"
    $option = Read-Host "Opción"

    switch ($option) {
        1 { Create-User }
        2 { Assign-Group }
        3 { Change-Group }
        4 { Write-Host "Saliendo..."; break }
        default { Write-Host "Opción no válida. Intente de nuevo." }
    }
}