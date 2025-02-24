#!/bin/bash

source /home/peenpapi/SistemasAdmin/FuncionesBash/FuncionesUbuntu.sh
source /home/peenpapi/SistemasAdmin/FuncionesBash/FuncionesPrincipales.sh

read -p "Ingresa la dirección IP: " ip
read -p "Ingresa el dominio: " dominio

configurarDNS "$ip" "$dominio"