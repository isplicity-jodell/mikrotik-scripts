#Establish your fulladmin group before applying this

#These rules block all traffic that isn't from active sonar accounts from passing
/ip firewall filter
add action=accept chain=forward comment="Allow established/related connections" connection-state=established,related
add action=drop chain=forward comment="Drop SMB" dst-port=445 protocol=tcp
add action=accept chain=forward comment="Allow active customers" src-address-list=CX-ACTIVE
add action=accept chain=forward dst-address-list=CX-ACTIVE
add action=accept chain=forward comment="Allow from our infrastructure" src-address-list=fulladmin
add action=accept chain=forward dst-address-list=fulladmin
add action=accept chain=forward comment="Allow Lead Customers" src-address-list=CX-LEAD
add action=accept chain=forward dst-address-list=CX-LEAD
add action=accept chain=forward comment="::::::::::::: SONAR AUTHENTICATOR DROP -- DISABLE IF SONAR SYNC IS BROKEN"

#Everything from here down will restrict access to the local router. fulladmin group needs populated before applying this part.
/ip firewall filter
add action=accept chain=input comment="Accept established/related" connection-state=established,related
add action=accept chain=input comment="MT Discovery" dst-port=5678 protocol=udp
add action=accept chain=input comment="Allow Admin Access" src-address-list=fulladmin
add action=accept chain=input comment="BTest Rules" dst-port=2000-2100 protocol=udp
add action=accept chain=input dst-port=2000-2100 protocol=tcp
add action=accept chain=input comment="Allow ICMP" protocol=icmp
add action=accept chain=input protocol=ospf
add action=drop chain=input comment="Drop else"