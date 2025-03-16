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

function obtenerVersionLTS(){
    local url=$1
    local index=${2:-0}
    readarray -t versions < <(curl -s "$url" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | sort -V -r | uniq)
    echo "${versions[$index]}"
}

function instalarServer(){
    local url=$1
    local versionInstall=$2
    local archivoDescomprimido=$3
    local servicio=$4

    # Instalar la version
    if ! curl -s -O "$url$versionInstall"; then
        echo "Error al descargar el archivo $versionInstall"
        return 1
    fi
    # Descomprimir el archivo descargado
    sudo tar -xzf $versionInstall > /dev/null 2>&1
    # Entrar a la carpeta
    cd "$archivoDescomprimido"
    # Compilar el archivo
    ./configure --prefix=/usr/local/"$servicio" > /dev/null 2>&1
    # Instalar servicio
    make -s > /dev/null 2>&1
    sudo make install > /dev/null 2>&1
}

function remove_tar_gz_suffix() {
    local filename=$1
    echo "${filename%.tar.gz}"
}

function primerDigito(){
    local index=$1
    local cadena=$2

    IFS='.' read -ra version <<< "$cadena"
    echo "${version[$index]}"
}

while true; do
    echo "=============================================="
    echo "==================== MENU ===================="
    echo "=============================================="
    echo "Servicios"
    echo "1. Descargar Tomcat"
    echo "2. Descargar Apache"
    echo "3. Descargar Nginx"
    echo "4. Salir"
    echo "Selecciona una opcion:"
    read opcion

    case "$opcion" in
        "1")
            descargarTomcat="https://tomcat.apache.org/index.html"
            versionDesarrollador=$(obtenerVersionLTS "$descargarTomcat" 0)
            ultimaVersionLTS=$(obtenerVersionLTS "$descargarTomcat" 1)

            echo "1. Instalar ultima version LTS: $ultimaVersionLTS"
            echo "2. Instalar version de desarrollo: $versionDesarrollador"
            echo "3. Salir"
            echo "Selecciona una opcion: "
            read -p "> " opcTomcat

            case "$opcTomcat" in
                "1")
                    firstDigit=$(primerDigito 0 "$ultimaVersionLTS")
                    read -p "Ingresa el puerto que se le asignara a Tomcat: " puerto
                    bloquear_puertos_comunes "$puerto"

                    if ss -tuln | grep -q ":$puerto"; then
                        echo "El puerto $puerto esta en uso por otro servicio. Intentelo de nuevo"
                    else
                        sudo rm -rf /opt/tomcat
                        sudo apt update
                        sudo apt install default-jdk -y
                        java -version
                        curl -s -O "https://dlcdn.apache.org/tomcat/tomcat-$firstDigit/v$ultimaVersionLTS/bin/apache-tomcat-$ultimaVersionLTS.tar.gz"
                        tar -xzvf apache-tomcat-$ultimaVersionLTS.tar.gz
                        sudo mv apache-tomcat-$ultimaVersionLTS /opt/tomcat
                        sudo chown -R $USER:$USER /opt/tomcat
                        sudo chmod -R 755 /opt/tomcat
                        # Modificar el puerto en server.xml
                        server_xml="/opt/tomcat/conf/server.xml"
                        sudo sed -i "s/port=\"8080\"/port=\"$puerto\"/g" "$server_xml"
                        # Otorgar permisos de ejecución
                        sudo chmod +x /opt/tomcat/bin/*.sh
                        # Iniciar Tomcat
                        sudo /opt/tomcat/bin/shutdown.sh
                        sudo /opt/tomcat/bin/startup.sh
                    fi
                    ;;
                "2")
                    firstDigit=$(primerDigito 0 "$versionDesarrollador")
                    read -p "Ingrese el puerto en el que se instalará Tomcat: " puerto
                    bloquear_puertos_comunes "$puerto"

                    if ss -tuln | grep -q ":$puerto"; then
                        echo "El puerto $puerto esta en uso. Eliga otro."
                    else
                        sudo rm -rf /opt/tomcat
                        # Instalar Java ya que Tomcat lo requiere
                        sudo apt update
                        sudo apt install default-jdk -y
                        java -version
                        curl -s -O "https://dlcdn.apache.org/tomcat/tomcat-$firstDigit/v$versionDesarrollador/bin/apache-tomcat-$versionDesarrollador.tar.gz"
                        tar -xzvf apache-tomcat-$versionDesarrollador.tar.gz
                        sudo mv apache-tomcat-$versionDesarrollador /opt/tomcat
                        # Modificar el puerto en server.xml
                        server_xml="/opt/tomcat/conf/server.xml"
                        sudo sed -i "s/port=\"8080\"/port=\"$puerto\"/g" "$server_xml"
                        # Otorgar permisos de ejecución
                        sudo chmod +x /opt/tomcat/bin/*.sh
                        # Iniciar Tomcat
                        sudo /opt/tomcat/bin/shutdown.sh
                        sudo /opt/tomcat/bin/startup.sh
                    fi
                    ;;
                "3")
                    echo "Saliendo al menu principal"
                    ;;
                *)
                    echo "Opcion invalida"
                    ;;
            esac
            ;;
        "2")
            descargarApache="https://downloads.apache.org/httpd/"
            paginaApache=$(hacerPeticion "$descargarApache")
            mapfile -t versions < <(obtenerVersionLTS "$descargarApache" 0)
            ultimaVersionLTS="${versions[0]}"

            echo "1. Instalar ultima version LTS: $ultimaVersionLTS"
            echo "2. Apache no cuenta con version de desarrollo"
            echo "3. Salir"
            echo "Selecciona una opcion: "
            read -p "> " opcApache

            case "$opcApache" in
                "1")
                    read -p "Ingrese el puerto en el que se instalará Apache: " puerto
                    bloquear_puertos_comunes "$puerto"

                    # Verificar si el puerto esta disponible
                    if ss -tuln | grep -q ":$puerto"; then
                        echo "El puerto $puerto esta en uso. Eliga otro."
                    else
                        instalarServer "$descargarApache" "httpd-$ultimaVersionLTS.tar.gz" "httpd-$ultimaVersionLTS" "apache2"
                        # Verificar la instalacón
                        /usr/local/apache2/bin/httpd -v
                        # Ruta de la configuración del archivo
                        rutaArchivoConfiguracion="/usr/local/apache2/conf/httpd.conf"
                        # Remover el puerto en uso actual
                        sudo sed -i '/^Listen/d' $rutaArchivoConfiguracion
                        # Añadir puerto que eligio el usuario
                        sudo printf "Listen $puerto" >> $rutaArchivoConfiguracion
                        # Comprobar si el puerto esta escuchando
                        sudo grep -i "Listen $puerto" $rutaArchivoConfiguracion
                        sudo /usr/local/apache2/bin/httpd -k start
                    fi
                    ;;
                "2")
                    echo "Saliendo al menu principal"
                    ;;
                "3")
                    echo "saliendo al menu principal"
                    ;;
                *)
                    echo "Opcion invalida"
                    ;;
            esac
            ;;
        "3")
            descargarNginx="https://nginx.org/en/download.html"
            versionDesarrollador=$(obtenerVersionLTS "$descargarNginx" 0)
            ultimaVersionLTS=$(obtenerVersionLTS "$descargarNginx" 1)     
            
            echo "1. Instalar ultima version LTS: $ultimaVersionLTS"
            echo "2. Instalar version de desarrollador: $versionDesarrollador"
            echo "3. Salir"
            echo "Selecciona una opcion: "
            read -p "> " opcNginx

            case "$opcNginx" in     
                "1")
                    read -p "Ingrese el puerto en el que se instalará Nginx: " puerto
                    bloquear_puertos_comunes "$puerto"

                    # Limpiar instalaciones previas
                    sudo systemctl stop nginx 2>/dev/null
                    sudo pkill nginx 2>/dev/null
                    sudo rm -rf /usr/local/nginx

                    if ss -tuln | grep -q ":$puerto"; then
                        echo "El puerto $puerto está en uso. Elija otro."
                    else
                    # Instalar dependencias
                    sudo apt update && sudo apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev

                    # Instalar Nginx
                    instalarServer "$descargarNginx" "nginx-$ultimaVersionLTS.tar.gz" "nginx-$ultimaVersionLTS" "nginx"

                    if [ $? -ne 0 ]; then
                        echo "Error: La instalación falló."
                        exit 1
                    fi

                    # Modificar puerto en nginx.conf
                    rutaArchivoConfiguracion="/usr/local/nginx/conf/nginx.conf"
                    sudo sed -i -E "s/listen[[:space:]]+[0-9]{1,5}([^0-9]|$)/listen $puerto;/g" "$rutaArchivoConfiguracion"

                    # Iniciar Nginx
                    sudo /usr/local/nginx/sbin/nginx
                    if [ $? -eq 0 ]; then
                        echo "¡Nginx reinstalado correctamente en el puerto $puerto!"
                    else
                        echo "Error: No se pudo iniciar Nginx. Verifica los logs."
                    fi
                fi                  
                ;;
                "2")
                    read -p "Ingrese el puerto en el que se instalará Nginx: " puerto
                    bloquear_puertos_comunes "$puerto"

                    if ss -tuln | grep -q ":$puerto"; then
                        echo "El puerto $puerto esta en uso. Eliga otro."
                    else
                        instalarServer "https://nginx.org/download/" "nginx-$versionDesarrollador.tar.gz" "nginx-$versionDesarrollador" "nginx"
                        # Verificar la instalación de Nginx
                        /usr/local/nginx/sbin/nginx -v
                        # Ruta de la configuración del archivo
                        rutaArchivoConfiguracion="/usr/local/nginx/conf/nginx.conf"
                        # Modificar el puerto
                        sudo sed -i -E "s/listen[[:space:]]{7}[0-9]{1,5}/listen      $puerto/" "$rutaArchivoConfiguracion"
                        # Verificar si esta escuchando en el puerto
                        sudo grep -i "listen[[:space:]]{7}" "$rutaArchivoConfiguracion"
                        sudo /usr/local/nginx/sbin/nginx
                        sudo /usr/local/nginx/sbin/nginx -s reload
                        ps aux | grep nginx
                    fi
                    ;;
                "3")
                    echo "Saliendo al menú principal..."
                    ;;
                *)
                    echo "Opción no válida"
                    ;;
            esac
            ;;
        "4")
            echo "Saliendo del programa"
            exit 0
            ;;
        *)
            echo "Opción inválida, por favor seleccione una opción correcta"
            ;;
    esac
done