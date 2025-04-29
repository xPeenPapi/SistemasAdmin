function Instalar-ActiveDirectory(){
    if(-not((Get-WindowsFeature -Name AD-Domain-Services).Installed)){
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    }
    else{
        Write-Host "Active Directory ya se encuentra instalado, omitiendo instalación..."
    }
}

function Configurar-DominioAD(){
    if((Get-WmiObject Win32_ComputerSystem).Domain -eq "google.com"){
        echo "El dominio ya se encuentra configurado, omitiendo configuración..."
    }
    else{
        Import-Module ADDSDeployment
        Install-ADDSForest -DomainName "google.com" -DomainNetbiosName "GOOGLE" -InstallDNS
    }
}

function Crear-UnidadesOrganizativas(){
    try {
        if((Get-ADOrganizationalUnit -Filter "Name -eq 'cuates'") -and (Get-ADOrganizationalUnit -Filter "Name -eq 'no cuates'")){
            echo "Las unidades organizativas ya se encuentran creadas en este equipo"
        }
        else{
            New-ADOrganizationalUnit -Name "cuates"
            New-ADOrganizationalUnit -Name "no cuates"
            echo "Organizaciones creadas correctamente"
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}

function Es-ContrasenaValida($contrasena) {
    return ($contrasena.Length -ge 8 -and
            $contrasena -match '[A-Z]' -and
            $contrasena -match '[a-z]' -and
            $contrasena -match '\d' -and
            $contrasena -match '[^a-zA-Z\d]')
}

function Crear-Usuario(){
    try {
        $nombreUsuario = Read-Host "Ingresa el nombre de usuario"
        $contrasena = Read-Host "Ingresa la contrasena"
        $organizacion = Read-Host "Ingresa la unidad organizativa de la que sera parte el usuario (cuates/no cuates)"
        if(($organizacion -ne "cuates") -and ($organizacion -ne "no cuates")){
            echo "Ingresa una unidad organizativa valida (cuates/no cuates)"
        }
        elseif(-not(Es-ContrasenaValida -contrasena $contrasena)){
            echo "El password no es lo suficientemente seguro"
        }
        else{
            New-ADUser -Name $nombreUsuario -GivenName $nombreUsuario -Surname $nombreUsuario -SamAccountName $nombreUsuario -UserPrincipalName "$nombreUsuario@google.com" -Path "OU=$organizacion,DC=google,DC=com" -AccountPassword (ConvertTo-SecureString $contrasena -AsPlainText -Force) -Enabled $true
            Add-ADGroupMember -Identity "Administradores" -Members $nombreUsuario
            echo "Cuenta creada correctamente"
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}

while($true){
    echo "Menu de opciones"
    echo "1. Instalar y configurar Active Directory"
    echo "2. Crear unidades organizativas"
    echo "3. Crear usuario"
    echo "4. Salir"
    $opc = Read-Host "Selecciona una opcion"

    if($opc -eq "4"){
        echo "Saliendo..."
        break
    }

    switch($opc){
        "1"{
            Instalar-ActiveDirectory
            Configurar-DominioAD
        }
        "2"{
            Crear-UnidadesOrganizativas
        }
        "3"{
            Crear-Usuario
        }
        default { echo "Selecciona una opcion valida (1..4)"}
    }
    echo ""
}