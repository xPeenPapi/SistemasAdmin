$ftpbase = "ftp://192.168.100.73" #Cammbia esto en la escuela

function Comprobarpuerto{
  param (
    [int]$newPort
  )
  
  $puertosinvalidos = (1,7,9,11,13,17,19,20,21,22,23, 25,37,42,53,69,77,79,87,95,101,102,103,104,109,110,111,113,115,117,119,123,135,
  137,138,139,143,161,162,171,179,194,389,427,465,512, 513,514,515,526,530,531,532,540,548,554,556,563,587,601,636,993,995,2049,3659,
   4045,6000)
  $netstatoutput = netstat -ano | Select-String ":$newPort "

  if($newPort -gt 1 -and $newPort -lt 65535 -and $puertosinvalidos -notcontains $newPort){
    if($netstatoutput){
        return $false
        Write-Host "El puerto esta en uso"
      }else{
        return $true
        Write-Host "Puerto Valido, se procedera a la instalacion"
      }
  }else{
    return $false
    echo "Puerto introducido invalido, los posibles puertos validos est�n entre el 1024 y el 65535"
  }
  
}

#Esta funcion descomprime caddy e incia el servicio
function CompileCaddy{
cd C:\caddy
    Expand-Archive -Path "caddy.zip" -DestinationPath C:\caddy
    New-Item -Path "C:\caddy\www\" -ItemType "Directory"

    #creo un archivo html que mostrara el servicio al conectarnos
    New-Item -Path "C:\caddy\www\" -Name "index.html" -ItemType "File"
        $HTMLcontent = @"
    <html>
    <h1>Le juro profe que caddy est� corriendo en el puerto $newPort</h1>
</html>
"@

#Creo el caddyfile y a�ado la configuracion inicial
$HTMLcontent | Out-File -Encoding utf8 -FilePath "C:\caddy\www\index.html"
    $CaddyfileContent = @"
:$newPort {
    root * C:/caddy/www/
    file_server
}

"@
$CaddyfileContent | Out-File -Encoding utf8 -FilePath "C:\caddy\Caddyfile"
    C:\caddy\caddy.exe fmt --overwrite


#Add-Content -Path C:\caddy\Caddyfile -Value $httpsConfig

    $running = $true

    #Pregunta para activar el ssl 
    while($running){
        Write-Host "Quieres configurar SSL para Caddy [S-N]"
        $opc = Read-Host "Opcion"
        if($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si"){
            ConfigsslCaddy #Funcion que configura ssl
            $running = $false
        }elseif($opc.ToLower() -eq "no" -or $opc.ToLower() -eq "n"){
            $running = $false
        }else{
            Write-Host "Opcion Invalida"
        }
    }

    Write-Host "Iniciando Servicio..."
    Write-Host "Servicio Iniciado con Status: "
    Start-Process -FilePath "C:\caddy\caddy.exe" -ArgumentList "run" -PassThru -WindowStyle Hidden

    
 Write-Host "Iniciando Servicio..."
}

#funcion para descargar caddy desde el ftp
function DownloadCaddyFTP{
    Write-Host "Descargando archivos"
    $ftp = "$ftpbase/Caddy/$version" #Sitio ftp, uso la ip para conectarme y los archivos estan detro de la carpeta publica
    $destino = "C:\caddy\caddy.zip"

    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com") #Me conecto con usuario anonimo
    $request.EnableSsl = $true

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true} #No me acuerdo que hace pero se ocupa
        
    try{
        #En este try se hace el proceso de descarga
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $reader = New-Object System.IO.FileStream $destino, "Create"
        
        $buffer = New-Object byte[] 1024
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0){
            $reader.Write($buffer,0, $read)
        }
        $reader.Close()
        $stream.Close()
        $response.Close()
        Write-Host "Arhivo descargado"    
        CompileCaddy
    }catch{
        Write-Host "Error: $_"
    }
}

function DownloadCaddyweb{
    #Esta funcion es la forma normal de descargarlo desde la web
    $version = $version -replace "^v", ""
    $Url = "https://github.com/caddyserver/caddy/releases/download/v$version/caddy_$($version)_windows_amd64.zip"
    $OutputPath = "C:\caddy\caddy.zip"
    echo $Url
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath
    CompileCaddy
    
}

function InstallCady{
    param (
    $ftp
  )
  if($ftp -eq $false){
      #Pregunta de donde se va adescargar
      Write-Host "Quieres descargar las versiones de la web o del servicor ftp"
      Write-Host "1. Web"
      Write-Host "2. FTP"
      Write-Host " Salir"
      $opc = Read-Host "Opcion"
  }else{
    $opc = '2'
  }
    
 
  switch($opc){
    '1'{ #Obtend� las versiones de la pagina web (o en este caso de la api de github)
      Write-Host "Obteniendo versiones de Caddy"
      [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null #Recuerdas ese comando que no sabias que hacia pero se ocupaba?
                                                                                    #Hay que revertitlo porque si no la peticion al servicio web no jala xD
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
      $versions = Invoke-RestMethod -Uri "https://api.github.com/repos/caddyserver/caddy/releases" | ForEach-Object {$_.tag_name}
      $version_lts =$versions | Where-Object {$_ -notmatch "beta"} | Select-Object -First 1
      $version_dev =$versions | Where-Object {$_ -match "beta"} | Select-Object -First 1
  
      if($version_lts -eq ("")){
        Write-Host "Ha ocurrido un problema al obtener las versiones, comprueba tu conexion a internet e intenta de nuevo"
      }else{
        echo "Ultima version estable $version_lts"
          echo "Ultima version en desarrollo $version_dev"
          echo "Cual quieres instalar"
          Write-Host "[1] $version_lts"
          Write-Host "[2] $version_dev"
          Write-Host "[3] Salir"
          $opc = Read-Host "Opcion"
          switch($opc){
              '1'{
                $version = $version_lts #Variable que contiene la version seleccionada
                DownloadCaddyweb
              }
              '2'{
                $version = $version_dev
                DownloadCaddyweb
           
              }
               '3'{
                $running = $false
            
              }
              default{
                write-host "Opcion Invalida, volviendo al menu principal"
                $running = $false
        
              }
          }
          cd C:\Users\Administrador

      }
    }
    '2'{
        Write-Host "Obteniendo versiones disponibles en el servidor ftp"
        Write-Host "Las versiones disponibles son: "
        $ftp = $ftp = "$ftpbase/Caddy"
        $request = [System.Net.FtpWebRequest]::Create($ftp) #Crea la peticion para el servicor ftp
        $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory #Indica que lo que va a recibir es una lista de directorios
        $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com") #Conecta con usuario anonymo(recuerda los archivos estan en la carpeta publica)
        $request.EnableSsl = $true #Activamos ssl para la peticion, ya que el servidor lo solicita
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true} #Aj�
        
        try{
            #Obtendr� y listar� los directorios de las versiones disponibles
            $response = $request.GetResponse()
            $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
            $directories = $reader.ReadToEnd()
            $reader.Close()
            $response.Close()
            $directories -split "`n"
        }catch{
            Write-Host "Error: $_"
        }

        #Pregunta cual quieres descargar
        Write-Host "Cual version quieres descargar"
        Write-Host "1. Version Oficial"
        Write-Host "2. Version Beta"
        Write-Host " Salir"
        $opc = Read-Host "Opcion:"
        switch($opc){
              '1'{
                $version = "caddy2.9.1.zip" #Dado a que las versiones no cambian en el ftp, ya que son las que hayamos subido, asigno el nombre del archivo a mano
                DownloadCaddyftp
              }
              '2'{
                $version = "caddy2.10.0-beta.2.zip"
                DownloadCaddyftp
           
              }
               '3'{
                $running = $false
            
              }
              default{
                write-host "Opcion Invalida, volviendo al menu principal"
                $running = $false
        
              }
          }
        }
        default{
            Write-Host "Volviendo al men�"
        }
  }
  
  
}

#Funcion para compilar, msimo proceso que con caddy
function compilenginx{
    cd C:\nginx
    $version = $version -replace '\.$',''
    echo "C:\nginx\nginx-$version\nginx.exe"

    Expand-Archive -Path "nginx.zip" -DestinationPath C:\nginx
    cd C:\nginx\nginx-$version\

    $nginxconfig = "C:\nginx\nginx-$version\conf\nginx.conf"
    $configcontent = Get-Content $nginxconfig
    #Configuramos el archivo de configuracion para cambiar el puerto
    $configcontent = $configcontent -replace 'listen       80;', "listen       $newPort;"
    Set-Content -Path $nginxconfig -Value $configcontent

    
    
    #Preguntamos si queremos ssl
    while($running){
    Write-Host "Quieres configurar SSL para Nginx [S-N]"
    $opc = Read-Host "Opcion"
    if($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si"){
        ConfigsslNginx
        $running = $false
    }elseif($opc.ToLower() -eq "no" -or $opc.ToLower() -eq "n"){
        $running = $false
    }else{
        Write-Host "Opcion Invalida"
    }
}
    
   Start-Process -FilePath ("C:\nginx\nginx-" + $version + "\nginx.exe") -WindowStyle Hidden
#Ya jala nomas falta iniciar el servicio ma�ana le das al ftp primero y luego vuelves ac�
    #& "C:\nginx\nginx-$version\nginx.exe"
     cd C:\Users\Administrador

    
}

#Descarga del ftp, mismo proceso que en caddy
function DownloadNginxftp{
    Write-Host "Descargando archivos"
    $ftp = "$ftpbase/Nginx/$bersion"
    $destino = "C:\nginx\nginx.zip"

    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true}
        
    try{
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $reader = New-Object System.IO.FileStream $destino, "Create"
        
        $buffer = New-Object byte[] 1024
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0){
            $reader.Write($buffer,0, $read)
        }
        $reader.Close()
        $stream.Close()
        $response.Close()
        Write-Host "Arhivo descargado"    
        
        compilenginx
    }catch{
        Write-Host "Error: $_"
    }
}

function DownloadNginxweb{
    $Url = "https://nginx.org/download/nginx-$($version)zip"
    $OutputPath = "C:\nginx\nginx.zip"
    echo $Url
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath
    compilenginx
    
}

function InstallNginx{

    param (
    $ftp
  )
  if($ftp -eq $false){
      #Pregunta de donde se va adescargar
      Write-Host "Quieres descargar las versiones de la web o del servicor ftp"
      Write-Host "1. Web"
      Write-Host "2. FTP"
      Write-Host "3. Salir"
      $opc = Read-Host "Opcion"
  }else{
    $opc = '2'
  }

  switch($opc){
    '1'{
          Write-Host "Obteniendo versiones de Nginx"
          [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
          [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
          $Url = Invoke-WebRequest -Uri "https://nginx.org/en/download.html" | Select-Object -ExpandProperty Content
          #echo $Url

          if($Url -match ("Mainline version.*?nginx-([\d.]+)")){
            $version_dev = $Matches[1]

          }

          if($Url -match ("Stable version.*?nginx-([\d.]+)")){
            $version_lts = $Matches[1]

          }

          echo "Ultima version estable $version_lts"
          echo "Ultima version en desarrollo $version_dev"
          echo "Cual quieres instalar"
          Write-Host "1. $version_lts"
          Write-Host "2. $version_dev"
          Write-Host " Salir"
          $opc = Read-Host "Opcion"
          switch($opc){
              '1'{
                $version = $version_lts
                DownloadNginxweb
              }
              '2'{
                $version = $version_dev
                DownloadNginxweb
           
              }
              '3'{
                    $running = $false
            
                  }
              default{
                write-host "Opcion Invalida, volviendo al menu principal"
                $running = $false
        
              }
          }
    }
    '2'{
        Write-Host "Obteniendo versiones disponibles en el servidor ftp"
        Write-Host "Las versiones disponibles son: "
        $ftp = "$ftpbase/Nginx"
        $request = [System.Net.FtpWebRequest]::Create($ftp)
        $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
        $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
        $request.EnableSsl = $true
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true}
        
        try{
            $response = $request.GetResponse()
            $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
            $directories = $reader.ReadToEnd()
            $reader.Close()
            $response.Close()
            $directories -split "`n"
        }catch{
            Write-Host "Error: $_"
        }

        Write-Host "Cual version quieres descargar"
        Write-Host "1. Version Oficial"
        Write-Host "2. Version Beta"
        Write-Host " Salir"
        $opc = Read-Host "Opcion:"
        switch($opc){
              '1'{
                $bersion = "nginx.zip" #La unica deiferencia con caddy es que aqui como al descomprimirlo te dar� una carpeta con el nombre dela version
                $version = "1.26.3"    #Asigno variables que contienen el nombre del archivo zip y de la version a la que corresponden
                DownloadNginxftp
              }
              '2'{
                $bersion = "nginx_beta.zip"
                $version = "1.27.4"
                DownloadNginxftp
           
              }
               '3'{
                $running = $false
            
              }
              default{
                write-host "Opcion Invalida, volviendo al menu principal"
                $running = $false
        
              }
          }
        }
        default{
            Write-Host "Volviendo al menu"
        }
    }
      cd C:\Users\Administrador
  }

  function descargararchivo{
      param (
        $archivo
      )

      Write-Host "Descargando archivos"
    $ftp = "$ftpbase/Otros/$archivo" #Sitio ftp, uso la ip para conectarme y los archivos estan detro de la carpeta publica
    $destino = "C:\ssl\$archivo"

    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com") #Me conecto con usuario anonimo
    $request.EnableSsl = $true

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true} #No me acuerdo que hace pero se ocupa
        
    try{
        #En este try se hace el proceso de descarga
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $reader = New-Object System.IO.FileStream $destino, "Create"
        
        $buffer = New-Object byte[] 1024
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0){
            $reader.Write($buffer,0, $read)
        }
        $reader.Close()
        $stream.Close()
        $response.Close()
        Write-Host "Arhivo descargado"    
        
    }catch{
        Write-Host "Error: $_"
    }


  }
  

  function otrasdescargas{
    Write-Host "Este directorio tiene estos archivos para descargar"
  
    $ftp = "$ftpbase/Otros"
    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true}
    try{
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
        $directories = $reader.ReadToEnd() -split "`r?`n"
        $reader.Close()
        $response.Close()
     }catch{
        Write-Host "Error: $_"
     }

     $running = $true
     while ($running){
         $i = 1
         Write-Host "Elige una opcion para descargar"
         for ($i = 0; $i -lt $directories.Length - 1 ; $i++){
            Write-Host "[$($i+1)] $($directories[$i])"
         }
         $opc = Read-Host "opcion: (1-$($directories.Length - 1), $($directories.Length) para salir)"
         
         if($opc -eq $($directories.Length)){
            write-host "Saliendo..."
            $running = $false
         }elseif($opc -match "^\d+$" -and [int]$opc -le $directories.Length){
            Write-Host $directories[[int]$opc - 1]
            descargararchivo -archivo $directories[[int]$opc - 1]

            $running = $false
         }else {
            write-host "Opcion invalida, intenta de nuevo"
         }
     }
     
  }

  
  function elegirserviciosweb(){
        $puertovalido = $false
        Write-Host "Instalar servicio HTTP"
        Write-Host "1. Caddy"
        Write-Host "2. Nginx"
        Write-Host "[3] Salir"
        $opc = Read-Host "Opcion"
        switch($opc){
            '1'{
                if(Test-Path "C:\caddy\caddy.exe"){
                    Write-Host "Caddy ya esta instalado en el equipo"
                }else{
                    while (-not $puertovalido){
                        $newPort = Read-Host "Introduce el puerto donde correra el servicio"
                        if(Comprobarpuerto -newPort $newPort){
                            $puertovalido = $true
                            Write-Host "Puerto Valido, se procedera a la instalacion"
                        }else{
                            $puertovalido = $false
                            Write-Host "Puerto invalido o esta en uso ingresa otro dato"
                        }
                    }
            
                    InstallCady InstallNginx -ftp $false
                }
            
            }
            '2'{
             
                if(Test-Path "C:\nginx\nginx-*\nginx.exe"){
                    Write-Host "Nginx ya esta instalado en el equipo"
                }else{
                    while (-not $puertovalido){
                        $newPort = Read-Host "Introduce el puerto donde correra el servicio"
                        if(Comprobarpuerto -newPort $newPort){
                            $puertovalido = $true
                            Write-Host "Puerto Valido, se procedera a la instalacion"
                        }else{
                            $puertovalido = $false
                            Write-Host "Puerto invalido o esta en uso ingresa otro dato"
                        }
                    }
                        InstallNginx -ftp $false
                }
            
            }
            '3'{
             
               $running = $false
            
            }
            default{
                Write-Host "Opcion Invalida"
            }
  
    }
  }

  function elegirserviciosftp(){
    Write-Host "Las opciones disponibles en ftp gson: "

    $ftp = "$ftpbase/"
    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true}
        
    try{
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
        $directories = $reader.ReadToEnd()
        $reader.Close()
        $response.Close()
        $directories -split "`n"
     }catch{
        Write-Host "Error: $_"
     }

     Write-Host "Que quieres descargar"
     Write-Host "1. Caddy"
     Write-Host "2. Nginx"
     Write-Host " Otros"
     $opc = Read-Host "opcion:"
     switch($opc){
        '1'{
            if(Test-Path "C:\caddy\caddy.exe"){
                    Write-Host "Caddy ya esta instalado en el equipo"
                }else{
                    while (-not $puertovalido){
                        $newPort = Read-Host "Introduce el puerto donde correra el servicio"
                        if(Comprobarpuerto -newPort $newPort){
                            $puertovalido = $true
                            Write-Host "Puerto Valido, se procedera a la instalacion"
                        }else{
                            $puertovalido = $false
                            Write-Host "Puerto invalido o esta en uso ingresa otro dato"
                        }
                    }
            
                    InstallCady -ftp $true
                }
            
        }
        '2'{
            if(Test-Path "C:\nginx\nginx-*\nginx.exe"){
                    Write-Host "Nginx ya esta instalado en el equipo"
                }else{
                    while (-not $puertovalido){
                        $newPort = Read-Host "Introduce el puerto donde correra el servicio"
                        if(Comprobarpuerto -newPort $newPort){
                            $puertovalido = $true
                            Write-Host "Puerto Valido, se procedera a la instalacion"
                        }else{
                            $puertovalido = $false
                            Write-Host "Puerto invalido o esta en uso ingresa otro dato"
                        }
                    }
                        InstallNginx -ftp $true
                }
            
        }
        '3'{
            otrasdescargas
        }
        default{
            Write-Host "Volviendo al menu"
        }
     }

  }


