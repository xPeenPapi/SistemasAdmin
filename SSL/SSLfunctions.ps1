

function Configsslftp{
    #New-SelfSignedCertificate -DnsName "ftp.PruebaFTP.com" -CertStoreLocation "Cert:\LocalMachine\My"
    $cert = Get-Item "Cert:\LocalMachine\My\BF7C0CBEC75CBBE7CD79BA70B7002070A221A080" #Selecciona el certificado, si generaste otro cambia la ultima parte de la ruta por el nuevo
    echo $cert
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name "ftpServer.security.ssl.serverCertHash" -Value BF7C0CBEC75CBBE7CD79BA70B7002070A221A080 #Asigne a mano el ssl porque ajá pero puedes hacerlo con un comando que sale mas abajo
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name "ftpServer.security.ssl.serverCertStoreName" -Value "My"
    #Lo de arriba signa el certificado ssl al servicio ftp

    #Lo de abajo cambia las politicas ssl del fpt para habilitar ssl
    $SSLPolicy = @(
       'ftpServer.security.ssl.controlChannelPolicy',
       'ftpServer.security.ssl.dataChannelPolicy'
    )
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name $SSLPolicy[0] -Value 1
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name $SSLPolicy[1] -Value 1
    Restart-Service ftpsvc
}

function ConfigsslIIS{
    param (
        [int]$newPort
      )
    #New-SelfSignedCertificate -DnsName "http.httpsite.com" -CertStoreLocation "Cert:\LocalMachine\My"
    $cert = Get-Item "Cert:\LocalMachine\My\BF7C0CBEC75CBBE7CD79BA70B7002070A221A080"
    
    echo $cert.Thumbprint
   
    #Creará una conexion https
    $binding = Get-WebBinding -Name "Default Web Site" -Protocol "https"
    $binding.AddSslCertificate($cert.GetCertHashString(),"my") #Asigna el certificado ssl

    $running = $true
    while ($running){
        #Se le debe asignar un puerto diferetne a esta conexion 
        $newPort = Read-Host "Introduce el puerto para HTTPS correrá el servicio"
        if(Comprobarpuerto -newPort $newPort){
        $puertovalido = $true
        Write-Host "Puerto Valido, se procederá a la configuracion"
        
        $running = $false
                
        }else{
            $puertovalido = $false
             Write-Host "Puerto invalido o está en uso ingresa otro dato"
         
        }
    }
    
    #Crea la conexion con el nuevo puerto
    New-WebBinding -Name "Default Web Site" -IPAddress "*" -port $newPort -Protocol "https"
    Get-WebBinding -Name "Default Web Site" -Protocol "https" -Port 444 | ForEach-Object {$_.AddSslCertificate($cert.GetCertHashString(),"MY")}
    iisreset
}

function ConfigsslNginx{
    $cert = Get-Item "Cert:\LocalMachine\My\BF7C0CBEC75CBBE7CD79BA70B7002070A221A080"
    #Exporta el certificado a la carpeta de nginx
    Export-PfxCertificate -Cert $cert -FilePath C:\nginx\certificado.pfx -Password (ConvertTo-SecureString -String "500DeCilantro" -Force -AsPlainText)
    Export-Certificate -Cert $cert -FilePath "C:\nginx\certificado.crt"
    #Crea los archivos que necesita nginx a partir del certificado
    openssl pkcs12 -in C:\nginx\certificado.pfx -clcerts -nokeys -out C:\nginx\clave.pem -passin pass:500DeCilantro
    openssl pkcs12 -in C:\nginx\certificado.pfx -nocerts -nodes -out C:\nginx\clave.key -passin pass:500DeCilantro

    $running = $true
    while ($running){
        #Pide un puerto para https
        $newPort = Read-Host "Introduce el puerto para HTTPS de el servicio"
        if(Comprobarpuerto -newPort $newPort){
        $puertovalido = $true
        Write-Host "Puerto Valido, se procederá a la configuracion"
        
        $running = $false
                
        }else{
            $puertovalido = $false
             Write-Host "Puerto invalido o está en uso ingresa otro dato"
         
        }
    }

    $nginxconfig = "C:\nginx\nginx-$version\conf\nginx.conf"

    # Lee el contenido del archivo

    $config = Get-Content $nginxConfig -Raw

# Definir la nueva configuración HTTPS
    $newHttpsConfig = @"
    server {
        listen $newPort ssl;
        server_name localhost;

        ssl_certificate C:\\nginx\clave.pem;
        ssl_certificate_key C:\\nginx\clave.key;

        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout 5m;

        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            root html;
            index index.html index.htm;
        }
    }
"@

# Edita el arhivo de configuracion para descomentar la seccion de httos y añadir el puerto y la ruta de los certificados
    $config = $config -replace '(?s)# HTTPS server.*?}', "# HTTPS server`r`n$newHttpsConfig"
    $config | Set-Content -Path $nginxconfig

}

function ConfigsslCaddy{
    #Lo mismo que en nginx
    $cert = Get-Item "Cert:\LocalMachine\My\BF7C0CBEC75CBBE7CD79BA70B7002070A221A080"
    Export-PfxCertificate -Cert $cert -FilePath C:\caddy\certificado.pfx -Password (ConvertTo-SecureString -String "500DeCilantro" -Force -AsPlainText)
    Export-Certificate -Cert $cert -FilePath "C:\caddy\certificado.crt"
    openssl pkcs12 -in C:\caddy\certificado.pfx -nocerts -nodes -out C:\caddy\clave.key -passin pass:500DeCilantro

    $running = $true
    while ($running){
        $newPort = Read-Host "Introduce el puerto para HTTPS de el servicio"
        if(Comprobarpuerto -newPort $newPort){
        $puertovalido = $true
        Write-Host "Puerto Valido, se procederá a la configuracion"
        
        $running = $false
                
        }else{
            $puertovalido = $false
             Write-Host "Puerto invalido o está en uso ingresa otro dato"
         
        }
    }

    $httpsConfig = @"
    https://localhost:$newPort {
    tls internal
    root * C:/caddy/www/
    file_server
}

"@
#Añade añ final del caddyfile la seccion para https
Add-Content -Path C:\caddy\Caddyfile -Value $httpsConfig
C:\caddy\caddy.exe fmt --overwrite
   
}