#!/bin/bash

# Función para validar si un valor es un número entero
function es_entero() {
    local valor=$1
    if [[ "$valor" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Función para validar si un puerto está en el rango válido
function es_puerto_valido() {
    local puerto=$1
    if [[ "$puerto" -ge 1024 && "$puerto" -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

# Función para verificar si un puerto está en uso
function puerto_en_uso() {
    local puerto=$1
    if netstat -tuln | grep ":$puerto " > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Función para bloquear puertos comunes
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

# Función para obtener el HTML de una URL
function hacer_peticion() {
    local url=$1
    curl -s "$url"
}

# Función para extraer la versión LTS o de desarrollo usando una expresión regular
function encontrar_version() {
    local html=$1
    local regex=$2
    echo "$html" | grep -oE "$regex" | head -n 1
}

# Función para descargar, compilar e instalar un servicio desde su código fuente
function instalar_servicio() {
    local nombre=$1
    local version=$2
    local url_descarga=$3
    local puerto=$4

    echo "Descargando $nombre versión $version..."
    curl -s -O "$url_descarga"
    if [[ $? -ne 0 ]]; then
        echo "Error: No se pudo descargar $nombre."
        exit 1
    fi

    local archivo=$(basename "$url_descarga")
    echo "Descomprimiendo $archivo..."
    tar -xvzf "$archivo"
    if [[ $? -ne 0 ]]; then
        echo "Error: No se pudo descomprimir $archivo."
        exit 1
    fi

    local carpeta="${archivo%.tar.gz}"
    cd "$carpeta" || exit 1

    echo "Compilando $nombre..."
    ./configure --prefix=/usr/local/"$nombre" > /dev/null 2>&1
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Error: No se pudo instalar $nombre."
        exit 1
    fi

    echo "Configurando $nombre en el puerto $puerto..."
    case $nombre in
        apache)
            sudo sed -i "s/Listen 80/Listen $puerto/" /usr/local/apache/conf/httpd.conf
            sudo /usr/local/apache/bin/apachectl start
            ;;
        nginx)
            sudo sed -i "s/listen 80/listen $puerto/" /usr/local/nginx/conf/nginx.conf
            sudo /usr/local/nginx/sbin/nginx
            ;;
        lighttpd)
            sudo sed -i "s/server.port = 80/server.port = $puerto/" /usr/local/lighttpd/etc/lighttpd.conf
            sudo /usr/local/lighttpd/sbin/lighttpd start
            ;;
    esac

    echo "$nombre instalado y configurado en el puerto $puerto."
}

# Función para obtener la última versión LTS y de desarrollo
function obtener_versiones() {
    local url_descargas=$1
    local regex_lts=$2
    local regex_dev=$3

    html=$(hacer_peticion "$url_descargas")
    version_lts=$(encontrar_version "$html" "$regex_lts")
    version_dev=$(encontrar_version "$html" "$regex_dev")

    echo "$version_lts $version_dev"
}

# Menú principal
while true; do
    echo "¿Qué servicio desea instalar?"
    echo "1. Apache"
    echo "2. Nginx"
    echo "3. Lighttpd"
    echo "4. Salir"
    read -p "Seleccione una opción: " opcion

    case $opcion in
        1|2|3)
            # Obtener las versiones disponibles dinámicamente
            case $opcion in
                1)
                    nombre="apache"
                    url_descargas="https://httpd.apache.org/download.cgi"
                    regex_lts='httpd-([0-9]+\.[0-9]+\.[0-9]+)\.tar\.gz'
                    regex_dev='httpd-([0-9]+\.[0-9]+\.[0-9]+)-dev\.tar\.gz'
                    ;;
                2)
                    nombre="nginx"
                    url_descargas="https://nginx.org/en/download.html"
                    regex_lts='nginx-([0-9]+\.[0-9]+\.[0-9]+)\.tar\.gz'
                    regex_dev='nginx-([0-9]+\.[0-9]+\.[0-9]+)-dev\.tar\.gz'
                    ;;
                3)
                    nombre="lighttpd"
                    url_descargas="https://www.lighttpd.net/download/"
                    regex_lts='lighttpd-([0-9]+\.[0-9]+\.[0-9]+)\.tar\.gz'
                    regex_dev='lighttpd-([0-9]+\.[0-9]+\.[0-9]+)-dev\.tar\.gz'
                    ;;
            esac

            # Obtener versiones LTS y de desarrollo
            read version_lts version_dev <<< $(obtener_versiones "$url_descargas" "$regex_lts" "$regex_dev")

            echo "Versiones disponibles para $nombre:"
            echo "1. Ultima versión LTS: $version_lts"
            if [[ -n "$version_dev" ]]; then
                echo "2. Ultima versión de desarrollo: $version_dev"
            else
                echo "2. No hay versión de desarrollo disponible."
            fi
            read -p "Seleccione la versión: " version_opcion

            if [[ $version_opcion -eq 1 ]]; then
                version="$version_lts"
            elif [[ $version_opcion -eq 2 && -n "$version_dev" ]]; then
                version="$version_dev"
            else
                echo "Opción no válida."
                continue
            fi

            while true; do
                read -p "Ingrese el puerto para la configuración: " puerto
                if es_entero "$puerto" && es_puerto_valido "$puerto" && ! puerto_en_uso "$puerto" && bloquear_puertos_comunes "$puerto"; then
                    break
                else
                    echo "Puerto no válido o en uso. Intente de nuevo."
                fi
            done

            # Descargar, compilar e instalar el servicio
            case $opcion in
                1)
                    instalar_servicio "apache" "$version" "https://downloads.apache.org/httpd/httpd-$version.tar.gz" "$puerto"
                    ;;
                2)
                    instalar_servicio "nginx" "$version" "https://nginx.org/download/nginx-$version.tar.gz" "$puerto"
                    ;;
                3)
                    instalar_servicio "lighttpd" "$version" "https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-$version.tar.gz" "$puerto"
                    ;;
            esac
            ;;
        4)
            echo "Saliendo..."
            break
            ;;
        *)
            echo "Opción no válida. Intente de nuevo."
            ;;
    esac
done