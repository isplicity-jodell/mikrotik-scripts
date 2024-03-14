#This will compare existing bgp networks to ospf networks
#This is made for ROS v6 and will not work on v7
{
  :local bgpNetworks [:toarray ""]
  :foreach i in=[/routing bgp network find] do={:set bgpNetworks ($bgpNetworks, [/routing bgp network get $i network]) }
  :put "\n\n Missing OSPF Networks: \n"
  :foreach i in=[$bgpNetworks] do={
    :if ([/routing ospf network find where network=$i]="") do={:put $i}
  }
}