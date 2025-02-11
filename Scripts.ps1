#ilustracion 93
try {
    Write-Output "Todo bien"
}
catch {
    Write-Output "Algo lanzo una excepcion"
    Write-Output $_
}

try {
    Start-Something -ErrorAction Stop
}
catch {
    Write-Output "Algo genero una excepcion o uso Write-Error"
    Write-Output $_
}
#ilustracion 94
$comando = [System.Data.SqlClient.SqlCommand]::New(#queryString, connection
)
try {
    $comando.Connection.Open()
    $comando.ExecuteNonQuery()
}
finally {
    Write-Error "Ha habido un problema con la ejecucion de la query. Cerrando la conexion"
    $comando.Connection.Close()
}
#ilustracion 95
try {
    Start-Something -Path $path -ErrorAction Stop
}
catch [System.IO.DirecoryNotFoundException],[System.IO.FileNotFoundException]{
    Write-Output "El directorio o fichero no ha sido encontrado: [$path]"
}
catch [System.IO.IDException]{
    Write-Output "Error de ID con el archivo: [$path]"
}
#ilustracion 96
throw "No se puede encontrar la ruta: [$path]"
throw [System.IO.FileNotFoundException] "No se puede encontrar la ruta: [$path]"
throw [System.IO.FileNotFoundException]::new()
throw [System.IO.FileNotFoundException]::new("No se puede encontrar la ruta: [$path]")
throw (New-Object -TypeName System.IO.FileNotFoundException)
throw (New-Object -TypeName System.IO.FileNotFoundException -ArgumentList "No se puede encontrar la ruta: [$ruta]")
#ilustracion 97
trap
{
    Write-Output $PSItem.ToString()
}
throw [System.Exception]::new('primero')
throw [System.Exception]::new('segundo')
throw [System.Exception]::new('tercero')
#ilustracion 98
function Backup-Registry {
    Param(
    [Parameter(Mandatory = $true)]
    [string]$rutaBackup
    )
    # Crear la ruta de destino del backup si no existe
    if (!(Test-Path -Path $rutaBackup)) {
    New-Item -ItemType Directory -Path $rutaBackup | Out-Null
    }
    # Generar un nombre único para el archivo de backup
    $nombreArchivo = "Backup-Registry_" + (Get-Date -Format "yyyyMM-dd_HH-mm-ss") + ".reg"
    $rutaArchivo = Join-Path -Path $rutaBackup -ChildPath
    $nombreArchivo
    # Realizar el backup del registro del sistema y guardarlo en el
    archivo de destino
    try {
    Write-Host "Realizando backup del registro del sistema en
    $rutaArchivo..."
    reg export HKLM $rutaArchivo
    Write-Host "El backup del registro del sistema se ha
    realizado con éxito."
    }
    catch {
    Write-Host "Se ha producido un error al realizar el backup
    del registro del sistema: $_"
    }
    }
#ilustracion 99
# Escribir en el archivo de log
$logDirectory = "$env:APPDATA\RegistryBackup"
$logFile = Join-Path $logDirectory "backup-registry_log.txt"
$logEntry = "$(Get-Date) - $env:USERNAME - Backup -
$backupPath"
if (!(Test-Path $logDirectory)) {
New-Item -ItemType Directory -Path $logDirectory | Out-Null
}
Add-Content -Path $logFile -Value $logEntry
#ilustracion 100
# Verificar si hay más de $backupCount backups en el directorio y eliminar los más antiguos si es necesario
$backupCount = 10
$backups = Get-ChildItem $backupDirectory -Filter *.reg | SortObject LastWriteTime -Descending
if ($backups.Count -gt $backupCount) {
$backupsToDelete = $backups[$backupCount..($backups.Count -
1)]
$backupsToDelete | Remove-Item -Force
}
#ilustracion 101
@{
    ModuleVersion = '1.0.0'
    PowerShellVersion = '5.1'
    RootModule = 'Backup-Registry.ps1'
    Description = 'Módulo para realizar backups del registro del
    sistema de Windows'
    Author = 'Alice'
    FunctionsToExport = @('Backup-Registry')
}
#ilustracion 102
    #ls
#ilustracion 103
Get-Help Backup-Registry
#ilustracion 104
Backup-Registry -rutaBackup 'D:\tmp\Backups\Registro\'
    #ls .\tmp\Backups\Registro\
#ilustracion 105
vim .\Backup-Registry.ps1
Import-Module BackupRegistry -Force
Backup-Registry -rutaBackup 'D:\tmp\Backups\Registro\'
    #ls 'D:\tmp\Backups\Registro\'
#ilustracion 106
# Configuración de la tarea
$Time = New-ScheduledTaskTrigger -At 02:00 -Daily
# Acción de la tarea
$PS = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument
"-Command `"Import-Module BackupRegistry -Force; Backup-Registry -
rutaBackup 'D:\tmp\Backups\Registro'`""
# Crear la tarea programada
Register-ScheduledTask -TaskName "Ejecutar Backup del Registro del
Sistema" -Trigger $Time -Action $PS
#ilustracion 107
    #ls 'D:\tmp\Backups\Registro\'
Get-Date
    #ls 'D:\tmp\Backups\Registro\'
#ilustracion 108
Get-ScheduledTask
#ilustracion 109
Unregister-ScheduledTask 'Ejecutar Backup del Registro del Sistema'
#ilustacion 110
Get-ScheduledTask