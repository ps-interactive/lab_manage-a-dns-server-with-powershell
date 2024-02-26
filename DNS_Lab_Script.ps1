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
Get-DnsServerZone -name "StdZone1"
Get-DnsServerZone -name "StdZone2"

# 4.1.B - Verify the DNS zone files created in the System32/DNS folder
Get-ChildItem C:\Windows\System32\DNS

# 4.1.C - Delete standard Primary zone
Remove-DnsServerZone "StdZone2.com" -PassThru -Verbose
Get-DnsServerZone -name "StdZone2"

# 4.1.D - Create standard Primary zone using existing zone file
Add-DnsServerPrimaryZone -Name "StdZone2.com" -ZoneFile "StdZone2.com.dns"
Get-DnsServerZone -name "StdZone2"


# 2 - Managing AD integrated Primary zones

# 4.2.A - Create AD integrated primary zones
$ZoneList = Get-Content .\Lab_Files\CH4_AD_Integrated_zones.txt
foreach ($zone in $ZoneList)
{
    Add-DnsServerPrimaryZone -Name "$zone.com" -ReplicationScope Domain -DynamicUpdate Secure -Verbose
}
Get-DnsServerZone -name "ADZone1"
Get-DnsServerZone -name "ADZone1"



#########################################################################################################

# 5 - Managing Resource records

# 1 - Managing Resource records

# 5.1.A - Add a host record
Add-DnsServerResourceRecordA -Name "Server01" -IPv4Address "172.31.24.140" -ZoneName "globomantics.co" -Verbose
Add-DnsServerResourceRecordA -Name "Server20" -IPv4Address "172.31.24.20" -ZoneName "ADZone1" -Verbose
Add-DnsServerResourceRecordA -Name "Server21" -IPv4Address "172.31.24.21" -ZoneName "ADZone1" -Verbose

Get-DnsServerResourceRecord -ZoneName "globomantics.co" -Name "Server01"


# 5.1.B - Add a CNAME record
Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "FS01.globomantics.co" -ZoneName "globomantics.co" -Verbose

# 5.1.C - Remove a resource record
Remove-DnsServerResourceRecord -ZoneName "globomantics.co" -RRType "A" -Name "Server01" -RecordData "172.31.24.140"



#########################################################################################################


# 6 - Configuring Secondary Zones

# 6.1.A - Create a secondary zone
Add-DnsServerSecondaryZone -Name "ADZone1.globomantics.co" -ZoneFile "ADZone1.globomantics.co.dns" -MasterServers 172.31.24.110

# 6.1.B - Configure primary zone for zone transfer
Set-DnsServerPrimaryZone -Name "ADZone1.globomantics.co" -ComputerName "DC01.globomantics.co" -SecureSecondaries TransferToSecureServers -SecondaryServers 172.31.24.130 -Notify NotifyServers -NotifyServers 172.31.24.130 -Confirm:$False -PassThru

# 6.1.C - Initiate an incremental zone transfer
Start-DnsServerZoneTransfer -Name "ADZone1.globomantics.co" -FullTransfer



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
dnscmd dc /config /enableglobalnamessupport 1

# 8.1.C - Create a PTR record inside the GlobalNames zone
Add-DnsServerResourceRecordCName -Name "pki" -HostNameAlias "FS01.globomantics.co" -ZoneName "globomantics.co" -Verbose

# 8.1.D - Verify the GlobalNames Zone working
Resolve-DnsName pki



#########################################################################################################


# 9 - Configure DNS Forwarders

# 9.1.A - Create a primary zone on FS01
Add-DnsServerPrimaryZone -Name "ForwarderTest.com" -ZoneFile "ForwarderTest.com.dns" -DynamicUpdate NonsecureAndSecure -Verbose

# 9.1.B - Add a forwarder
Add-DNSServerForwarder 172.31.24.130

# 9.1.C - Retrieve a forwarder
Get-DNSServerForwarder

# 9.1.D - Resolve query to use DNS Forwarder
Resolve-DNSName "Plularsight.com"

# 9.1.E - Remove a forwarder
Remove-DnsServerForwarder -IPAddress 10.0.0.8 -Verbose



#########################################################################################################


# 10 - Configuring Conditional Forwarders

# 10.1.A - Create a primary zone on FS01
Add-DnsServerPrimaryZone -Name "Pluralsight.com" -ZoneFile "Pluralsight.com.dns" -DynamicUpdate NonsecureAndSecure -Verbose

# 10.1.B - Add a Conditional Forwarder
Add-DnsServerConditionalForwarderZone -Name "Pluralsight.com" -MasterServers 172.31.24.130 -PassThru

# 10.1.C - Retrieve a conditional forwarder
Get-DNSServerForwarder

# 10.1.D - Remove a conditional forwarder
Remove-DnsServerZone -Name "Pluralsight.com"

# 10.1.E - Verify the removal of conditional forwarder
Get-DNSServerForwarder



#########################################################################################################


# 11 - Configuring Zone Delegation

# 11.1.A - Create a new Primary zone on a separate DNS server
Add-DnsServerPrimaryZone -Name "DelegatedZone.com" -ZoneFile "DelegatedZone.com.dns" -DynamicUpdate NonsecureAndSecure -Verbose
Add-DnsServerResourceRecordA -Name "DelegatedServer" -IPv4Address "172.31.24.160" -ZoneName "DelegatedZone.com" -Verbose

# 11.1.B - Add a new zone delegation
Add-DNSServerZoneDelegation -Name "globomantics.co" -ChildZoneName "DelegatedZone" -NameServer "FS01.globomantics.co" -IPAddress 172.31.24.130

# 11.1.C - Retrieve a new zone delegation
Get-DnsServerZoneDelegation -Name "globomantics.co"

# 11.1.D - Verify the working of a new zone delegation
Resolve-DnsName DelegatedServer

# 11.1.E - Remove zone delegation
Remove-DnsServerZoneDelegation -Name "globomantics.co" -ChildZoneName "DelegatedZone" -PassThru -Verbose


#########################################################################################################