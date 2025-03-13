#!/bin/bash

function entero() {
    local valor=$1
    if [[ "$valor" =~ ^[0-9]+$ ]]; then
        return 0
    else    
        return 1
    fi
}

function puerto() {
    local puerto=$1
    if [[ "$puerto" -ge 1024 && "$puerto" -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

function bloquear_puertos_comunes() {
    local puerto=$1
    case $puerto in
        21|22|23|25|53|80|110|143|443|3306|3389)
            echo "El puerto $puerto está reservado para servicios comunes (FTP, SSH, HTTP, etc.)."
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

function hacerPeticion() {
    local url=$1
    local html=$(curl -s "$url")
    echo "${html}"
}

function descargarLighttpd() {
    local nombreArchivo="lighttpd.tar.gz"
    local Link="https://www.lighttpd.net/download/"
    local Pagina=$(hacerPeticion "$Link")
    local versionRegex='lighttpd-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz'
    local descarga=$(echo "$Pagina" | grep -oE "$versionRegex" | head -n 1)
    
    if [[ -n "$descarga" ]]; then
        echo "Descargando Lighttpd: $descarga...."
        curl -s -O "https://www.lighttpd.net/download/$descarga"
        if [[ $? -eq 0 ]]; then
            echo "Lighttpd descargado correctamente"
        else
            echo "Error: Lighttpd no se pudo descargar"
            exit 1
        fi
    else
        echo "Error: No se pudo encontrar la versión de Lighttpd"
        exit 1
    fi

    sudo tar -xvzf "$descarga" > /dev/null 2>&1
    local carpeta="${descarga%.tar.gz}"
    cd "$carpeta" || exit 1
    ./configure --prefix=/usr/local/lighttpd > /dev/null 2>&1
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1
}

function instalarLighttpd() {
    echo "Ingrese el puerto"
    read puerto

    while true; do          
        if entero "$puerto" && puerto "$puerto" && bloquear_puertos_comunes "$puerto"; then
            break
        else
            echo "Puerto no válido o en uso. Intente de nuevo."
        fi
    done

    descargarLighttpd

    # Verificar la instalación
    /usr/local/lighttpd/sbin/lighttpd -v
    rutaArchivoConfiguracion="/usr/local/lighttpd/etc/lighttpd.conf"
    # Remuevo el puerto en uso
    sudo sed -i '/^server.port/d' "$rutaArchivoConfiguracion"
    # Añado el puerto proporcionado por el usuario
    sudo printf "server.port = $puerto\n" >> "$rutaArchivoConfiguracion"
    echo "Escuchando en el puerto $puerto"
    # Compruebo que realmente esté escuchando en ese puerto
    sudo grep -i "server.port = $puerto" "$rutaArchivoConfiguracion"
    sudo /usr/local/lighttpd/sbin/lighttpd restart
    ps aux | grep lighttpd
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
            
            case "$opcLighttpd" in
                "1")
                    instalarLighttpd
                    ;;
                "2")
                    echo "Saliendo al menu principal"
                    ;;
                *)
                    echo "Opcion no valida. Intente de nuevo."
                    ;;
            esac
            ;;
        *)
            echo "Opcion no valida. Intente de nuevo."
            ;;
    esac
done