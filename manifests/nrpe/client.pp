# NRPE config for clients
class nagios::nrpe::client {

  package { 'nrpe':
    ensure  => installed,
    name    => $::osfamily ? {
      'RedHat' => 'nrpe',
      'Debian' => 'nagios-nrpe-server',
    },
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
    name       => $::osfamily ? {
      'RedHat' => 'nrpe',
      'Debian' => 'nagios-nrpe-server',
      default  => 'nrpe',
    },
    require    => [ File['nrpe.cfg'], Package['nrpe'] ],
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  # Install SELinux NRPE policy
  if $::osfamily == 'RedHat' {
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
    name    => '/etc/nagios/nrpe.cfg',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/nagios/nrpe/nrpe.cfg',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
  }

  # Add a symlink for the different path on ubuntu
  if $::osfamily == 'Debian' {
    file { '/etc/nrpe.d':
      ensure => link,
      target => '/etc/nagios/nrpe.d',
    }
  }

  # Add a VIRTUAL nrpe user
  @user { 'nrpe':
    ensure => present,
  }

  # Then realize that virtual user with collection syntax
  User <| title == 'nrpe' |>

  # Add firewall rule to allow NRPE from the monitoring server
  Firewall <<| tag == 'nrpe' |>>
