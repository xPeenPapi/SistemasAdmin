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
    mkdir C:\FTP\LocalUser\Public
    cmd /c mklink /D C:\FTP\LocalUser\$FTPUserName\Public C:\FTP\LocalUser\Public




}
function Asignar-Grupo {
    Param (
        [String]$Username,
        [String]$nombreGrupo,
        [String]$FTPSiteName
    )
    try {
        # Intentar obtener el SID del usuario
        $UserAccount = New-Object System.Security.Principal.NTAccount("$Username")
        $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
    } catch [System.Security.Principal.IdentityNotMappedException] {
        Write-Error "El usuario $Username no fue encontrado."
        return
    } catch {
        Write-Error "Ocurrió un error inesperado al buscar el usuario $Username : $_"
        return
    }

    # Verificar si el grupo existe
    try {
        $Group = [ADSI]"WinNT://$env:ComputerName/$nombreGrupo,Group"
        # Verificar si el grupo es válido
        if (-not $Group.Path) {
            throw "El grupo no es válido."
        }
    } catch {
        Write-Error "El grupo $nombreGrupo no fue encontrado."
        return
    }

    # Verificar si el usuario ya está en el grupo
    try {
        $User = [ADSI]"WinNT://$SID"
        $Group.Add($User.Path)
    } catch {
        Write-Error "No se pudo agregar el usuario $Username al grupo $nombreGrupo."
        return
    }

    #$UserAccount = New-Object System.Security.Principal.NTAccount("$Username")
    #$SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
    #$Group = [ADSI]"WinNT://$env:ComputerName/$nombreGrupo,Group"
    #$User = [ADSI]"WinNT://$SID"
    #$Group.Add($User.Path)
    

    cmd /c mklink /D C:\FTP\LocalUser\$Username\$nombreGrupo C:\FTP\$nombreGrupo
    
    $FTPRootDir ="C:\FTP\LocalUser\$Username\$nombreGrupo"
    $FtpDir = $FTPRootDir
    ConfigurarPermisosNTFS $nombreGrupo $FtpDir $FTPSiteName
    
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

function ConfigurarPermisosNTFS(){

    Param ([String]$Objeto,[String]$FtpDir,[String]$FtpSiteName)
    
    
    $UserAccount = New-Object System.Security.Principal.NTAccount($Objeto)
    $AccessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($UserAccount, 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    
    $ACL = Get-Acl -Path $FtpDir
    $ACL.SetAccessRule($AccessRule)
    $ACL | Set-Acl -Path $FtpDir
    
    # Reiniciar el sitio FTP para que todos los cambios tengan efecto.
    Restart-WebItem "IIS:\Sites\$FTPSiteName" -Verbose
    
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
            Write-Host "El usuario '$Username' no existe. Inténtelo de nuevo."
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
                Write-Host "Eliminando al usuario $Username del grupo $($grupo.Name)..."
                Remove-LocalGroupMember -Group $grupo.Name -Member $Username -ErrorAction Stop
            }

            # Eliminar el enlace simbólico y la carpeta del grupo anterior
            $rutaGrupoAnterior = "C:\FTP\LocalUser\$Username\$($grupos[0].Name)"
            if (Test-Path $rutaGrupoAnterior) {
                Write-Host "Eliminando el enlace simbólico y la carpeta del grupo anterior..."
                Remove-Item -Path $rutaGrupoAnterior -Recurse -Force -ErrorAction Stop
            }
        }

        # Asignar el usuario al nuevo grupo (solo si el usuario y el grupo existen)
        Write-Host "Asignando al usuario $Username al grupo $nombreGrupo..."
        Asignar-Grupo -User $Username -nombreGrupo $nombreGrupo -FTPSiteName $FTPSiteName

        # Crear el enlace simbólico para el nuevo grupo
        $rutaNuevoGrupo = "C:\FTP\LocalUser\$Username\$nombreGrupo"
        if (!(Test-Path $rutaNuevoGrupo)) {
            Write-Host "Creando enlace simbólico para el nuevo grupo..."
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
    echo "          Menú Principal           "
    echo "===================================="
    echo "Menu"
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
                $Username= Read-Host "Ingresa el Usuario"
                $Password = Read-Host "Ingresa la contraseña del usuario"
                Crear-UsuarioFTP $Username $Password

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
