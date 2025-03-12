
#!/bin/bash
sudo apt-get upgrade
sudo apt install vsftpd

sudo groupadd reprobados --force
sudo groupadd recursadores --force


if ! mountpoint -q "/home/peenpapi/ftp/usuarios/$usuario/$grupoActual"; then
    sudo mount --bind /home/peenpapi/ftp/general /home/peenpapi/ftp/anon/general  
fi

sudo chown :reprobados /home/peenpapi/ftp/reprobados
sudo chown :recursadores /home/peenpapi/ftp/recursadores
sudo chmod 775 /home/peenpapi/ftp/reprobados
sudo chmod 775 /home/peenpapi/ftp/recursadores

while :
do
    echo "Menu"
    echo "1. Agregar usuario"
    echo "2. Cambiar usuario de grupo"
    echo "3. Salir"
    echo "Selecciona una opcion: "
    read opcion

    case "$opcion" in
        "1")
            echo "Ingresa el nombre del usuario: "
            read usuario
            echo "Ingresa el nombre del grupo (reprobados/recursadores): "
            read grupo

            declare -l grupo
            grupo=$grupo
            echo "$grupo"

            declare -l usuario
            usuario=$usuario
            echo "$usuario"

            if [[ ${#grupo} -gt 20]]; then
                echo "El grupo es demasiado largo"
            elif [[ ${#usuario} -gt 20]]; then
                echo "El usuario es demasiado largo"
            elif [[ ${#usuario} -lt 4]]; then
                echo "El usuario es demasiado corto"
            elif [[ ${#grupo} -lt 4]]; then
                echo "El grupo es demasiado corto"
            else
                if [[ ("$grupo" != "reprobados" && "$grupo" != "recursadores") || -z "$grupo" || -z "$usuario" ]]; then
                    echo "Has ingresado un grupo inválido o espacios en blanco"
                elif id "$usuario" &>/dev/null; then
                    echo "El usuario ya existe"
                else
                    sudo useradd -m -d "/home/peenpapi/ftp/usuarios/$usuario" "$usuario"
                    sudo passwd "$usuario"
                    sudo usermod -G "$grupo" "$usuario"

                    sudo mkdir -p "/home/peenpapi/ftp/users/$usuario"
                    sudo mkdir -p "/home/peenpapi/ftp/usuarios/$usuario/$usuario"
                    sudo mkdir -p "/home/peenpapi/ftp/usuarios/$usuario/general"
                    sudo mkdir -p "/home/peenpapi/ftp/usuarios/$usuario/$grupo"

                    # Enlaces
                    sudo mount --bind "/home/peenpapi/ftp/general" "/home/peenpapi/ftp/usuarios/$usuario/general"
                    sudo mount --bind "/home/peenpapi/ftp/$grupo" "/home/peenpapi/ftp/usuarios/$usuario/$grupo"
                    sudo mount --bind "/home/peenpapi/ftp/users/$usuario" "/home/peenpapi/ftp/usuarios/$usuario/$usuario"

                    sudo chmod 700 /home/peenpapi/ftp/usuarios/$usuario/$usuario
                    sudo chmod 775 /home/peenpapi/ftp/usuarios/$usuario/$grupo
                    sudo chmod 777 /home/peenpapi/ftp/usuarios/$usuario/general

                    sudo chown -R "$usuario":"$usuario" "/home/peenpapi/ftp/usuarios/$usuario/$usuario"
                    sudo chown -R "$usuario":"$usuario" "/home/peenpapi/ftp/usuarios/$usuario/general"
                    sudo chown -R "$usuario":"$grupo" "/home/peenpapi/ftp/usuarios/$usuario/$grupo"

                    echo "Registro realizado correctamente"
                fi
            fi

        ;;
        "2")
            grupoActual=""
            echo "Nombre de usuario: "
            read usuario
            echo "Nuevo grupo de usuario: "
            read grupo

            declare -l grupo
            grupo=$grupo
            declare -l usuario
            usuario=$usuario

            if [[ "$grupo" == "reprobados" ]]; then
                grupoActual="recursadores"
            else
                grupoActual="reprobados"
            fi

            fuser /home/peenpapi/ftp/usuarios/$usuario/$grupoActual > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "El directorio está en uso"
            else
                if [[ ${#usuario} -gt 20]]; then
                    echo "El usuario es demasiado largo"
                elif [[ ${#usuario} -lt 4]]; then
                    echo "El usuario es demasiado corto"
                elif [[ ${#grupo} -gt 20]]; then
                    echo "El grupo es demasiado largo"
                elif [[ ${#grupo} -lt 4]]; then
                    echo "El grupo es demasiado corto"
                else
                    if id "$usuario" &>/dev/null; then
                        if mountpoint -q "/home/peenpapi/ftp/usuarios/$usuario/$grupoActual"; then
                            sudo umount -f "/home/peenpapi/ftp/usuarios/$usuario/$grupoActual"
                        fi

                        echo "Grupos actuales de $usuario:"
                        groups "$usuario"

                        sudo usermod -G "$grupo" "$usuario"

                        echo "Grupos actuales de $usuario después del cambio:"
                        groups "$usuario"

                        if [[ -d "/home/peenpapi/ftp/usuarios/$usuario/$grupoActual" ]]; then
                            sudo rm -r "/home/peenpapi/ftp/usuarios/$usuario/$grupoActual"
                        fi

                        sudo mkdir -p "/home/peenpapi/ftp/usuarios/$usuario/$grupo"

                        sudo mount --bind "/home/peenpapi/ftp/$grupo" "/home/peenpapi/ftp/usuarios/$usuario/$grupo"

                        sudo chown "$usuario":"$grupo" "/home/peenpapi/ftp/usuarios/$usuario/$grupo"
                        sudo chmod 775 "/home/peenpapi/ftp/usuarios/$usuario/$grupo"

                        echo "Se realizó el cambio de grupo correctamente"
                    elif [[ ("$grupo" != "reprobados" && "$grupo" != "recursadores") || -z "$grupo" || -z "$usuario" ]]; then
                        echo "Has ingresado un grupo invalido o campos vacíos"
                    else
                        echo "El usuario no existe"
                    fi
                fi
            fi
        ;;
        "3")
            echo "Saliendo..."
            break
        ;;
        *)
            echo "Selecciona una opcion dentro del rango (1..3)"
        ;;
    esac
    echo ""
done