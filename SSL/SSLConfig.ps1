. .\SistemasAdmin\SSL\ftpConfig.ps1
. .\SistemasAdmin\SSL\SSLfunctions.ps1
. .\SistemasAdmin\SSL\httpconfig.ps1
. .\SistemasAdmin\SSL\httpfunctions.ps1

#Descargamos openssl que se necesita para crear los arhcivos de los certificados para caddy y nginx
choco install openssl -y
Import-Module WebAdministration

#New-SelfSignedCertificate -DnsName "ftp.PruebaFTP.com" -CertStoreLocation "Cert:\LocalMachine\My"
#Lo de arriba genera el certificado ssl descomentalo y ejecutalo si aun no lo tienes, el dnsName puede ser cualquiera, y se usa de base el mismo para todo

if((Get-WindowsFeature -Name Web-FTP-Server).Installed){
    Write-Host "FTP instalado"
}else{
    Write-Host "ftp no instalado, se va a configurar su instalacion"
    #Converti en funcion el archivo configuracion ftp y lo llamé
    Configftp
}

$running = $true

while($running){
    Write-Host "Quieres configurar SSL para ftp [S-N]"
    $opc = Read-Host "Opcion"
    if($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si"){
        Configsslftp
        $running = $false
    }elseif($opc.ToLower() -eq "no" -or $opc.ToLower() -eq "n"){
        $running = $false
    }else{
        Write-Host "Opcion Invalida"
    }
}


$running = $true

$running = $true
while($running){
        write-host "Quieres solo intsalar los servicios o ver las opciones dispobibles en el servidor ftp [1-2]"
        Write-Host "1. Instalar servicios"
        Write-Host "2. Ver FTP"
        $opc = Read-Host "opcion:"
        switch ($opc){
            '1'{
                httpconfig
                $running = $false
            }
            '2'{
                elegirserviciosftp
                $running = $false
            }
            default{
                Write-Host "Opcion invalida"
            }
        }

        
      }
 