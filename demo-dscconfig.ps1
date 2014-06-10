#requires -version 4.0

Configuration ChicagoServers {

Param([string[]]$Computername)  

Node $computername {
   
    File Reports {
     DestinationPath = 'C:\Reports'
     Ensure = 'Present'
     Type = 'Directory'
    } #end File resource

     Service WindowsUpdate  {
      Name = 'wuauserv'
      StartupType = 'Automatic'
      State = 'Running' 
     } #end Service resource
     
     WindowsFeature WindowsBackup {
      Name = 'Windows-Server-Backup'
      Ensure = 'Present'
      IncludeAllSubFeature = $True 

     } #end WindowsFeature resource

} #node

Node CHI-TEST01 {

Environment foo {
 Name = 'foo'
 Ensure = 'Present'
 Value = 'bar'
 } #end Environment resource

} #node

} #configuration

<#

#create the mof

$computers = 'chi-core01','chi-fp02','chi-test01'

chicagoServers -computername $computers

#push the config
Start-DscConfiguration ChicagoServers -wait

#test the config
Get-dscconfiguration -cimsession chi-core01

#manually break the config
Uninstall-WindowsFeature -name "Windows-Server-Backup" -computername 'chi-core01'
invoke-command { get-item c:\reports | del -force } -comp chi-core01,chi-test01

#re-test
test-dscconfiguration -cimsession chi-fp02
test-dscconfiguration -cimsession chi-core01
test-dscconfiguration -cimsession chi-core01 -verbose
test-dscconfiguration -cimsession chi-te01 -verbose
#remediate

($Computers).foreach({
if (-Not (Test-DscConfiguration -CimSession $psitem)) {
   Start-DscConfiguration -path C:\scripts\ChicagoServers -Computername $psitem -wait 
}})

#>