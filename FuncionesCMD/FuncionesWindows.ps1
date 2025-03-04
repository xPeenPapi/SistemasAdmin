function validar_ip {
    Param([Parameter(Mandatory)][string]$ip)
    if ($ip -match '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
        return $true
    } else {
        Write-Host "Error: La dirección IP '$ip' no es válida."
        return $false
    }
}

function validar_dominio {
    Param([Parameter(Mandatory)][string]$dominio)
    if ($dominio -match '^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$') {
        return $true
    } else {
        Write-Host "Error: El nombre del dominio '$dominio' no es valido."
        return $false
    }
}

function validar_mascaraCidr {
    Param([Parameter(Mandatory)][int]$mascara_cidr)
    if ($mascara_cidr -ge 0 -and $mascara_cidr -le 32) {
        return $true
    } else {
        Write-Host "Error: La máscara de subred CIDR '$mascara_cidr' no es válida. Debe ser un número entre 0 y 32."
        return $false
    }
}

function validar_mascaraDecimal {
    Param([Parameter(Mandatory)][string]$mascara_decimal)
    if ($mascara_decimal -match '^(255|254|252|248|240|224|192|128|0)\.(255|254|252|248|240|224|192|128|0)\.(255|254|252|248|240|224|192|128|0)\.(255|254|252|248|240|224|192|128|0)$') {
        return $true
    } else {
        Write-Host "Error: La máscara de subred '$mascara_decimal' no es válida."
        return $false
    }
}

function validar_subred {
    Param([Parameter(Mandatory)][string]$subnetMask)
    if ($subnetMask-match '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.0$') {
        return $true
    } else {
        Write-Host "Error: La subred '$subnetMask' no es válida. Debe terminar en 0."
        return $false
    }
}