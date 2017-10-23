# NRPE config for clients
class nagios::client::nrpe (
  String $nrpe_package,
  String $nrpe_service,
  String $nrpe_config,
  String $nrpe_d,
  Boolean $selinux,
) {

  # Find our array of Nagios server(s) from Hiera
  $nagios_servers = hiera_array('nagios_server')

  # Map each hostname from the array to one or more IPs
  $nagios_server_ips = $nagios_servers.map |String $nagios_server| {
    dns_a($nagios_server)
  }

  # Squash the arrays of hostnames and IPs into strings that can be read by NRPE
  $nagios_server_list = join($nagios_servers, ',')
  $nagios_server_ip_list = join($nagios_server_ips, ',')

  package { 'nrpe':
    ensure  => installed,
    name    => $nrpe_package,
    require => [Class['epel'],User['nrpe']],
  }

  # Install some perl modules on Debian as they don't seem to get pulled in by any dependencies
  if $::operatingsystem == 'Debian' {
    package { 'libnagios-plugin-perl':
      ensure => installed,
    }
  }

  # Start the service
  service { 'nrpe':
    ensure     => running,
    name       => $nrpe_service,
    require    => [ File['nrpe.cfg'], Package['nrpe'] ],
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  # Install SELinux NRPE policy
  if ($selinux) {
    selinux::module { 'nrpe':
      ensure    => 'present',
      source_te => 'puppet:///modules/nagios/nrpe/nrpe.te',
    }
    selboolean { 'nagios_run_sudo':
      name       => nagios_run_sudo,
      persistent => true,
      value      => on,
    }
  }

  # Install base nrpe config
  file { 'nrpe.cfg':
    name    => $nrpe_config,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('nagios/nrpe.cfg.erb'),
    require => Package['nrpe'],
    notify  => Service['nrpe'],
  }

  # Add a VIRTUAL nrpe user
  @user { 'nrpe':
    ensure => present,
  }

  # Then realize that virtual user with collection syntax
  User <| title == 'nrpe' |>

  # Add firewall rule to allow NRPE from the monitoring server
  Firewall <<| tag == 'nrpe' |>>
}
