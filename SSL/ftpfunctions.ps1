function InstallFtp{
    #Install-WindowsFeature Web-Basic-Auth
    #Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature
    #Install-WindowsFeature Web-Server -IncludeAllSubFeature -IncludeManagementTools
    #Import-Module WebAdministration

   
    $sitename = "PruebaFTP"
    new-webFtpSite -Name $sitename -Port '21' -PhysicalPath 'C:\FTP' #Sustituye variables
 
    $FTPUserGroupName1 = "Reprobados"
    $FTPUserGroupName2 = "Recursadores"


    $ADSI = [ADSI]"WinNT://$env:ComputerName"
    $FTPUserGroup1 = $ADSI.Create("Group","$FTPUserGroupName1")
    $FTPUserGroup2 = $ADSI.Create("Group","$FTPUserGroupName2")
    $FTPUserGroup1.SetInfo()
    $FTPUserGroup1.Description = "Grupo de Reprobados"
    $FTPUserGroup1.SetInfo()
    $FTPUserGroup2.SetInfo()
    $FTPUserGroup2.Description = "Grupo de Reprobados"
    $FTPUserGroup2.SetInfo()

    New-Item -Path "C:\FTP\LocalUser\Public" -ItemType Directory
    New-Item -Path "C:\FTP\Reprobados" -ItemType Directory
    New-Item -Path "C:\FTP\Recursadores" -ItemType Directory

    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name ftpServer.userIsolation.mode -Value 3

    icacls "C:\FTP\LocalUser\Public" /grant "Todos:(OI)(CI)F"
    icacls "C:\FTP\" /grant "Todos:(OI)(CI)F"
    icacls "C:\FTP\LocalUser\Public" /grant "IUSR:(OI)(CI)F"
    icacls "C:\FTP\LocalUser\Public" /grant "IIS_IUSRS:(OI)(CI)F"
    icacls "C:\FTP\LocalUser" /grant "IIS_IUSRS:(OI)(CI)F"
    icacls "C:\FTP" /grant "IUSR:(OI)(CI)F"
    icacls "C:\FTP" /grant "IIS_IUSRS:(OI)(CI)F"
    icacls "C:\FTP\Reprobados" /grant "Reprobados:(OI)(CI)F"
    icacls "C:\FTP\Recursadores" /grant "Recursadores:(OI)(CI)F"

    icacls "C:\FTP\LocalUser\Public" /grant IUSR:R /T





    Import-Module WebAdministration
    Add-WebConfigurationProperty -filter "/system.ftpServer/security/authentication/basicAuthentication" -name enable -value true -PSPath "IIS:\Sites\PruebaFTP"
    Add-WebConfigurationProperty -filter "/system.ftpServer/security/authentication/anonymousAuthentication" -name enable -value true -PSPath "IIS:\Sites\PruebaFTP"
    Add-WebConfiguration "/system.ftpServer/security/authorization" ` -PSPath "IIS:\Sites\PruebaFTP"  -Value @{accesType="Allow";users="*"; permissions="Read, Write"}


    $FTPSitePath = "IIS:\Sites\$sitename"
    $BasicAuth = 'ftpServer.security.authentication.basicAuthentication.enabled'
    Set-ItemProperty -Path $FTPSitePath -Name $BasicAuth -Value $True
    $param =@{
        Filter = "/system.ftpServer/security/authorization"
        Value = @{
            accessType = "Allow"
            roles = $FTPUserGroupName1
            permision = 1
        }
        PSPath = 'IIS:\'
        Location = $sitename
    }
    $param2 =@{
        Filter = "/system.ftpServer/security/authorization"
        Value = @{
            accessType = "Allow"
            roles = $FTPUserGroupName2
            permision = 1
        }
        PSPath = 'IIS:\'
        Location = $sitename
    }
    $param3 =@{
        Filter = "/system.ftpServer/security/authorization"
        Value = @{
            accessType = "Allow"
            roles = "*"
            permisions = "Read, Write"
        }
        PSPath = 'IIS:\'
        Location = $sitename
    }
    Add-WebConfiguration @param
    Add-WebConfiguration @param2
    Add-WebConfiguration @param3

    $SSLPolicy = @(
       'ftpServer.security.ssl.controlChannelPolicy',
       'ftpServer.security.ssl.dataChannelPolicy'
    )
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name $SSLPolicy[0] -Value 0
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name $SSLPolicy[1] -Value 0

    Restart-Service ftpsvc
    Restart-Service W3SVC
    Restart-WebItem "IIS:\Sites\PruebaFTP" -Verbose

}

function ChangeGroup{
     Write-Host "A que grupo se va a reasignar el usuario $user"
     Write-Host "1. Reprobados"
     Write-Host "2. Recursadores"
     Write-Host "[Otro]Cancelar"
     $opc = Read-Host("Opcion")
    switch($opc){
    '1'{
        Remove-LocalGroupMember -Group Recursadores -Member $user -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group Reprobados -Member $user
        Write-Host "El usuario se ha registrado al nuevo grupo"
        icacls "C:\FTP\Recursadores" /remove $user
        icacls "C:\FTP\Reprobados" /grant "$($user):(OI)(CI)F"
        Remove-Item "C:\FTP\LocalUser\$user\Recursadores"
        New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$user\Reprobados" -Target "C:\FTP\Reprobados"
     }
    '2'{
            Remove-LocalGroupMember -Group Reprobados -Member $user -ErrorAction SilentlyContinue
            Add-LocalGroupMember -Group Recursadores -Member $user
            Write-Host "El usuario se ha registrado al nuevo grupo"
            icacls "C:\FTP\Reprobados" /remove $user
            icacls "C:\FTP\Recursadores" /grant "$($user):(OI)(CI)F"
            Remove-Item "C:\FTP\LocalUser\$user\Reprobados" -Force
            New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$user\Recursadores" -Target "C:\FTP\Recursadores"   
     }

     default{}

     }
}

function Login{
    do{
        $user = Read-Host (echo "Ingresa el nombre de usuario")
        $userexists = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
        if(-not $userexists){
            Write-Host "El usuario no existe, intente de nuevo" -ForegroundColor Red
        }
    } while (-not $userexists)

        clear
        Write-Host "Elige una opcion [1-2]"
        Write-Host "1. Reasignar Grupos a usuario"
        Write-Host "2. Eliminar Usuario"
        Write-Host "Cancelar"
        $opc = Read-Host("Opcion")
        switch($opc){
        '1'{
                ChangeGroup;
           }
        '2'{
                Write-Host "Usuario eliminado"
                Remove-LocalUser -Name $user    
           }

        default{$running = $false}

        }
    }

function Register{
    do{
        $ADSI = [ADSI]"WinNT://$env:ComputerName"
        Write-Host "2"
        $username = Read-Host("Ingrese su nombre de usuario")
        if([string]::IsNullOrWhiteSpace($username) -or $username -match "\s"){
            Write-Host "El nombre no puede tener espacios en blanco ni ser nulo"
        }
    }while ([string]::IsNullOrWhiteSpace($username) -or $username -match "\s")

    do{
        $password = Read-Host("Ingrese una contraseña segura, con almenos una mayuscula y un numero")
        $regex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{8,}$"
        if($password -notmatch $regex){
            Write-Host "La contraseña no cumple con las politicas de seguridad, intentalo de nuevo"
        }
    } while ($password -notmatch $regex)
    

    Write-Host "A que grupo o grupos pertenece el usuario [1-3]"
    Write-Host "1. Reprobados"
    Write-Host "2. Recursadores"
    Write-Host "Ninguno (solo el publico)"
    $opc = Read-Host("Opcion")

    $CreateUserFTPUser = $ADSI.Create("User","$username")
    $CreateUserFTPUser.SetInfo()
    $CreateUserFTPUser.SetPassword("$password")
  
    $CreateUserFTPUser.SetInfo()
    
    $UserAccount = New-Object System.Security.Principal.NTAccount("$username")
    $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
    
    New-Item -Path "C:\FTP\LocalUser\$username" -ItemType Directory
    icacls "C:\FTP\LocalUser\$username" /grant "$($username):(OI)(CI)F"
    icacls "C:\FTP\LocalUser\Public" /grant "$($username):(OI)(CI)F"
    New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$username\Public" -Target "C:\FTP\LocalUser\Public"
    icacls "C:\FTP\LocalUser\$username\Public" /grant "$($username):(OI)(CI)F"
    New-Item -Path "C:\FTP\LocalUser\$username\$username" -ItemType Directory
    icacls "C:\FTP\LocalUser\$username\$username" /grant "$($username):(OI)(CI)F"
    icacls "C:\FTP\LocalUser\$username\Public" /grant "$($username):(OI)(CI)F"
    echo $username
    switch($opc){
        '1'{
              $Group = [ADSI]"WinNT://$env:ComputerName/Reprobados,Group"
              $User = [ADSI]"WinNT://$SID"
              $Group.Add($User.Path)
              icacls "C:\FTP\Reprobados" /grant "$($username):(OI)(CI)F"
              New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$username\Reprobados" -Target "C:\FTP\Reprobados"
              icacls "C:\FTP\LocalUser\$username\Reprobados" /grant "$($username):(OI)(CI)F"
              
            
        }
        '2'{
            $Group = [ADSI]"WinNT://$env:ComputerName/Recursadores,Group"
              $User = [ADSI]"WinNT://$SID"
              $Group.Add($User.Path)
              icacls "C:\FTP\Recursadores" /grant "$($username):(OI)(CI)F"
              New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$username\Recursadores" -Target "C:\FTP\Recursadores"
              icacls "C:\FTP\LocalUser\$username\Recursadores" /grant "$($username):(OI)(CI)F"
            
        }
        
    }

    #Aqui para crear usuario
   
}




icacls "C:\FTP\Reprobado1"