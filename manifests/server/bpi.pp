# Install the Nagios BPI addon
class nagios::server::bpi (
  $url,
  $selinux,
  $webroot,
) {

  # Install BPI
  package { 'nagiosbpi':
    ensure => installed,
  }

  # Take over ownership of the BPI config file
  concat { 'bpi.conf':
    ensure  => present,
    path    => "${webroot}/bpi/bpi.conf",
    require => Package['nagiosbpi'],
    owner   => 'root',
    group   => 'apache',
    mode    => '0644',
  }

  # Print BPI config header
  # Read the notes in this file about how to configure BPI
  concat::fragment{ 'bpi-header':
    target => 'bpi.conf',
    source => 'puppet:///modules/nagios/bpi.conf.header',
    order  => '10',
  }

  file { "${webroot}/bpi/tmp":
    ensure  => directory,
    owner   => 'root',
    group   => 'apache',
    recurse => true,
    mode    => '0777',
    require => Package['nagiosbpi'],
  }

  # Define the check_bpi plugin for use with Nagios
  nagios_command { 'check_bpi':
    command_line => '$USER1$/check_bpi.php $ARG1$',
  }

  # Create a dummy host which will have BPI checks associated with it
  nagios_host { 'bpi':
    host_name       => 'bpi',
    use             => 'generic-host',
    display_name    => 'BPI',
    check_command   => 'check_dummy!0',
    icon_image      => 'nagios.gif',
    statusmap_image => 'nagios.gd2',
    notes_url       => "https://${url}/nagios/bpi/index.php",
  }

  # Install SELinux Nagios BPI policy
  if ($selinux) {
    selinux::module { 'bpi':
      ensure    => 'present',
      source_te => 'puppet:///modules/nagios/bpi.te',
    }
  }
}
