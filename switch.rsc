# model = CRS309-1G-8S+
{
:global sysName "WestBethany"
:global swIP "10.200.21.2"
:global swSM "24"
:global swGW "10.200.21.1"
:global bridgeVLANs [:toarray value="101,1210,2010,2380,2381,2410,2411,900"];
:global mgmtVLAN "1210"
:global snmpCommunity "tekwav"
:global sntpServer "208.67.102.151"
:local swPW "changeme"



:foreach i in=[/interface ethernet find] do={/interface ethernet set l2mtu=1600 numbers=$i}

/interface bridge
add name=bridge1 vlan-filtering=yes
/interface bridge port
:foreach i in=[/interface ethernet find] do={/interface bridge port add bridge=bridge1 interface=$i}
:foreach i in $bridgeVLANs do={/interface bridge vlan add bridge=bridge1 vlan-ids=$i}
{
    /interface ethernet
    :global InterfaceList ""
    :global separator ""
    :foreach i,Interface in=[ find where default-name~"ether*|sfp*|qsfp*" ] do={
        :set $InterfaceList "$InterfaceList$separator$[ get $Interface name ]"
        :if ($i = 0) do={ :set separator "," }
    }

    :put $InterfaceList
    /interface bridge vlan set tagged="$InterfaceList,bridge1" [ find where vlan-ids=$mgmtVLAN ]
}
/ip address
add address="$swIP/$swSM" interface=bridge1
/ip dns
set servers=172.82.32.3,8.8.8.8,8.8.4.4
/ip route
add distance=1 gateway=$swGW
/snmp
set enabled=yes
/system clock
set time-zone-name=America/Chicago
/system identity
set name="CS-309-01.$sysName"
/system ntp client
set enabled=yes primary-ntp=$sntpServer
/system package update
set channel=long-term
#Configure SNMP
/snmp community
set [ find default=yes ] name=$snmpCommunity
/snmp
set enabled="yes"
#Set user password
/user set [ find where name="admin" ] password="$swPW"
}