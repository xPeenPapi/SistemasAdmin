#!/bin/bash

# Solicitar el nombre del dominio
read -p "Ingrese el nombre del dominio: " $dominio

# Solicitar la dirección IP y validarla con regex
while true; do
    read -p "Ingrese la dirección IP: " $ip
    if [[ $ip =~ "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$" ]]; then
         break
    else
        echo "Dirección IP no válida. Intente de nuevo."
    fi
done


# Agregar la zona DNS a named.conf.local
echo "zone \"$dominio\" IN {
    type master;
    file \"/etc/bind/db.$dominio\";
};" | sudo tee -a /etc/bind/named.conf.local

# Crear el archivo de zona db.reprobados.com a partir de la plantilla db.local
sudo cp /etc/bind/db.local /etc/bind/db.$dominio

# Configurar el archivo de zona db.reprobados.com
sudo bash -c "cat > /etc/bind/db.$dominio" <<EOF
;
; BIND data file for $dominio
;
\$TTL    604800
@       IN      SOA     $dominio. admin.$dominio. (
                        2023101001         ; Serial
                        604800             ; Refresh
                        86400              ; Retry
                        2419200            ; Expire
                        604800 )           ; Negative Cache TTL
;
@       IN      NS      $dominio.
@       IN      A       $ip
www     IN      A       $ip
EOF

# Reiniciar el servicio BIND para aplicar los cambios
sudo systemctl restart bind9

echo "Configuración completada para el dominio $dominio con la IP $ip."