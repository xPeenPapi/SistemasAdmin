
#Converti este script en una funcion para llamarlo desde el script del ssl
function Configftp{


    #Write-Host "No se ha detectado el servidor ftp, procederemos a instalarlo y configurarlo"

    . .\ftpfunctions.ps1

    InstallFtp


    $running = $true
    while($running){
        clear
        Write-Host "Elige una opcion [1-2]"
        Write-Host "1. Administrar Usuario"2
        Write-Host "2. Crear usuario usuario"
        Write-Host "Salir"
        $opc = Read-Host("Opcion")
        switch($opc){
        '1'{
                Login;
           }
        '2'{
                Register;    
           }

        default{$running = $false}

        }
        Restart-Service ftpsvc
        Restart-Service W3SVC
    }



    Restart-WebItem "IIS:\Sites\PruebaFTP" -Verbose
}


