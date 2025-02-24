#!/bin/bash

source /home/peenpapi/SistemasAdmin/FuncionesBash/FuncionesUbuntu.sh
source /home/peenpapi/SistemasAdmin/FuncionesBash/FuncionesPrincipales.sh

read -p "Ingresa la dirección IP del servidor: " ip
read -p "Ingresa la máscara de subred en formato CIDR (24 por ejemplo): " subnet_mask_cidr
read -p "Ingresa la subred (El subnet termina en 0 porque representa la dirección de red): " subnet
read -p "Ingresa el rango inicial de direcciones IP: " rango_inicio
read -p "Ingresa el rango final de direcciones IP: " rango_final
read -p "Ingresa la máscara de subred en formato decimal (255.255.255.0 por ejemplo): " mask

configurarDHCP "$ip" "$subnet_mask_cidr" "$subnet" "$rango_inicio" "$rango_final" "$mask"