# Default params for nagios
class nagios::params {

  # Name of Nagios package
  $nagios_package = $::osfamily ? {
    'RedHat' => 'nagios',
    'Debian' => 'nagios',
    default  => 'nagios',
  }

  $nagios_service = $::osfamily ? {
    'RedHat' => 'nagios',
    'Debian' => 'nagios',
    default  => 'nagios',
  }

  $nrpe_package = $::osfamily ? {
    'RedHat' => 'nrpe',
    'Debian' => 'nagios-nrpe-server',
  }

  $nrpe_server = $::osfamily ? {
    'RedHat' => 'nrpe',
    'Debian' => 'nagios-nrpe-server',
    default  => 'nrpe',
  }

  $nrpe_config = $::osfamily ? {
    'RedHat' => '/etc/nagios/nrpe.cfg',
    'Debian' => '/etc/nagios/nrpe.cfg',
    default  => '/etc/nagios/nrpe.cfg',
  }

  $nrpe_d = $::osfamily ? {
    'RedHat' => '/etc/nrpe.d',
    'Debian' => '/etc/nagios/nrpe.d',
    default  => '/etc/nrpe.d',
  }

  $nrpe_plugin_package = $::osfamily ? {
    'RedHat' => 'nagios-plugins-nrpe',
  }

  $nsca_client_package = $::osfamily ? {
    'RedHat' => 'nsca-client',
    'Debian' => 'nsca-client',
    default  => 'nsca-client',
  }

  $nsca_server_package = $::osfamily ? {
    'RedHat' => 'nsca',
    'Debian' => 'nsca',
    default  => 'nsca',
  }

  $nsca_service = $::osfamily ? {
    'RedHat' => 'nsca',
    'Debian' => 'nsca',
    default  => 'nsca',
  }

  $nsca_config = $::osfamily ? {
    'RedHat' => '/etc/nagios/nsca.cfg',
    'Debian' => '/etc/nagios/nsca.cfg',
    default  => '/etc/nagios/nsca.cfg',
  }

  $webroot = $::osfamily ? {
    default => '/usr/share/nagios/html',
  }

  $cgiroot = $::osfamily ? {
    default => '/usr/lib64/nagios/cgi-bin',
  }
}
