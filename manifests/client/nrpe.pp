# NRPE config for clients
class nagios::client::nrpe (
  $nrpe_package,
  $nrpe_service,
  $nrpe_config,
  $nrpe_d,
  $selinux,
) {

  # Find our Nagios server(s)
  $nagios_server = hiera_array('nagios_server')
  $nagios_server_list = join($nagios_server, ',')

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
