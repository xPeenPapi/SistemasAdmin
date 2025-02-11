#!/bin/bash

# Solicitar el nombre del dominio
read -p "Ingrese el nombre del dominio: " dominio

# Patrón regex para validar la dirección IP
ipPattern='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

# Solicitar la dirección IP y validarla
while true; do
    read -p "Ingrese la dirección IP: " ip
    if [[ $ip =~ $ipPattern ]]; then
        break
    else
        echo "Dirección IP no válida. Intentalo de nuevo"
    fi
done

# Agregar la zona DNS al archivo named.conf.local
echo "zone \"$dominio\" IN {
    type master;
    file \"/etc/bind/db.$dominio\";
};" | sudo tee -a /etc/bind/named.conf.local

# Crear el archivo de zona db.$dominio a partir de una plantilla
sudo cp /etc/bind/db.local /etc/bind/db.$dominio

# Configurar el archivo de zona db.$dominio
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

echo "Configuracion completada para el dominio $dominio con la IP $ip."
