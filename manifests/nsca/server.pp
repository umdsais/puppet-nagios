# Configure NSCA server
class nagios::nsca::server {

  # Install NSCA server package
  package { 'nsca':
    ensure => installed,
    name   => $::osfamily ? {
      'RedHat' => 'nsca',
      'Debian' => 'nsca',
    },
  }

  # NSCA service to accept passive checks
  service { 'nsca':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [ Service['nagios'], Package['nsca'], File['nsca.cfg'] ],
  }

  # NSCA config
  file { 'nsca.cfg':
    name    => '/etc/nagios/nsca.cfg',
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/nagios/nsca.cfg',
    require => Package['nsca'],
    notify  => Service['nsca'],
  }

  # Firewall rules for NSCA
  # Automatically grant NSCA access to any managed host
  Firewall <<| tag == 'nsca' |>>
}
