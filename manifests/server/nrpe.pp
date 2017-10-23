# NRPE config for the Nagios server
class nagios::server::nrpe (
  Boolean $firewall,
  String $nrpe_plugin_package,
) {

  # Install plugin to query NRPE on clients
  package { 'nagios-plugins-nrpe':
    ensure => installed,
    name   => $nrpe_plugin_package,
  }

  # Define Nagios command to run NRPE checks
  nagios_command { 'check_nrpe':
    command_line => '$USER1$/check_nrpe -u -H $HOSTADDRESS$ -t 20 -c $ARG1$',
    tag          => hiera('nagios_server'),
  }

  if ($firewall) {
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
}
