
Install-WindowsFeautre -Name DNS
Install-WindowsFeature -Name RSAT-DNS-Server
$dominio = Read-Host "Introduce el nombre del dominio"

$ipPattern = '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

do {
    $ip = Read-Host "Introduce la IP para el dominio"
    if ($ip -match $ipPattern) {
        break
    } else {
        Write-Host "Dirección IP no válida. Inténtalo de nuevo."
    }
} while ($true)

Add-DnsServerPrimaryZone -Name $dominio -ZoneFile "$dominio.dns"
Add-DnsServerResourceRecordA -IPv4Address $ip -Name "www" -ZoneName $dominio
Write-Host "Zona DNS '$dominio' creada y configurada correctamente."