#ilustracion 73
Get-Verb
#ilustracion 74
function Get-Fecha
{
    Get-Date
}
Get-Fecha
#ilustracion 75
Get-ChildItem -Path Function:\Get-*
#ilustracion 76
Get-ChildItem -Path Function:\Get-Fecha | Remove-Item
Get-ChildItem -Path Function:\Get-*
#ilustracion 77
function Get-Resta {
    Param ([int]$num1, [int]$num2)
    $resta=$num1-$num2
    Write-Host "La resta de los parametros es $resta"
}
#ilustracion 78
Get-Resta 10 5
#ilustracion 79
Get-Resta -num2 10 -num1 5
#ilustracion 80
Get-Resta -num2 10
#ilustracion 81
function Get-Resta 
{
    Param ([Parameter(Mandatory)][int]$num1, [int]$num2)
    $resta=$num1-$num2
    Write-Host "La resta de los paramtros es $resta"
}
Get-Resta -num2 10
#ilustracion 82
function Get-Resta {
    [CmdletBinding()]
    Param ([int]$num1, [int]$num2)
    $resta=$num1-$num2
    Write-Host "La resta de los parametros es $resta"
}
#ilustracion 83
(Get-Command -Name Get-Resta).Parameters.Keys
#ilustracion 84
function Get-Resta {
    [CmdletBinding()]
    Param ([int]$num1, [int]$num2)
    $resta=$num1-$num2 
    Write-Host "La resta de los parametros es $resta"
}
#ilustracion 85
function Get-Resta {
    [CmdletBinding()]
    Param ([int]$num1, [int]$num2)
    $resta=$num1-$num2 
    Write-Verbose -Message 
    Write-Host "La resta de los parametros es $resta"
}
Get-Resta 10 5 -Verbose