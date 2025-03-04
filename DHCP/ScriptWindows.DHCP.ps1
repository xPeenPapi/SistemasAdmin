. .\FuncionesDHCP.ps1
. .\FuncionesWindows.ps1

Write-Host "Adaptadores de red disponibles:"
Get-NetAdapter

$adaptador = Read-Host "Introduce el nombre del adaptador de red (por ejemplo: Ethernet 2)"
$ip = Read-Host "Introduce la IP estática"
$netMask = Read-Host "Introduce el valor del prefijo (CIDR)"
$nombreRed = Read-Host "Introduce el nombre de la red"
$rangoInicial = Read-Host "Introduce el rango inicial de direcciones IP"
$rangoFinal = Read-Host "Introduce el rango final de direcciones IP"
$subnetMask = Read-Host "Introduce la máscara de subred"

if (validar_ip $ip -and validar_mascaraCidr $netMask -and validar_subred $subnetMask -and validar_ip $rangoInicial -and validar_ip $rangoFinal) {
    
}

Configurar_DHCP -Adaptador $adaptador -Ip $ip -NetMask $netMask -NombreRed $nombreRed -RangoInicial $rangoInicial -RangoFinal $rangoFinal -SubnetMask $subnetMask
