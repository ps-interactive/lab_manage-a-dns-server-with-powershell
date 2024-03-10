# 3 - Install DNS service

# 3.1.A - Get current status of DNS service on the server
Get-WindowsFeature -name DNS

# 3.1.B - Istall DNS service
Add-WindowsFeature -name DNS -IncludeAllSubFeature -IncludeManagementTools -Verbose

# 3.1.C - Verify the status of DNS service
Get-WindowsFeature -name DNS



#########################################################################################################

# 4 - Configuring DNS Primary Zones

# 1 - Manage standard Primary zones
# 4.1.A - Create standard Primary zones
$ZoneList = Get-Content .\Lab_Files\CH4_Standard_zones.txt
foreach ($zone in $ZoneList)
{
    Add-DnsServerPrimaryZone -Name "$zone.com" -ZoneFile "$zone.com.dns" -DynamicUpdate NonsecureAndSecure -Verbose
}
Get-DnsServerZone -name "StdZone1.com"
Get-DnsServerZone -name "StdZone2.com"

# 4.1.B - Verify the DNS zone files created in the System32/DNS folder
Get-ChildItem C:\Windows\System32\DNS

# 4.1.C - Delete standard Primary zone
Remove-DnsServerZone "StdZone2.com" -PassThru -Verbose -Force
Get-DnsServerZone -name "StdZone2.com"

# 4.1.D - Create standard Primary zone using existing zone file
Add-DnsServerPrimaryZone -Name "StdZone2.com" -ZoneFile "StdZone2.com.dns"
Get-DnsServerZone -name "StdZone2.com"


# 2 - Managing AD integrated Primary zones

# 4.2.A - Create AD integrated primary zones
$ZoneList = Get-Content .\Lab_Files\CH4_AD_Integrated_zones.txt
foreach ($zone in $ZoneList)
{
    Add-DnsServerPrimaryZone -Name "$zone.com" -ReplicationScope Domain -DynamicUpdate Secure -Verbose
}
Get-DnsServerZone -name "ADZone1.com"
Get-DnsServerZone -name "ADZone2.com"



#########################################################################################################

# 5 - Managing Resource records

# 1 - Managing Resource records

# 5.1.A - Add a host record
Add-DnsServerResourceRecordA -Name "Server01" -IPv4Address "172.31.24.140" -ZoneName "globomantics.co" -Verbose
Add-DnsServerResourceRecordA -Name "Server20" -IPv4Address "172.31.24.20" -ZoneName "ADZone1.com" -Verbose
Add-DnsServerResourceRecordA -Name "Server21" -IPv4Address "172.31.24.21" -ZoneName "ADZone1.com" -Verbose

Get-DnsServerResourceRecord -ZoneName "globomantics.co" -Name "Server01"


# 5.1.B - Add a CNAME record
Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "FS01.globomantics.co" -ZoneName "globomantics.co" -Verbose

# 5.1.C - Remove a resource record
Remove-DnsServerResourceRecord -ZoneName "globomantics.co" -RRType "A" -Name "Server01" -RecordData "172.31.24.140" -Force



#########################################################################################################


# 6 - Configuring Secondary Zones

# 6.1.A - Create a secondary zone
Add-DnsServerSecondaryZone -Name "ADZone1.com" -ZoneFile "ADZone1.co.dns" -MasterServers 172.31.24.110 -ComputerName FS01

# 6.1.B - Configure primary zone for zone transfer
Set-DnsServerPrimaryZone -Name "ADZone1.com" -ComputerName "DC01.globomantics.co" -SecureSecondaries TransferToSecureServers -SecondaryServers 172.31.24.130 -Notify NotifyServers -NotifyServers 172.31.24.130 -Confirm:$False -PassThru

# 6.1.C - Initiate an incremental zone transfer
Add-DnsServerResourceRecordA -Name "Server22" -IPv4Address "172.31.24.22" -ZoneName "ADZone1.com" -Verbose
Start-DnsServerZoneTransfer -Name "ADZone1.com" -FullTransfer



#########################################################################################################


# 7 - Configure Reverse Lookup Zone

# 7.1.A - Create a reverse lookup zone
Add-DnsServerPrimaryZone -NetworkID "172.31.24.0/24" -ReplicationScope Domain -DynamicUpdate Secure -Verbose

# 7.1.B - Create a PTR record
Add-DnsServerResourceRecordPtr -Name "130" -ZoneName "24.31.172.in-addr.arpa" -PtrDomainName "FS01.globomantics.co" 

# 7.1.C - Test and verify reverse lookup name resolution
Resolve-DnsName 172.31.24.130



#########################################################################################################


# 8 - Configure Global Names

# 8.1.A - Add a Primary zone for GlobalNames
Add-DnsServerPrimaryZone -Name "GlobalNames" -ReplicationScope Domain -DynamicUpdate Secure -Verbose

# 8.1.B - Enable GlobalNames settings on the DNS server
dnscmd DC01 /config /enableglobalnamessupport 1

# 8.1.C - Create a PTR record inside the GlobalNames zone
Add-DnsServerResourceRecordCName -Name "pki" -HostNameAlias "FS01.globomantics.co" -ZoneName "globalnames" -Verbose

# 8.1.D - Verify the GlobalNames Zone working
Resolve-DnsName pki



#########################################################################################################


# 9 - Configure DNS Forwarders

# 9.1.A - Create a primary zone on FS01
Add-DnsServerPrimaryZone -Name "testcompany.com" -ZoneFile "testcompany.dns" -DynamicUpdate NonsecureAndSecure -Verbose

# 9.1.B - Add a forwarder
Add-DNSServerForwarder 172.31.24.130

# 9.1.C - Retrieve a forwarder
Get-DNSServerForwarder

# 9.1.D - Resolve query to use DNS Forwarder
Resolve-DNSName "testcompany.com"

# 9.1.E - Remove a forwarder
Remove-DnsServerForwarder -IPAddress 172.31.24.130 -Verbose -Force



#########################################################################################################


# 10 - Configuring Conditional Forwarders

# 10.1.A - Create a primary zone on FS01
Add-DnsServerPrimaryZone -Name "Pluralsight.com" -ZoneFile "Pluralsight.com.dns" -DynamicUpdate NonsecureAndSecure -Verbose

# 10.1.B - Add a Conditional Forwarder
Add-DnsServerConditionalForwarderZone -Name "Pluralsight.com" -MasterServers 172.31.24.130 -PassThru

# 10.1.C - Retrieve a conditional forwarder
Get-DNSServerForwarder

# 10.1.D - Resolve a conditional forwarder
Resolve-DNSName "Pluralsight.com"

# 10.1.E - Remove a conditional forwarder
Remove-DnsServerZone -Name "Pluralsight.com" -Force -PassThru -Verbose