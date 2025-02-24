function Configurar_DHCP {
    param (
        [string]$Adaptador,
        [string]$Ip,
        [int]$NetMask,
        [string]$NombreRed,
        [string]$RangoInicial,
        [string]$RangoFinal,
        [string]$SubnetMask
    )

    # Instalar la característica de DHCP
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
    Write-Host "La característica de DHCP se ha instalado correctamente." -ForegroundColor Green

    # Configurar el adaptador de red
    Write-Host "Configurando la IP estática en el adaptador $Adaptador..."
    New-NetIPAddress -InterfaceAlias $Adaptador -IPAddress $Ip -PrefixLength $NetMask -ErrorAction Stop

    # Crear el alcance DHCP
    Write-Host "Creando el alcance DHCP para la red $NombreRed..."
    Add-DhcpServerv4Scope -Name $NombreRed -StartRange $RangoInicial -EndRange $RangoFinal -SubnetMask $SubnetMask -ErrorAction Stop

    Write-Host "El servidor DHCP se ha configurado exitosamente con el nombre '$NombreRed'." -ForegroundColor Green
}
