#ilustracion 50
Get-Service -Name "LSM" | Get-Member
#ilustracion 51
Get-Service -Name "LSM" | Get-Member -MemberType Property
#ilustracion 52
Get-Item .\test.txt | Get-Member -MemberType Method
#ilustracion 53
Get-Item .\test.txt | Select-Object Name, Lenght
#ilustracion 54
Get-Service | Select-Object -First 5
#ilustracion 55
Get-Service | Select-Object -Last 5
#ilustracion 56
Get-Service | Where-Object {$_.Status -eq "Running"}
#ilustracion 57
(Get-Item .\test.txt).IsReadOnly
(Get-Item .\test.txt).IsReadOnly = 1
(Get-Item .\test.txt).IsReadOnly
#ilustracion 58
Get-ChildItem *.txt
(Get-Item .\test.txt).CopyTo("D:\Desktop\prueba.txt")
(Get-Item .\test.txt).Delete()
Get-ChildItem *.txt
#ilustracion 59
$miObjeto = New-Object psobject
$miObjeto | Add-Member -MemberType NoteProperty -Name Nombre -Value "Miguel"
$miObjeto | Add-Member -MemberType NoteProperty -Name Edad -Value 23
$miObjeto | Add-Member -MemberType NoteProperty -Name Saludar -Value {Write-Host "Hola Mundo!"}
#ilustracion 60
$miObjeto = New-Object -TypeName psobject -Property @{
    Nombre = "Miguel"
    Edad = 23
}
$miObjeto | Add-Member -MemberType ScriptMethod -Name Saludar -Value {Write-Host "Hola Mundo!"}
$miObjeto | Get-Member
#ilustracion 61
$miObjeto = [PSCustomObject]@{
    Nombre = "Miguel"
    Edad = 23
}
$miObjeto | Add-Member -MemberType ScriptMethod -Name Saludar -Value {Write-Host "Hola Mundo!"}
$miObjeto | Get-Member
#ilustracion 62
Get-Process -Name Acrobat | Stop-Process
#ilustracion 63
Get-Help -Full Stop-Process
#ilustracion 64
Get-Help -Full Get-Process
#ilustracion 65
Get-Process
Get-Process -Name Acrobat | Stop-Process
Get-Process
#ilustracion 66
Get-ChildItem *.txt | Get-Clipboard
#ilustracion 67
Get-Help -Full Stop-Service
#ilustracion 68
    #-InputObject <ServiceController[]>
    #-Name <string[]>
#ilustracion 
Get-Service
Get-Service Spooler | Stop-Service
Get-Service
#ilustracion 70
Get-Service
"Spooler" | Stop-Service
Get-Service
Get-Service
#ilustracion 71
Get-Service
$miObjeto = [PSCustomObject]@{
    Name = "Spooler"
}
$miObjeto | Stop-Service
Get-Service
Get-Service