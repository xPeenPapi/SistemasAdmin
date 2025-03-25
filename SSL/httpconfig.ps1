#Converti este script en una funcion para llamarlo desde el script del ssl
function httpconfig{
    . .\httpfunctions.ps1

    Write-Host "Validando instalacion de los servicios de IIS"
    $running = $true
    if((Get-WindowsFeature -Name Web-Server).Installed){
      Write-Host "IIS instalado e iniciado"
      $opc = "s"
    }else{
      while ($running){
        Write-Host "Primero debes instalar el servicio HTTP de IIS,¿Quieres instalarlo S/N?"
        $opc = Read-Host "Opcion"
        if($opc.ToLower() == "s" or $opc.ToLower() == "si"){
            Install-WindowsFeature -Name Web-Server -IncludeManagementTools
            $opc = "s"
        }elseif($opc.ToLower() == "no" or $opc.ToLower() == "n"){
            $opc = "n"
        }else{
            Write-Host "Opcion invalida"
            $running = $false
        }
      }
  
    }

    $running = $true

    while ($running){
        Write-Host "Quieres configurar un puerto especifico para IIS? [S/N]"
        $opc = Read-Host "Opcion"
        if($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si"){
            $newPort = Read-Host "Introduce el puerto donde correrá el servicio"
            if(Comprobarpuerto -newPort $newPort){
                $puertovalido = $true
                Write-Host "Puerto Valido, se procederá a la configuracion"
                Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName port -Value $newPort > $null
                $running = $false
                $opc = "s"
                
             }else{
                $puertovalido = $false
                Write-Host "Puerto invalido o está en uso ingresa otro dato"
                $opc = "s"
             }
       
        }elseif($opc.ToLower() -eq "no" -or $opc.ToLower() -eq "n"){
             $puertovalido = $false
              $running = $false
              $opc = "s"
              Write-Host "IIS se quedó por defecto en el puerto 80"
              $newPort = 80
        }else{
            Write-Host "Opcion invalida intentalo de nuevo"
        
            $opc = "s"
        }
      }

    $running = $true
    while($running){
        Write-Host "Quieres configurar SSL para IIS [S-N]"
        $opc = Read-Host "Opcion"
        if($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si"){
            ConfigsslIIS
            $running = $false
        }elseif($opc.ToLower() -eq "no" -or $opc.ToLower() -eq "n"){
            $running = $false
        }else{
            Write-Host "Opcion Invalida"
        }
    }
    


    $running = $true
    $opc = "s"
    if($opc -eq "s"){
        elegirserviciosweb
    }

}





