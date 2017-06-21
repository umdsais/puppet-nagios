# NRPE config for the Nagios server
class nagios::nrpe::server {

  # Install plugin to query NRPE on clients
  package { 'nagios-plugins-nrpe':
    ensure => installed,
  }

  # Auto-add a firewall rule in the NRPE clients just for us
  @@firewall { "100-nrpe-${::fqdn}":
    proto  => 'tcp',
    dport  => '5666',
    tag    => 'nrpe',
    source => $::ipaddress,
    action => 'accept',
  }
  @@firewall { "100-nrpe-v6-${::fqdn}":
    proto    => 'tcp',
    dport    => '5666',
    tag      => 'nrpe',
    source   => $::ipaddress6,
    provider => 'ip6tables',
    action   => 'accept',
  }
}
