Import-Module WebAdministration
function Crear-SitioFTP(){

    Param(
        [String]$FTPSiteName,
        [String]$FTPRootDir,
        [Int]$FTPPort
        )
    New-WebFtpSite -Name $FTPSiteName -Port $FTPPort -PhysicalPath $FTPRootDir
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
    $FTPUserGroupName = $nombreGrupo
    $ADSI = Get-ADSI
    $FTPUserGroup = $ADSI.Create("Group", "$FTPUserGroupName")
    $FTPUserGroup.SetInfo()
    $FTPUserGroup.Description = "$descripcion"
    $FTPUserGroup.SetInfo()
    mkdir C:\FTP\$nombreGrupo

}

function Crear-UsuarioFTP(){
    Param(
        [String]$User,
        [String]$Password
    )

    $FTPUserName = $User
    $FTPPassword = $Password
    $ADSI = Get-ADSI
    $CreateUserFTPUser = $ADSI.Create("User", "$FTPUserName")
    $CreateUserFTPUser.SetInfo()
    $CreateUserFTPUser.SetPassword("$FTPPassword")
    $CreateUserFTPUser.SetInfo()

    mkdir C:\FTP\LocalUser\$User
    mkdir C:\FTP\LocalUser\$User\$User
    mkdir C:\FTP\LocalUser\$User\Publica
    cmd /c mklink /D C:\FTP\LocalUser\$User\Publica C:\FTP\Publica

}
function Asignar-Grupo {
    Param (
        [String]$User,
        [String]$nombreGrupo,
        [String]$FTPSiteName
    )

    $UserAccount = New-Object System.Security.Principal.NTAccount("$User")
    $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
    $Group = [ADSI]"WinNT://$env:ComputerName/$nombreGrupo,Group"
    $User = [ADSI]"WinNT://$SID"
    $Group.Add($User.Path)
    
    
    cmd /c mklink /D C:\FTP\LocalUser\$User\$nombreGrupo C:\FTP\$nombreGrupo
    
    $FTPRootDir ="C:\FTP\LocalUser\$User\$nombreGrupo"
    
    ConfigurarPermisosNTFS $nombreGrupo $FTPRootDir $FTPSiteName
    
}

function Configurar-FTPSite {
    Param ([String]$FTPSiteName)

    $FTPSitePath = "IIS:\\Sites\\$FTPSiteName"
    $BasicAuth = 'ftpServer.security.authentication.basicAuthentication.enabled'

    Set-ItemProperty -Path $FTPSitePath -Name $BasicAuth -Value $True

    $Param = @{
        Filter = "system.ftpServer/security/authorization"
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

$Ruta = "C:\FTP"
Crear_RutaFTP $Ruta

$FTPSiteName= "FTP"
$FTPRootDir= "C:\FTP\"
$FTPPort=21
$FTPRootDirLogin= "C:\FTP\LocalUser"


Crear-SitioFTP -Name $FTPSiteName -PhysicalPath $FTPRootDIR -Port $FTPPort

Crear-GrupoFTP -nombreGrupo "reprobados" -descripcion "Grupo Reprobados"
Crear-GrupoFTP -nombreGrupo "recursadores" -descripcion "Grupo Recursadores"
Crear-GrupoFTP -nombreGrupo "publica" -descripcion "Grupo Publica"
ConfigurarPermisosNTFS -nombreGrupo "reprobados" -FTPRootDirLogin $FTPRootDirLogin -FTPSiteName $FTPSiteName
ConfigurarPermisosNTFS -nombreGrupo "recursadores" -FTPRootDirLogin $FTPRootDirLogin -FTPSiteName $FTPSiteName
ConfigurarPermisosNTFS -nombreGrupo "publica" -FTPRootDirLogin $FTPRootDirLogin -FTPSiteName $FTPSiteName

VerificarInstalacionFTP  
Configurar-FTPSite $FTPSiteName
Configurar-SSLPolicy 

while($true){
    echo "===================================="
    echo "          Menú Principal           "
    echo "===================================="
    echo "Menu"
    echo "1. Agregar usuario"
    echo "2. Asignar Grupo"
    echo "2. Cambiar usuario de grupo"
    echo "3. Salir"

    try{
        $opcion = Read-Host "Selecciona una opcion"
        $intOpcion = [int]$opcion
    }
    catch{
        echo "Valor invalido"
    }

    if($intOpcion -eq 3){
        echo "Saliendo..."
        break
    }

    if($intOpcion -is [int]){
        switch($opcion){
            1 {
                $User= Read-Host "Ingresa el Usuario"
                $Password = Read-Host "Ingresa la contraseña del usuario"
                Crear-UsuarioFTP $User $Password

            }
            2 {
            $User= Read-Host "Ingrese el nombre del Usuario asignar"
            $nombreGrupo = Read-Host "Ingrese el nombre del grupo para asignar al usuario"

             Asignar-Grupo $User $nombreGrupo $FTPSiteName
             ConfigurarPermisosNTFS $nombreGrupo $FTPRootDirLogin $FTPSiteName
            }
        }
    }
}
