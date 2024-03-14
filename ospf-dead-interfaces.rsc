#Execute from terminal and this will spit out all configured ospf/interfaces that don't have active neighbors in ospf/neighbors
#This is made for ROS v6 and will not work on v7
{
  :local oInterfaces [:toarray ""]
  :foreach i in=[/routing ospf interface find where passive=no] do={:set oInterfaces ($oInterfaces, [/routing ospf interface get $i interface]) }
  :put "\n\n Possible Dead OSPF Links: \n"
  :foreach i in=[$oInterfaces] do={
    :if ([/routing ospf neighbor find where interface=$i]="") do={:put $i}
  }
}