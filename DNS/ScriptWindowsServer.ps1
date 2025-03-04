. .\FuncionesDHCP.ps1
. .\FuncionesWindows.ps1


$ip = Read-Host "Introduce la IP"
$dominio = Read-Host "Introduce el nombre del dominio "

if (validar_ip $ip -and validar_dominio $dominio ) {
    
}

Configurar_DNS  -ip $ip dominio $dominio
