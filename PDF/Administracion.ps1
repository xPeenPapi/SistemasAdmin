#111
Get-Service
#112
Get-Service -Name Spooler
Get-Service -DisplayName Hora*
#113
Get-Service | Where-Object {$_.Status -eq "Running"}
#114
Get-Service |
Where-Object {$_.StartType -eq "Automatic"} |
Select-Object Name, StartType
#115
Get-Service -DependentServices Spooler
#116
Get-Service -RequiredServices Fax
#117
Stop-Service -Name Spooler -Confirm -PassThru
#118
Start-Service -Name Spooler -Confirm -PassThru
#119
Suspend-Service -Name stisvc -Confirm -PassThru
#120
Get-Service | Where-Object CanPauseAndContinue -eq True
#121
Suspend-Service -Name Spooler
#122
Restart-Service -Name WSearch -Confirm -PassThru
#123
Set-Service -Name dcsvc -DisplayName "Servicio de virtualizacion de credenciales de seguridad distribuidas"
#124
Set-Service -Name BITS -StartupType Automatic -Confirm -PassThru | Select-Object Name, StartType
#125
Set-Service -Name BITS -Descriptionw "Transfiere archivos en segundo plano mediante el uso de ancho de banda de red inactivo."
#126
Get-CimInstance Win32_Service -Filter 'Name = "BITS"' | Format-List Name, Description
#127
Set-Service -Name Spooler -Status Running -Confirm -PassThru
#128
Set-Service -Name BITS -Status Stopped -Confirm -PassThru
#129
Set-Service -Name stisvc -Status Paused -Confirm -PassThru
#130
Get-Process
#131
Get-Process -Name Acrobat
Get-Process -Name Search*
Get-Process -Id 13948
#132
Get-Process WINWORD -FileVersionInfo
#133
Get-Process WINWORD -IncludeUserName
#134
Get-Process WINWORD -Module
#135
Stop-Process -Name Acrobat -Confirm -PassThru
Stop-Process -ID 10940 -Confirm -PassThru
Get-Process -Name Acrobat |Stop-Process -Confirm -PassThru
#136
Start-Process -FilePath "C:\Windows\System32\note.exe" -PassThru
#137
Start-Process -FilePath "cmd.exe" -ArgumentList "\c mkdir NuevaCarpeta" -WorkingDirectory "D:\Documents\FIC\Q6\ASO" -PassThru
#138
Start-Process -FilePath "notepad.exe" -WindowStyle "Maximized" -PassThru
#139
Start-Process -FilePath "D:\Documents\FIC\Q6\ASO\TT\TT.txt" -Verb Print -PassThru
#140
Get-Process -Name notep*
Get-Process -Name notepad | Wait-Process
#141
Get-LocalUser
#142
Get-LocalUser -SID S-1-5-21-619924196-4045554399-1956444398-500 | Select-Object *
#143
Get-LocalUser -Name Miguel | Select-Object *
#144
Get-LocalGroup
#145
Get-LocalGroup -Name Administradores | Select-Object *
#146
Get-LocalGroup -SID S-1-5-32-545 | Select-Object *
#147
New-LocalUser -Name "Usuario2" -Description "Usuario de prueba 2" -Password (ConvertTo-SecureString -AsPlainText "12345" -Force)
#148
New-LocalUser -Name "Usuario1" -Description "Usuario de prueba 1" -NoPassword
#149
Get-LocalUser -Name "Usuario1"
Get-LocalUser -Name "Usuario2"
#150
New-LocalGroup -Name 'Grupo1' -Description 'Grupo de prueba 1'
#151
Add-LocalGroupMember -Group Grupo1 -Member Usuario2 -Verbose
#152
Get-LocalGroupMember Grupo1
#153
Remove-LocalGroupMember -Group Grupo1 -Member Usuario1
Remove-LocalGroupMember -Group Grupo1 -Member Usuario2
Get-LocalGroupMember Grupo1
#154
Get-LocalGroup -Name "Grupo1"
