#!/bin/bash

configurarDNS(){
    local ip=$1
    local dominio=$2

    if ! validar_ip "$ip"; then
        return 1
    fi

    if ! validar_dominio "$dominio"; then
        return 1
    fi

    echo "Configurando la zona DNS para $dominio..."
    echo "zone \"$dominio\" IN {
        type master;
        file \"/etc/bind/db.$dominio\";
    };" | sudo tee -a /etc/bind/named.conf.local

    sudo cp /etc/bind/db.local /etc/bind/db.$dominio

    echo "Creando el archivo de zona para $dominio..."
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

    echo "Verificando la configuración de la zona..."
    if ! sudo named-checkzone $dominio /etc/bind/db.$dominio; then
        echo "Error: La configuración de la zona para $dominio no es válida."
        return 1
    fi

    echo "Reiniciando el servicio BIND..."
    sudo systemctl restart bind9

    echo "Estado del servicio BIND:"
    sudo systemctl status bind9

    echo "Configuración completada para el dominio $dominio con la IP $ip."


}
configurarDHCP(){
    local ip=$1
    local subnet_mask_cidr=$2
    local subnet=$3
    local rango_inicio=$4
    local rango_final=$5
    local mask=$6

    # Validar entradas
    if ! validar_ip "$ip"; then
        return 1
    fi

    if ! validar_mascara_cidr "$subnet_mask_cidr"; then
        return 1
    fi

    if ! validar_subred "$subnet"; then
        return 1
    fi

    if ! validar_ip "$rango_inicio"; then
        return 1
    fi

    if ! validar_ip "$rango_final"; then
        return 1
    fi

    if ! validar_mascara_decimal "$mask"; then
        return 1
    fi

    # Instalar el servidor DHCP
    echo "Instalando el servidor DHCP..."
    sudo apt-get update
    sudo apt-get install -y isc-dhcp-server

    # Configurar la interfaz en /etc/default/isc-dhcp-server
    echo "Configurando la interfaz..."
    sudo bash -c "cat > /etc/default/isc-dhcp-server" <<EOF
INTERFACESv4="enp0s3"
INTERFACESv6=""
EOF

    # Configurar la IP estática en Netplan
    echo "Configurando la IP estática..."
    sudo tee /etc/netplan/*.yaml > /dev/null <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses: [$ip/$subnet_mask_cidr]
EOL

    # Aplicar la configuración de Netplan
    sudo netplan apply

    # Configurar el archivo dhcpd.conf
    echo "Configurando el archivo dhcpd.conf..."
    sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOL
subnet $subnet netmask $mask {
  range $rango_inicio $rango_final;
  option routers $ip;
  option subnet-mask $mask;
}
EOL

    # Reiniciar el servicio DHCP
    echo "Reiniciando el servicio DHCP..."
    sudo service isc-dhcp-server restart

    # Verificar el estado del servicio DHCP
    echo "Estado del servicio DHCP:"
    sudo service isc-dhcp-server status

    echo "Configuración del servidor DHCP completada."

}