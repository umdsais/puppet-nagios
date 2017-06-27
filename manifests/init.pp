# Nagios base class - single point of entry for all classes
class nagios (
  $client              = true,
  $server              = false,
  $nrpe                = false,
  $nsca                = false,
  $selinux             = false,
  $firewall            = false,
  $url                 = $::fqdn,
  $nrpe_package        = $nagios::params::nrpe_package,
  $webroot             = $nagios::params::webroot,
  $cgiroot             = $nagios::params::cgiroot,
  $dev                 = false,
  $nsca_client_package = $nagios::params::nsca_client_package,
  $nrpe_service        = $nagios::params::nrpe_service,
  $nrpe_config         = $nagios::params::nrpe_config,
  $nrpe_d              = $nagios::params::nrpe_d,
  $nrpe_plugin_package = $nagios::params::nrpe_plugin_package,
  $nsca_server_package = $nagios::params::nsca_server_package,
  $nsca_service        = $nagios::params::nsca_service,
  $nsca_config         = $nagios::params::nsca_config,
  $nagios_package      = $nagios::params::nagios_package,
  $nagios_service      = $nagios::params::nagios_service,
  $serveradmin         = 'root@localhost',
) inherits nagios::params {

  # Configure Nagios client
  if ($client) {
    class { '::nagios::client':
      nrpe                => $nrpe,
      nsca                => $nsca,
      selinux             => $selinux,
      firewall            => $firewall,
      nsca_client_package => $nsca_client_package,
      nrpe_package        => $nrpe_package,
      nrpe_service        => $nrpe_service,
      nrpe_config         => $nrpe_config,
      nrpe_d              => $nrpe_d,
    }
  }

  # Configure Nagios server
  if ($server) {
    class { '::nagios::server':
      url                 => $url,
      nrpe                => $nrpe,
      nsca                => $nsca,
      selinux             => $selinux,
      firewall            => $firewall,
      webroot             => $webroot,
      cgiroot             => $cgiroot,
      dev                 => $dev,
      nagios_package      => $nagios_package,
      nagios_service      => $nagios_service,
      serveradmin         => $serveradmin,
      nsca_server_package => $nsca_server_package,
      nsca_service        => $nsca_service,
      nsca_config         => $nsca_config,
      nrpe_plugin_package => $nrpe_plugin_package,
    }
  }
}
