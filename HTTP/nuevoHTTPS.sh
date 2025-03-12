#!/bin/bash

function entero(){
    local valor=$1
    if[["$valor" =~ ^[0-9]+$]]; then
        return 0
    else    
        return 1
    fi
}
function puerto(){
    local puerto=$1
    if[["$puerto" -ge 1024 && "$puerto" -le 65535]]; then
        return 0
    else
        return 1
    fi
}
function hacerPeticion(){
    local =$url
    local html=$(curl -s "$curl")
    echo "${html}"
}

function descargarLighttpd(){
    echo "Ingresa el puerto en el que se instalara Lighttpd: "
    read puerto
    
    local Link = "https://www.lighttpd.net/releases/"
    local Pagina=${$hacerPeticion "$Link"}
    local regex = 'lighttpd-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz'
    local descarga=$(echo "$Pagina" | grep -oE "$regex" | head  -n 1)
    if[[ -n "$descarga"]]: then
        echo "Descargando Lighttpd: $descarga...."
        curl -s -O "https://www.lighttpd.net/download/$descarga"
        if[[ $? -eq 0]]; then
            echo "Lighttpd descargado correctamente"
        else
            echo "Error: Lighttpd no se pudo descargar"
            exit 1
        fi
    else
        echo "Error no se pudo encontrar la version de Lighttpd"
        exit 1
    fi
}
while true; do
    echo "Servicio a instalar"
    echo "1. Descargar Lighttpd"
    echo "2. Descargar Apache"
    echo "3. Descargar Nginx"
    echo "Selecciona una opcion:"
    read opcion

    case "$opcion" in
        "1")
            echo "1. Instalar ultima version LTS"
            echo "No existe la version desarrollador"
            echo "2. Salir"
            echo "Selecciona una opcion: "
            read opcLighttpd
            
            case "opcLighttpd" in
                "1")
                    $descargarLighttpd
                ;;
                "2")
                    echo "Saliendo al menu principal"
                ;;
                *)
                    echo "Opcion no valida. Intente de nuevo."
                ;;
            esac
        done
            




    