Install-WindowsFeature -Name DHCP -IncludeManagementTools

$adaptador = "Ethernet 2"
$netMask = "24"

Get-NetAdapter

$ip = Read-Host "Introduce la IP estática"

New-NetIPAddress -InterfaceAlias $adaptador -IPAddress $ip -PrefixLength $netMask

$nombreRed = Read-Host "Introduce el nombre de la red"
$rangoInicial = Read-Host "Introduce el rango inicial"
$rangoFinal = Read-Host "Introduce el rango final"

Add-DhcpServerv4Scope -Name "$nombreRed" -StartRange $rangoInicial -EndRange $rangoFinal -SubnetMask 255.255.255.0

Write-Host "El servidor DHCP se ha configurado exitosamente con el nombre '$nombreRed'."
