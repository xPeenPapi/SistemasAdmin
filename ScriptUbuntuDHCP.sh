#!/bin/bash

sudo apt-get update

sudo apt-get install -y isc-dhcp-server

sudo bash -c "cat > /etc/defualt/isc-dhcp-server"<<EOF
INTERFACESv4="enp0s3"
INTERFACESv6=""
EOF

read -p "Ingresa la dirección IP del servidor: " ip 
read -p "Ingresa la mascara de subred en formato CIDR (24 por ejemplo): " subnet_mask

sudo tee /etc/netplan/*yaml > /dev/null <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    ensp0s3:
      dhcp4: false
      addresses: [$ip/$subnet_mask]
EOL

sudo netplan apply

read -p "Ingresa la subred (El subnet termina en 0 porque representa la dirección de red): " subnet
read -p "Ingresa el rango inicial de direcciones IP: " rango_inicio
read -p "Ingresa el rango final de direcciones IP: " rango_final

sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOL
subnet $subnet netmask 255.255.255.0 {
  range $rango_inicial $rango_final;
  option routers $ip;
  option subnet-mask 255.255.255.0;
}
EOL

sudo systemctl restart isc-dhcp-server

sudo systemctl status isc-dhcp-server

echo "Configuración del servidor DHCP completada."


# Configurar el cliente para usar DHCP
# Nota: Esto debe ejecutarse en el cliente, no en el servidor
# sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOL
# network:
#   version: 2
#   renderer: networkd
#   ethernets:
#     ens33:
#       dhcp4: true
# EOL

# sudo netplan apply

# ip addr show ens33