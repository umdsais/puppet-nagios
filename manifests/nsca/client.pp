# Install NSCA client
class nagios::nsca::client (
  $nsca_client_package,
  $firewall,
) {
  package { 'nsca-client':
    ensure => installed,
    name   => $nsca_client_package,
  }

  if ($firewall) {
    # Auto-add a NSCA firewall rule on the NSCA server just for us
    @@firewall { "200-nsca-${::fqdn}":
      proto  => 'tcp',
      dport  => '5667',
      tag    => 'nsca',
      source => $::default_ipaddress,
      action => 'accept',
    }
    @@firewall { "200-nsca-v6-${::fqdn}":
      proto    => 'tcp',
      dport    => '5667',
      source   => $::ipaddress6,
      provider => 'ip6tables',
      action   => 'accept',
    }
  }
}
