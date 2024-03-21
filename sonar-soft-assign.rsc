{
# CONFIGURATION SETTINGS
# ############
# Change these values for your Sonar instance
:local url "cvi.sonar.software"
:local apikey "69e03131-2d91-4c9a-a05d-8502ce58ed89"
# The maximum retries to send to Sonar
:local max 30
# #############
# END CONFIGURATION SETTINGS
# Do not edit below
 
# Each https request has a 30 second retry

:local attempts 0
:local success 0
:do {
  :set attempts ($attempts+1);
  :if ($leaseBound = 0) do {
    :do {
      /tool fetch duration=30s url="https://$url/api/dhcp?ip_address=$leaseActIP&mac_address=$leaseActMAC&expired=1&api_key=$apikey" mode=https as-value output=user;
      :set success 1;
    } on-error={
      :log error "DHCP FAILED to send unassignment to $url on attempt $attempts out of $max for $leaseActMAC / $leaseActIP";
      :delay 3s;
    }
  } else {
    :delay 1s;
    # see note below
    :local remoteID [/ip dhcp-server lease get [find where address=$leaseActIP] agent-remote-id];
    :do {
      /tool fetch duration=30s url="https://$url/api/dhcp?ip_address=$leaseActIP&mac_address=$leaseActMAC&remote_id=$remoteID&expired=0&api_key=$apikey" mode=https as-value output=user;
      :set success 1;
    } on-error={
      :log error "DHCP FAILED to send assignment to $url on attempt $attempts out of $max for $leaseActMAC / $leaseActIP";
      :delay 3s;
    }
  }
  :if ($success) do {
    :log info "DHCP lease message successfully sent $leaseActMAC / $leaseActIP to $url";
    :set attempts $max;  # break out of the do..while loop
  }
} while ( $attempts < $max )
}