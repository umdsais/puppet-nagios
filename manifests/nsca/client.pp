# Install NSCA client
class nagios::nsca::client {
  package { 'nsca-client':
    ensure => installed,
    name   => $::osfamily ? {
      'RedHat' => 'nsca-client',
      'Debian' => 'nsca-client',
    },
  }

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
