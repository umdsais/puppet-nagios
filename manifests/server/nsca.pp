# Configure NSCA server
class nagios::server::nsca (
  $nsca_server_package,
  $nsca_service,
  $nsca_config,
  $firewall,
) {

  # Install NSCA server package
  package { 'nsca':
    ensure => installed,
    name   => $nsca_server_package,
  }

  # NSCA service to accept passive checks
  service { 'nsca':
    ensure     => running,
    name       => $nsca_service,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [ Service['nagios'], Package['nsca'], File['nsca.cfg'] ],
  }

  # NSCA config
  file { 'nsca.cfg':
    name    => $nsca_config,
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/nagios/nsca.cfg',
    require => Package['nsca'],
    notify  => Service['nsca'],
  }

  if ($firewall) {
    # Firewall rules for NSCA
    # Automatically grant NSCA access to any managed host
    Firewall <<| tag == 'nsca' |>>
  }
}
