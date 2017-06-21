# Default params for nagios
class nagios::params {

  # Name of Nagios package
  $nagios_package = $::osfamily ? {
    'RedHat' => 'nagios',
    'Debian' => 'nagios',
    default  => 'nagios',
  }
}
