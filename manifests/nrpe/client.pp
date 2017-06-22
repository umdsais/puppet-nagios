# NRPE config for clients
class nagios::nrpe::client (
  $nrpe_package,
  $nrpe_service,
  $nrpe_config,
  $nrpe_d,
  $selinux,
) {

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
    selinux::module { 'resnet-nrpe':
      ensure    => 'present',
      source_te => 'puppet:///modules/nagios/nrpe/resnet-nrpe.te',
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
    source  => 'puppet:///modules/nagios/nrpe/nrpe.cfg',
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
