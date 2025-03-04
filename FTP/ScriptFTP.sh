#!/bin/bash
sudo apt-get update
sudo apt-get install vsftpd
sudo systemctl start vsftpd
sudo systemctl enable vsftpd
sudo systemctl status vsftpd

crear_usuario() {
    read -p "Ingrese el nombre de usuario: " username
    sudo useradd "$username"

    sudo mkdir /home/$username
    sudo chmod 700 /home/$username
    sudo chown $username:$username /home/$username

    sudo mkdir /home/$username/publica
    sudo chmod 755 /home/$username/publica
    sudo mount --bind /home/FTP/publica /home/$username/publica

    sudo mkdir /home/$username/$username
    sudo chmod 700 /home/$username/$username
    sudo chown $username:$username /home/$username/$username

    read -sp "Ingrese la contraseña para $username: " password
    echo
    echo "$username:$password" | sudo chpasswd

    echo "Usuario $username creado y contraseña asignada."
}

asignar_grupo() {
    echo groups
    read -p "Escriba el nombre de usuario a asignar a un grupo (reprobados o recursadores): " user
    read -p "Escriba el nombre del grupo a asignar: " grupo
    sudo adduser "$user" "$grupo"
    echo "Usuario $user asignado al grupo $grupo."
}

cambiar_grupo() {
    read -p "Escriba el usuario a quien desea cambiar de grupo: " user
    read -p "Escriba el nuevo grupo de ese usuario: " grupo

    grupo_actual=$(groups "$user" | awk '{print $5}')  # Asume que el grupo relevante es el tercero
    echo groups

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

# Menú principal
while true; do
    echo "Seleccione una opción:"
    echo "1. Crear un usuario"
    echo "2. Asignar un usuario a un grupo"
    echo "3. Cambiar un usuario de grupo"
    echo "4. Salir"
    read -p "Opción: " opcion

    case $opcion in
        1)
            crear_usuario
            ;;
        2)  
            asignar_grupo
            ;;
        3)
            cambiar_grupo
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
