Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name ssh-agent -StartupType "Automatic"
Set-Service -Name sshd -StartupType "Automatic"
Start-Service sshd

Get-NetTCPConnection -State Listen | Where {$_.localport -eq "22"}
Enable-NetFirewallRule -Name *OpenSSH-Server*

Get-NetFirewallRule -Group "OpenSSH Server"