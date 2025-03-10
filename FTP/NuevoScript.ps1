Import-Module WebAdministration
function Crear-SitioFTP(){

    Param(

        [String]$FTPSiteName = "FTP",
        [String]$FTPRootDir = "C:\FTP\",
        [Int]$FTPPort = 21
        )
    New-WebFtpSite -Name $FTPSiteName -Port $FTPPort -PhysicalPath $FTPRootDir -Force
    }
    
function VerificarInstalacionFTP {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)] [string]$FeatureName 
    )  
    if((Get-WindowsOptionalFeature -FeatureName $FeatureName -Online).State -eq "Enabled") {
        return $true
    }else{
        return $false
    }
}

if(-not(VerificarInstalacionFTP "Web-Server")){
    Install-WindowsFeature Web-Server -IncludeManagementTools
}

if(-not(VerificarInstalacionFTP "Web-Ftp-Server")){
    Install-WindowsFeature Web-Ftp-Server -IncludeAllSubFeature
}

if(-not(VerificarInstalacionFTP "Web-Basic-Auth")){
    Install-WindowsFeature Web-Basic-Auth
}
function Get-ADSI {
    return [ADSI]"WinNT://$env:ComputerName"
}

function Crear-GrupoFTP {
        param(
            [String]$nombreGrupo, 
            [string]$descripcion   
        )
        try {
            $ADSI = Get-ADSI
    
            if (-not ([ADSI]::Exists("WinNT://$env:ComputerName/$nombreGrupo,Group"))) {
                # Crear el grupo si no existe
                $FTPUserGroup = $ADSI.Create("Group", "$nombreGrupo")  
                $FTPUserGroup.SetInfo()
                $FTPUserGroup.Description = $descripcion  
                $FTPUserGroup.SetInfo()
                Write-Host "Grupo $nombreGrupo creado correctamente."
    
                if (!(Test-Path "C:\FTP\$nombreGrupo")) {
                    mkdir "C:\FTP\$nombreGrupo"
                    Write-Host "Carpeta C:\FTP\$nombreGrupo creada correctamente."
                } else {
                    Write-Host "La carpeta C:\FTP\$nombreGrupo ya existe."
                }
            } else {
                Write-Host "El grupo $nombreGrupo ya existe."
            }
        } catch {
            Write-Host "Error: $_"  
        }
}
function Verifica-Password() {
    Param (
        [String]$Password
    )

    $longitudMinima = 8
    $regexMayuscula = "[A-Z]"
    $regexMinuscula = "[a-z]"
    $regexNumero = "[0-9]"
    $regexEspecial = "[!@#$%^&*()\-+=]"

    if ($Password.Length -lt $longitudMinima) {
        Write-Host "La contraseña debe tener al menos $longitudMinima caracteres."
        return $false
    }

    if (-not ($Password -match $regexMayuscula)) {
        Write-Host "La contraseña debe contener al menos una letra mayuscula."
        return $false
    }

    if (-not ($Password -match $regexMinuscula)) {
        Write-Host "La contraseña debe contener al menos una letra minuscula."
        return $false
    }

    if (-not ($Password -match $regexNumero)) {
        Write-Host "La contraseña debe contener al menos un numero."
        return $false
    }

    if (-not ($Password -match $regexEspecial)) {
        Write-Host "La contraseña debe contener al menos un carácter especial (!@#$%^&*()\-+=)."
        return $false
    }

    Write-Host "La contraseña es valida."
    return $true
}
function Validar-Usuario {
    Param (
        [String]$Username
    )
    $longitudMaxima = 20

    if ($Username.Length -gt $longitudMaxima) {
        Write-Host "El nombre de usuario no puede superar los $longitudMaxima caracteres."
        return $false
    }
    Write-Host "El nombre de usuario es valido."
    return $true
}
function Crear-UsuarioFTP(){
    Param(
        [String]$Username,
        [String]$Password
    )

    $FTPUserName = $Username
    $FTPPassword = $Password
    $ADSI = Get-ADSI
    $CreateUserFTPUser = $ADSI.Create("User", "$FTPUserName")
    $CreateUserFTPUser.SetInfo()
    $CreateUserFTPUser.SetPassword("$FTPPassword")
    $CreateUserFTPUser.SetInfo()
    mkdir C:\FTP\LocalUser\$FTPUserName
    mkdir C:\FTP\LocalUser\$FTPUserName\$FTPUserName
    if (-not (Test-Path "C:\FTP\LocalUser\Public")) {
        mkdir C:\FTP\LocalUser\Public
    } else {
        Write-Host "La carpeta Public ya existes"
    }
    
    $SubCarpetaUsuario = "C:\FTP\LocalUser\$FTPUserName\$FTPUserName"
    ConfigurarPermisos700 -Usuario $FTPUserName -CarpetaUsuario $SubCarpetaUsuario

    cmd /c mklink /D C:\FTP\LocalUser\$FTPUserName\Public C:\FTP\LocalUser\Public

}


function ConfigurarPermisos700 {
    Param (
        [String]$Usuario,          # Nombre del usuario propietario
        [String]$CarpetaUsuario    # Ruta de la carpeta personal del usuario
    )

    # Validar que el directorio existe
    if (-not (Test-Path $CarpetaUsuario)) {
        Write-Host "El directorio $CarpetaUsuario no existe."
        return
    }

    try {
        # Crear objeto del usuario propietario
        $UserAccount = New-Object System.Security.Principal.NTAccount($Usuario)

        # Obtener la ACL actual del directorio
        $ACL = Get-Acl -Path $CarpetaUsuario

        # Bloquear herencia y eliminar permisos heredados
        $ACL.SetAccessRuleProtection($true, $false)

        # Limpiar reglas de acceso existentes (excepto las necesarias)
        $ACL.Access | ForEach-Object {
            if (-not ($_.IdentityReference -eq "NT AUTHORITY\SYSTEM" -or $_.IdentityReference -eq "BUILTIN\Administrators")) {
                $ACL.RemoveAccessRule($_)
            }
        }

        # Agregar permisos para el propietario (Control Total)
        $AccessRuleUser = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $UserAccount, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow"
        )
        $ACL.SetAccessRule($AccessRuleUser)

        # Agregar permisos para grupo y público (Sin permisos)
        $ACL.Access | ForEach-Object {
            if ($_.IdentityReference -like "BUILTIN\Users" -or $_.IdentityReference -like "Everyone") {
                $ACL.RemoveAccessRule($_)
            }
        }

        # Establecer propiedad al usuario
        $ACL.SetOwner($UserAccount)

        # Aplicar los cambios a la carpeta
        Set-Acl -Path $CarpetaUsuario -AclObject $ACL

        Write-Host "Permisos configurados correctamente para '$Usuario'."
    } catch {
        Write-Host "Error al configurar permisos: $_"
    }
}

function Asignar-Grupo {
    Param (
        [String]$Username,
        [String]$nombreGrupo,
        [String]$FTPSiteName
    )

    $gruposPermitidos = @("reprobados", "recursadores")

    if ($gruposPermitidos -notcontains $nombreGrupo) {
        Write-Host "El grupo '$nombreGrupo' no está permitido. Solo se puede asignar a 'reprobados' o 'recursadores'."
        return
    }

    try {
        $UserAccount = New-Object System.Security.Principal.NTAccount("$Username")
        $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
    } catch [System.Security.Principal.IdentityNotMappedException] {
        Write-Host "El usuario $Username no fue encontrado."
        return
    } catch {
        Write-Host "Ocurrió un error inesperado al buscar el usuario $Username : $_"
        return
    }

    # Verificar si el grupo existe
    try {
        $Group = [ADSI]"WinNT://$env:ComputerName/$nombreGrupo,Group"
        if (-not $Group.Path) {
            throw "El grupo no es válido."
        }
    } catch {
        Write-Host "El grupo $nombreGrupo no fue encontrado."
        return
    }

    # Verificar si el usuario ya está en algún grupo
    $grupos = Get-LocalGroup | Where-Object { 
        $_ | Get-LocalGroupMember | Where-Object { $_.Name -eq "$env:COMPUTERNAME\$Username" }
    }

    if ($grupos.Count -gt 0) {
        Write-Host "El usuario $Username ya pertenece al grupo $($grupos[0].Name). No se puede asignar a otro grupo."
        return
    }

    # Si el usuario no está en ningún grupo, asignarlo al nuevo grupo
    try {
        $User = [ADSI]"WinNT://$SID"
        $Group.Add($User.Path)
        Write-Host "El usuario $Username ha sido asignado al grupo $nombreGrupo correctamente."
    } catch {
        Write-Host "No se pudo agregar el usuario $Username al grupo $nombreGrupo."
        return
    }

    $UserDir = "C:\FTP\LocalUser\$Username"
    $GroupDir = "C:\FTP\$nombreGrupo"
    $UserGroupDir = "$UserDir\$nombreGrupo"

    if (-not (Test-Path $UserDir)) {
        New-Item -ItemType Directory -Path $UserDir
    }

    if (-not (Test-Path $GroupDir)) {
        New-Item -ItemType Directory -Path $GroupDir
    }

    if (-not (Test-Path $UserGroupDir)) {
        New-Item -ItemType Directory -Path $UserGroupDir
    }


    # Configurar permisos NTFS
    $FtpDir = $UserGroupDir
    ConfigurarPermisosGrupo $nombreGrupo $FtpDir $FTPSiteName

    cmd /c mklink /D C:\FTP\LocalUser\$Username\$nombreGrupo C:\FTP\$nombreGrupo
}
function ConfigurarPermisosGrupo {
    Param (
        [String]$Objeto,      # Nombre del grupo
        [String]$FtpDir,      # Ruta de la carpeta
        [String]$FtpSiteName  # Nombre del sitio FTP (opcional)
    )

    # Validar que el directorio existe
    if (-not (Test-Path $FtpDir)) {
        Write-Host "El directorio $FtpDir no existe."
        return
    }

    # Validar que el objeto (grupo) existe
    try {
        $GroupAccount = New-Object System.Security.Principal.NTAccount($Objeto)
        $SID = $GroupAccount.Translate([System.Security.Principal.SecurityIdentifier])
    } catch [System.Security.Principal.IdentityNotMappedException] {
        Write-Host "El grupo '$Objeto' no fue encontrado."
        return
    } catch {
        Write-Host "Ocurrió un error inesperado al validar el grupo '$Objeto': $_"
        return
    }

    # Obtener la ACL actual del directorio
    $ACL = Get-Acl -Path $FtpDir

    # Bloquear la herencia de permisos y eliminar permisos heredados
    $ACL.SetAccessRuleProtection($true, $false)

    # Eliminar todos los permisos existentes (excepto los del sistema)
    $ACL.Access | ForEach-Object {
        if (-not ($_.IdentityReference -eq "NT AUTHORITY\SYSTEM" -or $_.IdentityReference -eq "BUILTIN\Administrators")) {
            $ACL.RemoveAccessRule($_)
        }
    }

    # Crear la regla de acceso para el grupo
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $GroupAccount,                          # Cuenta del grupo
        "Modify",                               # Permisos: "Modify" permite leer, escribir, ejecutar y eliminar
        "ContainerInherit, ObjectInherit",      # Heredar a subcarpetas y archivos
        "None",                                 # No propagar
        "Allow"                                 # Tipo de permiso: Permitir
    )

    # Agregar la regla de acceso a la ACL
    $ACL.SetAccessRule($AccessRule)

    # Aplicar la ACL modificada al directorio
    Set-Acl -Path $FtpDir -AclObject $ACL

    Write-Host "Permisos NTFS configurados correctamente para el grupo '$Objeto' en '$FtpDir'."

    # Reiniciar el sitio FTP si es necesario (opcional)
    if ($FtpSiteName) {
        Restart-WebItem "IIS:\Sites\$FtpSiteName" -Verbose
        Write-Host "Sitio FTP '$FtpSiteName' reiniciado."
    }
}
function Configurar-FTPSite {
    Param ([String]$FTPSiteName)
    
    $FTPSitePath = "IIS:\\Sites\\$FTPSiteName"
    $BasicAuth = 'ftpServer.security.authentication.basicAuthentication.enabled'

    Set-ItemProperty -Path $FTPSitePath -Name $BasicAuth -Value $True

    $Param = @{
        Filter = "/system.ftpServer/security/authorization"
        Value = @{
            accessType = "Allow"
            users = "*"
            permissions = 3
        }
        PSPath = 'IIS:\\'
    Location = $FTPSiteName
    }

    Add-WebConfiguration @Param

    Configurar-SSLPolicy $FTPSitePath
    }

   

function Configurar-SSLPolicy {
    Param ([String]$FTPSitePath)

    $SSLPolicy = @(
    'ftpServer.security.ssl.controlChannelPolicy',
    'ftpServer.security.ssl.dataChannelPolicy'
)

Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[0] -Value $false
Set-ItemProperty -Path $FTPSitePath -Name $SSLPolicy[1] -Value $false

}

function ConfigurarPermisosNTFS {
    Param (
        [String]$Objeto,      
        [String]$FtpDir,      
        [String]$FtpSiteName  
    )

    # Validar que el directorio existe
    if (-not (Test-Path $FtpDir)) {
        Write-Host "El directorio $FtpDir no existe." 
        return
    }

    # Validar que el objeto (usuario/grupo) existe
    try {
        $UserAccount = New-Object System.Security.Principal.NTAccount($Objeto)
        $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
    } catch [System.Security.Principal.IdentityNotMappedException] {
        Write-Host "El objeto (usuario o grupo) '$Objeto' no fue encontrado." 
        return
    } catch {
        Write-Host "Ocurrio un error inesperado al validar el objeto '$Objeto': $_"
        return
    }

    $AccessRule = [System.Security.AccessControl.FileSystemAccessRule]::new(
        $UserAccount, 
        'ReadAndExecute', 
        'ContainerInherit,ObjectInherit', 
        'None', 
        'Allow'
        )

        $ACL = Get-Acl -Path $FtpDir
        $ACL.SetAccessRule($AccessRule)
        $ACL | Set-Acl -Path $FtpDir
   

    Restart-WebItem "IIS:\Sites\$FtpSiteName" -Verbose
}
    
function Crear_RutaFTP(){
    Param(
        [string]$RutaFTP
    )
    if(!(Test-Path $RutaFTP)){
        mkdir $RutaFTP
    }
}

function AislarUsuario(){
    Param (
        [String]$FTPSiteName
    )
    
    Set-ItemProperty -Path "IIS:\Sites\$FTPSiteName" -Name ftpServer.userisolation.mode -Value 3
    
}

function Habilitar-AccesoAnonimo(){
    Param(
        [string]$FTPSiteName
    )
    Set-ItemProperty "IIS:\Sites\$FTPSiteName" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
}

function CambiarGrupoFtp {
    Param(
        [String]$Username,
        [String]$nombreGrupo,
        [String]$FTPSiteName
    )

    try {
        # Verificar si el usuario existe
        if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
            Write-Host "El usuario '$Username' no existe. Intentelo de nuevo."
            return
        }

        # Verificar si el grupo existe
        if (-not (Get-LocalGroup -Name $nombreGrupo -ErrorAction SilentlyContinue)) {
            Write-Host "El grupo '$nombreGrupo' no existe. Inténtelo de nuevo."
            return
        }

        # Obtener los grupos a los que pertenece el usuario
        $grupos = Get-LocalGroup | Where-Object { 
            $_ | Get-LocalGroupMember | Where-Object { $_.Name -eq "$env:COMPUTERNAME\$Username" }
        }

        # Verificar si el usuario pertenece a algún grupo
        if ($grupos.Count -eq 0) {
            Write-Host "El usuario $Username no pertenece a ningún grupo."
        } else {
            # Eliminar al usuario de los grupos actuales
            foreach ($grupo in $grupos) {
                Remove-LocalGroupMember -Group $grupo.Name -Member $Username -ErrorAction Stop
            }

            # Eliminar el enlace simbólico y la carpeta del grupo anterior
            $rutaGrupoAnterior = "C:\FTP\LocalUser\$Username\$($grupos[0].Name)"
            if (Test-Path $rutaGrupoAnterior) {
                Remove-Item -Path $rutaGrupoAnterior -Recurse -Force -ErrorAction Stop
            }
        }

        Asignar-Grupo -User $Username -nombreGrupo $nombreGrupo -FTPSiteName $FTPSiteName

        # Crear el enlace simbólico para el nuevo grupo
        $rutaNuevoGrupo = "C:\FTP\LocalUser\$Username\$nombreGrupo"
        if (!(Test-Path $rutaNuevoGrupo)) {
            cmd /c mklink /D $rutaNuevoGrupo "C:\FTP\$nombreGrupo"
        } else {
            Write-Host "El enlace simbólico para el nuevo grupo ya existe."
        }

        Write-Host "El usuario $Username ha sido asignado al grupo $nombreGrupo correctamente."
    } catch {
        Write-Host "Error: $_"
    }
}
$FTPSiteName = "FTP"
$FTPRootDir = "C:\FTP\"
$FTPPort = 21
$FTPRootDirLogin = "C:\FTP\LocalUser"

$Ruta = "C:\FTP"
Crear_RutaFTP $Ruta

Crear-SitioFTP
VerificarInstalacionFTP -FeatureName  "Web-Server"
Configurar-FTPSite $FTPSiteName

Crear-GrupoFTP -nombreGrupo "reprobados" -descripcion "Grupo Reprobados"
Crear-GrupoFTP -nombreGrupo "recursadores" -descripcion "Grupo Recursadores"
Crear-GrupoFTP -nombreGrupo "Public" -descripcion "Grupo Publica"

ConfigurarPermisosNTFS -Objeto "reprobados" -FtpDir $FTPRootDir -FTPSiteName $FTPSiteName
ConfigurarPermisosNTFS -Objeto "recursadores" -FtpDir $FTPRootDir -FTPSiteName $FTPSiteName
ConfigurarPermisosNTFS -Objeto "Public" -FtpDir $FTPRootDir -FTPSiteName $FTPSiteName  

AislarUsuario $FTPSiteName
Habilitar-AccesoAnonimo $FTPSiteName
while($true){
    echo "===================================="
    echo "          Mene Principal           "
    echo "===================================="
    echo "1. Agregar usuario"
    echo "2. Asignar Grupo"
    echo "3. Cambiar usuario de grupo"
    echo "4. Salir"

    try{
        $opcion = Read-Host "Selecciona una opcion"
        $intOpcion = [int]$opcion
    }
    catch{
        echo "Valor invalido"
    }

    if($intOpcion -eq 4){
        echo "Saliendo..."
        break
    }

    if($intOpcion -is [int]){
        switch($opcion){
            1 {
                $Username = Read-Host "Ingresa el Usuario"
    
                if (Validar-Usuario -Username $Username) {
                    $Password = Read-Host "Ingresa la contraseña del usuario"
                    
                    if (Verifica-Password -Password $Password) {
                        Crear-UsuarioFTP -Username $Username -Password $Password
                    } else {
                        Write-Host "La contraseña no cumple con los requisitos. No se creara el usuario."
                    }
                } else {
                    Write-Host "El nombre de usuario no es valido. No se creara el usuario."
                }

            }
            2 {
                $Username= Read-Host "Ingrese el nombre del Usuario asignar"
                $nombreGrupo = Read-Host "Ingrese el nombre del grupo para asignar al usuario"

                Asignar-Grupo $Username $nombreGrupo $FTPSiteName
                ConfigurarPermisosNTFS $nombreGrupo $FTPRootDirLogin $FTPSiteName
            }
            3{
                $Username= Read-Host "Ingrese el nombre de usuario a quien desea cambiar de grupo"
                $nombreGrupo= Read-Host "Ingrese el nuevo grupo del usuario"

                CambiarGrupoFtp $Username $nombreGrupo $FTPSiteName
            }
        }
    }
}
