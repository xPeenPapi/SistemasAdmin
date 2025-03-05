#!/bin/bash
sudo apt-get update
sudo apt-get install vsftpd
sudo systemctl start vsftpd
sudo systemctl enable vsftpd

validar_usuario() {
    local username="$1"
    if [[ -z "$username" ]]; then
        echo "El nombre de usuario no puede estar vacío."
        return 1
    fi
    if [[ ! "$username" =~ ^[a-zA-Z0-9]{1,20}$ ]]; then
        echo "El nombre de usuario debe tener un máximo de 20 caracteres y solo contener letras y números."
        return 1
    fi
    if id "$username" &>/dev/null; then
        echo "El usuario ya existe."
        return 1
    fi
    return 0
}

validar_contraseña() {
    local password="$1"
    if [[ -z "$password" ]]; then
        echo "La contraseña no puede estar vacía."
        return 1
    fi
    if [[ "${#password}" -lt 8 ]]; then
        echo "La contraseña debe tener al menos 8 caracteres."
        return 1
    fi
    return 0
}

verificar_instalacion() {
    sudo systemctl status vsftpd
    echo "FTP INSTALADO CORRECTAMENTE"
}

crear_grupos() {
    sudo mkdir /home/FTP/recursadores
    sudo mkdir /home/FTP/reprobados

    sudo chmod 770 /home/FTP/recursadores
    sudo chmod 770 /home/FTP/reprobados

    if [[ -d "/home/FTP/recursadores" && -d "/home/FTP/reprobados" ]]; then
        echo "Los grupos reprobados y recursadores se crearon correctamente."
    else
        echo "Hubo un problema al crear los grupos. Verifica los permisos y la ruta."
        exit 1
    fi
}

crear_usuario() {
    while true; do
        read -p "Ingrese el nombre de usuario: " username
        validar_usuario "$username" && break
    done

    sudo useradd "$username"
    sudo mkdir /home/$username
    sudo chmod 700 /home/$username
    sudo chown $username:$username /home/$username

    sudo mkdir /home/$username/publica
    sudo chmod 775 /home/$username/publica
    sudo mount --bind /home/FTP/publica /home/$username/publica

    sudo mkdir /home/$username/$username
    sudo chmod 700 /home/$username/$username
    sudo chown $username:$username /home/$username/$username

    while true; do
        read -sp "Ingrese la contraseña para $username: " password
        echo
        validar_contraseña "$password" && break
    done

    echo "$username:$password" | sudo chpasswd
    echo "Usuario $username creado y contraseña asignada."
}

asignar_grupo() {
    read -p "Escriba el nombre de usuario a asignar a un grupo (reprobados o recursadores): " user
    if ! id "$user" &>/dev/null; then
        echo "El usuario $user no existe."
        return 1
    fi

    read -p "Escriba el nombre del grupo a asignar: " grupo
    if [[ ! "$grupo" =~ ^(reprobados|recursadores)$ ]]; then
        echo "El grupo $grupo no existe. Debe ser 'reprobados' o 'recursadores'."
        return 1
    fi

    sudo adduser "$user" "$grupo"
    sudo mkdir /home/$user/$grupo
    sudo chmod 770 /home/$user/$grupo
    sudo mount --bind /home/FTP/$grupo /home/$user/$grupo

    echo "Usuario $user asignado al grupo $grupo."
}

cambiar_grupo() {
    read -p "Escriba el usuario a quien desea cambiar de grupo: " user
    if ! id "$user" &>/dev/null; then
        echo "El usuario $user no existe."
        return 1
    fi

    read -p "Escriba el nuevo grupo de ese usuario: " grupo
    if [[ ! "$grupo" =~ ^(reprobados|recursadores)$ ]]; then
        echo "El grupo $grupo no existe. Debe ser 'reprobados' o 'recursadores'."
        return 1
    fi

    grupo_actual=$(ls /home/$user | grep -E 'reprobados|recursadores')
    if [[ "$grupo_actual" == "$grupo" ]]; then
        echo "El usuario $user ya está en el grupo $grupo. No se realizaron cambios."
        return
    fi

    sudo umount "/home/$user/$grupo_actual" || {
        echo "Hubo un problema al desmontar la carpeta del grupo actual."
        exit 1
    }

    sudo deluser "$user" "$grupo_actual"
    sudo adduser "$user" "$grupo"

    sudo mv "/home/$user/$grupo_actual" "/home/$user/$grupo"
    sudo mount --bind "/home/FTP/$grupo" "/home/$user/$grupo"

    echo "Usuario $user cambiado al grupo $grupo."
}

while true; do
    echo "Seleccione una opción:"
    echo "1. Verificar instalación del FTP"
    echo "2. Crear los grupos reprobados y recursadores"
    echo "3. Crear un usuario"
    echo "4. Asignar un usuario a un grupo"
    echo "5. Cambiar un usuario de grupo"
    echo "6. Salir"
    read -p "Opción: " opcion

    case $opcion in
        1)
            verificar_instalacion
            ;;
        2)
            crear_grupos
            ;;
        3)
            crear_usuario
            ;;
        4)
            asignar_grupo
            ;;
        5)
            cambiar_grupo
            ;;
        6)
            echo "Saliendo..."
            break
            ;;
        *)
            echo "Opción no válida. Intente de nuevo."
            ;;
    esac
done
