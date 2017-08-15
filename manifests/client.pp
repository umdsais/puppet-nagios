# Configures nagios client and sets up basic checks
class nagios::client (
  $nrpe                = true,
  $nsca                = true,
  $selinux             = true,
  $firewall            = true,
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
  $ssl_cert            = '/path/to/cert.crt',
  $ssl_key             = '/path/to/key.key',
  $ssl_chain           = undef,
  $auth_type           = 'basic',
) inherits nagios::params {

  if ($nsca) {
    class { '::nagios::nsca::client':
      nsca_client_package =>  $nsca_client_package,
      firewall            =>  $firewall,
    }
  }

  if ($nrpe) {
    class { '::nagios::nrpe::client':
      nrpe_package =>  $nrpe_package,
      nrpe_service =>  $nrpe_service,
      nrpe_config  =>  $nrpe_config,
      nrpe_d       =>  $nrpe_d,
      selinux      =>  $selinux,
    }
  }

  # NOTE
  # We are using $::default_ipaddress in some places as it returns the IP
  # of the interface that is the default gateway, as opposed to $::ipaddress
  # which returns the IP of the first alphabetical interface. This causes
  # problems on machines running Docker
  # https://tickets.puppetlabs.com/browse/FACT-380
  #
  # This should be fixed in Facter 3 / Puppet 4. To remove this workaround,
  # revert the commits within MR !664
  # https://git.services.bristol.ac.uk/resnet/resnet-puppet/merge_requests/664

  if $::osfamily == 'RedHat' {
    package { ['nagios-plugins',
      'nagios-plugins-all',
      'nagios-plugins-bonding',
      'nagios-plugins-perl']:
      ensure  => installed,
      require => Class['epel'],
    }
  }

  if $::operatingsystem == 'Ubuntu' {
    package { ['nagios-plugins',
      'nagios-plugins-basic',
      'nagios-plugins-standard',
      'nagios-plugins-extra']:
    ensure  => installed,
    }
  }

  # Create a hostgroup for our OS
  @@nagios::create_hostgroup { $::fqdn:
    hostgroup      => downcase("${::operatingsystem}-${::operatingsystemmajrelease}"),
    hostgroupalias => "${::operatingsystem} ${::operatingsystemmajrelease}",
    tag            => 'nagios',
  }

  # Define the host in nagios, including parent hypervisor, if there is one
  $ilom = hiera('ilom', undef)
  $parent = hiera('nagios::parent', undef)
  if ($ilom) {
    $ilomnotes = "iLOM address: ${ilom}"
  } else {
    $ilomnotes = undef
  }
  @@nagios_host { $::fqdn:
    ensure          => present,
    address         => $::default_ipaddress,
    use             => 'generic-host',
    action_url      => "/nagios/pnp4nagios/graph?host=${::fqdn}",
    notes           => $ilomnotes,
    parents         => $parent,
    hostgroups      => downcase("${::operatingsystem}-${::operatingsystemmajrelease}"),
    icon_image_alt  => $::operatingsystem,
    icon_image      => "${::operatingsystem}.png",
    statusmap_image => "${::operatingsystem}.gd2",
    tag             => 'nagios',
    target          => "/etc/nagios/conf.d/${::fqdn}-host.cfg",
  }

  #### NRPE
  nagios::service { "check_nrpe_${::fqdn}":
    check_command       => 'check_nrpe_status',
    service_description => 'NRPE',
    tag                 => hiera('nagios_server'),
  }

  # Install supplementary nrpe config
  # First we template a couple of useful values
  $warnload = $::processorcount*7
  $critload = $::processorcount*10

  $lib = $::architecture ? {
    'i386'   => 'lib',
    'x86_64' => 'lib64',
    default  => 'lib',
  }
}
