# Nagios base class - single point of entry for all classes
class nagios (
  $client   = true,
  $server   = false,
  $nrpe     = false,
  $nsca     = false,
  $selinux  = false,
  $firewall = false,
  $url      = $::fqdn,
) inherits nagios::params {

  # Configure Nagios client
  if ($client) {
    class { '::nagios::client': }
  }

  # Configure Nagios server
  if ($server) {
    class { '::nagios::server':
      url => $url,
    }
  }

}
