function Configurar_DHCP {
    param (
        [string]$adaptador,
        [string]$ip,
        [int]$netMask,
        [string]$nombreRed,
        [string]$rangoInicial,
        [string]$rangoFinal,
        [string]$subnetMask
    )

    Install-WindowsFeature -Name DHCP -IncludeManagementTools
    Write-Host "La característica de DHCP se ha instalado correctamente." -ForegroundColor Green

    Write-Host "Configurando la IP estática en el adaptador $Adaptador..."
    New-NetIPAddress -InterfaceAlias $Adaptador -IPAddress $Ip -PrefixLength $NetMask -ErrorAction Stop

    Write-Host "Creando el alcance DHCP para la red $NombreRed..."
    Add-DhcpServerv4Scope -Name $NombreRed -StartRange $RangoInicial -EndRange $RangoFinal -SubnetMask $SubnetMask -ErrorAction Stop

    Write-Host "El servidor DHCP se ha configurado exitosamente con el nombre '$NombreRed'." -ForegroundColor Green
}

function Configurar_DNS {
    param (
        [string]$dominio,
        [string]$ip
  
    )
    # Instalar la característica de DNS
    Write-Host "Instalando la característica de DNS..." -ForegroundColor Yellow
    Install-WindowsFeature -Name DNS -IncludeManagementTools
    Write-Host "La característica de DNS se ha instalado correctamente." -ForegroundColor Green

    # Crear la zona DNS primaria
    Write-Host "Creando la zona DNS primaria para el dominio '$dominio'..." -ForegroundColor Yellow
    Add-DnsServerPrimaryZone -Name $dominio -ZoneFile "$dominio.dns"
    Write-Host "Zona DNS primaria creada correctamente." -ForegroundColor Green

    # Agregar un registro A para el servidor DNS
    Write-Host "Agregando un registro A para 'www.$dominio'..." -ForegroundColor Yellow
    Add-DnsServerResourceRecordA -IPv4Address $ip -Name "www" -ZoneName $dominio
    Write-Host "Registro A agregado correctamente." -ForegroundColor Green

    Write-Host "El servidor DNS se ha configurado exitosamente para el dominio '$dominio'." -ForegroundColor Green
}