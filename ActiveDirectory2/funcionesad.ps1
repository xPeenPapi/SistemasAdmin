function InstalarAD(){
    if(-not((Get-WindowsFeature -Name AD-Domain-Services).Installed)){
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    }
    else{
        Write-Host "AD ya se encuentra instalado, omitiendo instalación" -ForegroundColor Yellow
    }
}

function ConfigurarDominioAD(){
    if((Get-WmiObject Win32_ComputerSystem).Domain -eq "5demayo.com"){
        Write-Host "El dominio ya se encuentra configurado" -ForegroundColor Yellow
    }
    else{
        Import-Module ADDSDeployment
        Install-ADDSForest -DomainName "5demayo.com" -DomainNetbiosName "5DEMAYO" -InstallDNS
        New-ADOrganizationalUnit -Name "cuates"
        New-ADOrganizationalUnit -Name "nocuates"
        Write-Host "Organizaciones creadas correctamente" -ForegroundColor Green
    }
}


function CrearUsuario(){
    try {
        $usuario = Read-Host "Ingresa el nombre de usuario"
        $password = Read-Host "Ingresa la contrasena"
        $organizacion = Read-Host "Ingresa la unidad organizativa de la que sera parte el usuario (cuates/nocuates)"

        if(($organizacion -ne "cuates") -and ($organizacion -ne "nocuates")){
            Write-Host "Ingresa una unidad organizativa valida (cuates/nocuates)" -ForegroundColor Red
            return
        }

        New-ADUser -Name $usuario -GivenName $usuario -Surname $usuario -SamAccountName $usuario `
            -UserPrincipalName "$usuario@5demayo.com" `
            -Path "OU=$organizacion,DC=5demayo,DC=com" `
            -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
            -Enabled $true

        Set-ADUser -Identity $usuario -ChangePasswordAtLogon $true

        Add-ADGroupMember -Identity "Administradores" -Members $usuario

        # Asignar al grupo correspondiente
        if ($organizacion -eq "cuates") {
            Add-ADGroupMember -Identity "grupo1" -Members $usuario
        } elseif ($organizacion -eq "nocuates") {
            Add-ADGroupMember -Identity "grupo2" -Members $usuario
        }

        Write-Host "Usuario agregado con éxito y asignado al grupo correspondiente" -ForegroundColor Green
    }
    catch {
        echo $Error[0].ToString()
    }
}

function CrearGruposAD() {
    try {
        if (-not (Get-ADGroup -Filter "Name -eq 'grupo1'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name "grupo1" -GroupScope Global -Path "OU=cuates,DC=5demayo,DC=com"
            Write-Host "Grupo1 creado exitosamente" -ForegroundColor Green
        } else {
            Write-Host "Grupo1 ya existe" -ForegroundColor Yellow
        }

        if (-not (Get-ADGroup -Filter "Name -eq 'grupo2'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name "grupo2" -GroupScope Global -Path "OU=nocuates,DC=5demayo,DC=com"
            Write-Host "Grupo2 creado exitosamente" -ForegroundColor Green
        } else {
            Write-Host "Grupo2 ya existe" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error al crear grupos: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function ConfigurarPermisosdeGruposAD() {
    Import-Module ActiveDirectory
    Import-Module FileServerResourceManager

    function New-LogonHoursArray {
        param(
            [int] $startHour,          # Hora de inicio del rango de acceso permitido
            [int] $endHour,            # Hora de finalización del rango de acceso permitido
            [int] $utcOffset           # Ajuste de zona horaria o simplemente un valor para que cuadren las horas AJSJAJA
        )

        $bits = New-Object byte[] 168  # Crea un arreglo de bytes de 168 elementos, uno por cada hora de la semana 

        for ($hour = 0; $hour -lt 168; $hour++) {  # Itera a través de cada hora en la semana (de 0 a 167)
            $localHour = ($hour + $utcOffset) % 24  # Ajusta la hora local según el desfase horario especificado
            if ($localHour -lt 0) { $localHour += 24 }  # Si el valor de la hora local es negativo, lo ajusta sumándole 24

            if ($startHour -le $endHour) {  # Si la hora de inicio es menor o igual a la hora de fin (rango horario sin cruzar medianoche)
                if ($localHour -ge $startHour -and $localHour -lt $endHour) { $bits[$hour] = 1 }  # Marca como 1 (permitido) las horas dentro del rango
            } else {  # Si el rango horario cruza medianoche
                if ($localHour -ge $startHour -or $localHour -lt $endHour) { $bits[$hour] = 1 }  # Marca como 1 las horas que están en el rango cruzadO
            }
        }

        $bytes = for ($i = 0; $i -lt 21; $i++) {  # Itera en bloques de 8 horas para convertir los valores de bits a bytes
            $val = 0  # Inicializa el valor del byte
            for ($bit = 0; $bit -lt 8; $bit++) {  # Itera a través de cada bit (0-7) para cada bloque de 8 horas
                $val += $bits[$i * 8 + $bit] -shl $bit  # Usa desplazamiento de bits para construir el byte con los valores de bits
            }
            [byte]$val  # Convierte el valor acumulado en un byte
        }

        return ,$bytes  # Devuelve el arreglo de bytes resultante
    }
    
    # --- Creación de un perfil movil ---
    
    $rutaBase = "C:\UsuariosMoviles"

    # Asegurarse de que exista la carpeta base
    if (!(Test-Path $rutaBase)) {
        New-Item -ItemType Directory -Path $rutaBase
    }

    # Procesar cada grupo
    $grupos = @(
        @{Nombre="grupo1"},
        @{Nombre="grupo2"}
    )

    foreach ($grupo in $grupos) {
        $usuarios = Get-ADGroupMember -Identity $grupo.Nombre -Recursive | Where-Object { $_.objectClass -eq "user" }

        foreach ($usuario in $usuarios) {
            $nombre = $usuario.SamAccountName
            $carpetaPerfil = Join-Path $rutaBase $nombre
            $rutaUNC = "\\$(hostname)\UsuariosMoviles\$nombre"

            # Crear carpeta de perfil si no existe
            if (!(Test-Path $carpetaPerfil)) {
                New-Item -ItemType Directory -Path $carpetaPerfil -Force
                # Dar control total al usuario
                $acl = Get-Acl $carpetaPerfil
                $perm = New-Object System.Security.AccessControl.FileSystemAccessRule("$nombre", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($perm)
                Set-Acl -Path $carpetaPerfil -AclObject $acl
            }

            # Establecer perfil móvil
            Set-ADUser -Identity $nombre -ProfilePath $rutaUNC
        }

        Write-Host "Configuración aplicada al grupo $($grupo.Nombre)" -ForegroundColor Green
    }

    # --- Restricción de horario de inicio de sesión ---
    $lh1 = [byte[]](New-LogonHoursArray -startHour 8 -endHour 15 -utcOffset -8) # La verdad ya no quise saber porque no daban las horas y le puse 8 porque así sí jalaba
    $lh2 = [byte[]](New-LogonHoursArray -startHour 15 -endHour 2 -utcOffset -8) # La verdad ya no quise saber porque no daban las horas y le puse 8 porque así sí jalaba

    $miembros1 = Get-ADGroupMember -Identity "grupo1" -Recursive | Where-Object ObjectClass -eq 'user'
    foreach ($usuario in $miembros1) {
        Set-ADUser -Identity $usuario.SamAccountName -Replace @{logonHours = $lh1}
    }

    $miembros2 = Get-ADGroupMember -Identity "grupo2" -Recursive | Where-Object ObjectClass -eq 'user'
    foreach ($usuario in $miembros2) {
        Set-ADUser -Identity $usuario.SamAccountName -Replace @{logonHours = $lh2}
    }

    # --- Restricción de MB ---
    <# 
        Para grupo1 = UO cuates
        Para grupo2 = UO nocuates 
    #>
    Import-Module GroupPolicy

    try {
        # Crear las GPO si no existen
        if (-not (Get-GPO -Name "CuotaGrupo1" -ErrorAction SilentlyContinue)) {
            New-GPO -Name "CuotaGrupo1" | Out-Null
            Write-Host "GPO 'CuotaGrupo1' creada" -ForegroundColor Green
        } else {
            Write-Host "GPO 'CuotaGrupo1' ya existe" -ForegroundColor Yellow
        }

        if (-not (Get-GPO -Name "CuotaGrupo2" -ErrorAction SilentlyContinue)) {
            New-GPO -Name "CuotaGrupo2" | Out-Null
            Write-Host "GPO 'CuotaGrupo2' creada" -ForegroundColor Green
        } else {
            Write-Host "GPO 'CuotaGrupo2' ya existe" -ForegroundColor Yellow
        }

        # Establecer valores de MaxProfileSize
        Set-GPRegistryValue -Name "CuotaGrupo1" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
            -ValueName "MaxProfileSize" `
            -Type DWord -Value 5000

        Set-GPRegistryValue -Name "CuotaGrupo2" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
            -ValueName "MaxProfileSize" `
            -Type DWord -Value 10000

        # Vincular las GPOs a sus respectivas OUs
        New-GPLink -Name "CuotaGrupo1" -Target "OU=cuates,DC=5demayo,DC=com" -Enforced "Yes"

        New-GPLink -Name "CuotaGrupo2" -Target "OU=nocuates,DC=5demayo,DC=com" -Enforced "Yes"


        Write-Host "Límites de perfil aplicados correctamente" -ForegroundColor Green
    }
    catch {
        Write-Host "Error al aplicar las restricciones de MB: $($_.Exception.Message)" -ForegroundColor Red
    }

    # --- Restricción de notepad ---
    try{
        # GPO para grupo1: solo se permite notepad.exe
        if (-not (Get-GPO -Name "SoloNotepadGrupo1" -ErrorAction SilentlyContinue)) {
            New-GPO -Name "SoloNotepadGrupo1" | Out-Null
        }

        Set-GPRegistryValue -Name "SoloNotepadGrupo1" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
            -ValueName "RestrictRun" -Type DWord -Value 1

        Set-GPRegistryValue -Name "SoloNotepadGrupo1" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\RestrictRun" `
            -ValueName "1" -Type String -Value "notepad.exe"

        # GPO para grupo2: se bloquea notepad.exe
        if (-not (Get-GPO -Name "BloquearNotepadGrupo2" -ErrorAction SilentlyContinue)) {
            New-GPO -Name "BloquearNotepadGrupo2" | Out-Null
        }

        Set-GPRegistryValue -Name "BloquearNotepadGrupo2" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
            -ValueName "DisallowRun" -Type DWord -Value 1

        Set-GPRegistryValue -Name "BloquearNotepadGrupo2" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" `
            -ValueName "1" -Type String -Value "notepad.exe"

        # Vincular las GPOs a sus respectivas OUs
        New-GPLink -Name "SoloNotepadGrupo1" -Target "OU=cuates,DC=5demayo,DC=com" -Enforced "Yes"

        New-GPLink -Name "BloquearNotepadGrupo2" -Target "OU=nocuates,DC=5demayo,DC=com" -Enforced "Yes"
    }catch{
        Write-Host "Error al aplicar las restricciones para notepad: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function ConfigurarPoliticaContraseñaAD {
    param (
        [string]$Dominio = "5demayo.com"
    )

    Import-Module ActiveDirectory

    # Preguntar por opciones de política
    $respuesta = Read-Host "¿Requerir contraseñas seguras (complejidad)? [s/n]"
    $complejidad = $false
    if ($respuesta -match '^[sS]$') { $complejidad = $true }

    $respuesta = Read-Host "¿Establecer longitud mínima de contraseña? [s/n]"
    $longitud = 8
    if ($respuesta -match '^[sS]$') {
        $inputLong = Read-Host "Ingresa la longitud mínima (recomendado 8)"
        if ($inputLong -match '^\d+$') { $longitud = [int]$inputLong }
    }

    $respuesta = Read-Host "¿Habilitar caducidad de contraseñas? [s/n]"
    $maxAge = "30.00:00:00"
    if ($respuesta -match '^[sS]$') {
        $dias = Read-Host "¿Cada cuántos días deben caducar las contraseñas? (ej. 30)"
        if ($dias -match '^\d+$') {
            $maxAge = "$dias.00:00:00"
        }
    }

    # Aplicar política de contraseñas directamente al dominio
    Set-ADDefaultDomainPasswordPolicy -Identity $Dominio `
        -MinPasswordLength $longitud `
        -ComplexityEnabled $complejidad `
        -PasswordHistoryCount 1 `
        -MinPasswordAge "1.00:00:00" `
        -MaxPasswordAge $maxAge

    Write-Host "Política de contraseñas aplicada al dominio $Dominio" -ForegroundColor Green

    # Forzar cambio de contraseña al siguiente inicio de sesión
    $respuesta = Read-Host "¿Deseas que todos los usuarios deban cambiar su contraseña al iniciar sesión? [s/n]"
    if ($respuesta -match '^[sS]$') {
        Get-ADUser -Filter * -SearchBase (Get-ADDomain).DistinguishedName | ForEach-Object {
            try {
                Set-ADUser $_ -ChangePasswordAtLogon $true
                Write-Host "Se marcó para cambio de contraseña: $($_.SamAccountName)"
            } catch {
                Write-Warning "No se pudo actualizar el usuario $($_.SamAccountName): $_"
            }
        }
        Write-Host "Todos los usuarios deben cambiar su contraseña al iniciar sesión." -ForegroundColor Yellow
    }
}

# Habilita auditoría para eventos de inicio de sesión y cambios en AD
function HabilitarAuditoriaAD() {
    try {
        Write-Host "Habilitando auditoría avanzada para Active Directory..." -ForegroundColor Yellow

        # Habilitar categorías generales (éxito y error)
        auditpol /set /category:"Inicio/cierre de sesión" /success:enable /failure:enable
        auditpol /set /category:"Inicio de sesión de la cuenta" /success:enable /failure:enable
        auditpol /set /subcategory:"Acceso del servicio de directorio" /success:enable /failure:enable
        auditpol /set /subcategory:"Cambios de servicio de directorio" /success:enable /failure:enable
        auditpol /set /subcategory:"Administración de cuentas de usuario" /success:enable /failure:enable
        auditpol /set /subcategory:"Administración de cuentas de equipo" /success:enable /failure:enable
        

        Write-Host "Auditoría avanzada habilitada correctamente para Active Directory." -ForegroundColor Green

        # Aviso sobre el Visor de eventos
        Write-Host "Los eventos se registrarán en el Visor de eventos -> Registros de Windows -> Seguridad." -ForegroundColor Yellow # Para recordar donde se guardan
    }
    catch {
        Write-Host "Error al habilitar la auditoría: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function ConfigurarMFAAD {
    param (
        [string]$NombreUsuario = '',
        [string]$Issuer = '5demayo.com'
    )

    $NombreUsuario = Read-Host "Ingrese el nombre de usuario (incluyendo el dominio)"

    # Definir el alfabeto Base32
    $Script:Base32Charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

    # Generar clave secreta en Base32
    $SecretLength = 10
    $byteArrayForSecret = [byte[]]::new($SecretLength)
    [Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($byteArrayForSecret, 0, $SecretLength)

    $binaryString = -join $byteArrayForSecret.ForEach{
        [Convert]::ToString($_, 2).PadLeft(8, '0')
    }

    $Base32Secret = [regex]::Replace($binaryString, '.{5}', {
        param($Match)
        $Script:Base32Charset[[Convert]::ToInt32($Match.Value, 2)]
    })


    # Construir URI TOTP
    $otpUri = "otpauth://totp/{0}?secret={1}&issuer={2}" -f (
        [Uri]::EscapeDataString($NombreUsuario),
        $Base32Secret,
        [Uri]::EscapeDataString($Issuer)
    )

    $encodedUri = [Uri]::EscapeDataString($otpUri)
    $qrCodeUri = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$encodedUri"

    # Mostrar datos
    Write-Host "`n--- Configuración MFA ---"
    Write-Host "Usuario         : $NombreUsuario"
    Write-Host "Emisor          : $Issuer"
    Write-Host "Secreto         : $Base32Secret"
    Write-Host "URI TOTP        : $otpUri"
    Write-Host "QR para escanear:"
    Write-Host $qrCodeUri

    # Opcional: Abrir el navegador automáticamente
    Start-Process $qrCodeUri

    return [PSCustomObject]@{
        Usuario    = $NombreUsuario
        Issuer     = $Issuer
        Secreto    = $Base32Secret
        QrCode     = $qrCodeUri
    }
}