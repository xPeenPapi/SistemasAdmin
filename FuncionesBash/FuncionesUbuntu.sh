#!/bin/bash

validar_ip() {
    local ipPattern='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    if [[ $1 =~ $ipPattern ]]; then
        return 0
    else
        echo "Error: La dirección IP '$1' no es válida."
        return 1
    fi
}

validar_dominio() {
    local dominioPattern='^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$'
    if [[ $1 =~ $dominioPattern ]]; then
        return 0
    else
        echo "Error: El nombre del dominio '$1' no es válido."
        return 1
    fi
}

validar_mascara_cidr() {
    if [[ $1 =~ ^[0-9]{1,2}$ ]] && [ $1 -ge 0 ] && [ $1 -le 32 ]; then
        return 0
    else
        echo "Error: La máscara de subred CIDR '$1' no es válida. Debe ser un número entre 0 y 32."
        return 1
    fi
}

validar_mascara_decimal() {
    local maskPattern='^(255|254|252|248|240|224|192|128|0)\.(255|254|252|248|240|224|192|128|0)\.(255|254|252|248|240|224|192|128|0)\.(255|254|252|248|240|224|192|128|0)$'
    if [[ $1 =~ $maskPattern ]]; then
        return 0
    else
        echo "Error: La máscara de subred '$1' no es válida."
        return 1
    fi
}

validar_subred() {
    local subnetPattern='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.0$'
    if [[ $1 =~ $subnetPattern ]]; then
        return 0
    else
        echo "Error: La subred '$1' no es válida. Debe terminar en 0."
        return 1
    fi
}