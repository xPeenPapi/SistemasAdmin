. .\FuncionesDHCP.ps1
. .\FuncionesWindows.ps1

# Mostrar adaptadores disponibles
Write-Host "Adaptadores de red disponibles:"
Get-NetAdapter

# Solicitar entradas al usuario
$adaptador = Read-Host "Introduce el nombre del adaptador de red (por ejemplo: Ethernet 2)"
$ip = Read-Host "Introduce la IP estática"
$netMask = Read-Host "Introduce el valor del prefijo (CIDR)"
$nombreRed = Read-Host "Introduce el nombre de la red"
$rangoInicial = Read-Host "Introduce el rango inicial de direcciones IP"
$rangoFinal = Read-Host "Introduce el rango final de direcciones IP"
$subnetMask = Read-Host "Introduce la máscara de subred"

# Llamar a la función principal
Configurar-DHCP -Adaptador $adaptador -Ip $ip -NetMask $netMask -NombreRed $nombreRed -RangoInicial $rangoInicial -RangoFinal $rangoFinal -SubnetMask $subnetMask
