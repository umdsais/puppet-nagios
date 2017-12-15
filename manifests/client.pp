# Configures nagios client and sets up basic checks
class nagios::client (
  $nrpe                = true,
  $nsca                = true,
  $selinux             = true,
  $firewall            = true,
  $basic_checks        = true,
  $auto_os_hostgroup   = true,
  $auto_virt_hostgroup = true,
  $hostgroups          = [],
  $nrpe_package        = $nagios::params::nrpe_package,
  $nsca_client_package = $nagios::params::nsca_client_package,
  $nrpe_service        = $nagios::params::nrpe_service,
  $nrpe_config         = $nagios::params::nrpe_config,
  $nrpe_d              = $nagios::params::nrpe_d,
  $nrpe_plugin_package = $nagios::params::nrpe_plugin_package,
) inherits nagios::params {

  if ($nsca) {
    class { '::nagios::client::nsca':
      nsca_client_package =>  $nsca_client_package,
      firewall            =>  $firewall,
    }
  }

  if ($nrpe) {
    class { '::nagios::client::nrpe':
      nrpe_package =>  $nrpe_package,
      nrpe_service =>  $nrpe_service,
      nrpe_config  =>  $nrpe_config,
      nrpe_d       =>  $nrpe_d,
      selinux      =>  $selinux,
    }
  }

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
  if ($auto_os_hostgroup) {
    @@nagios::hostgroup { "${::fqdn}-os":
      hostgroup      => downcase("${::operatingsystem}-${::operatingsystemmajrelease}"),
      hostgroupalias => "${::operatingsystem} ${::operatingsystemmajrelease}",
      tag            => hiera('nagios_server'),
    }

    $os_hostgroup = downcase("${::operatingsystem}-${::operatingsystemmajrelease}")
  }

  # Create a hostgroup for our platform
  if ($auto_virt_hostgroup) {
    @@nagios::hostgroup { "${::fqdn}-virtual":
      hostgroup      => downcase($::virtual),
      hostgroupalias => $::virtual,
      tag            => hiera('nagios_server'),
    }

    $virt_hostgroup = downcase($::virtual)
  }

  # Make final array of hostgroups
  $final_hostgroups = delete_undef_values([
    $hostgroups,
    $os_hostgroup,
    $virt_hostgroup,
  ])

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
    address         => $::ipaddress,
    use             => 'generic-host',
    action_url      => "/nagios/pnp4nagios/graph?host=${::fqdn}",
    notes           => $ilomnotes,
    parents         => $parent,
    hostgroups      => join($final_hostgroups, ','),
    icon_image_alt  => $::operatingsystem,
    icon_image      => "${::operatingsystem}.png",
    statusmap_image => "${::operatingsystem}.gd2",
    tag             => hiera('nagios_server'),
    target          => "/etc/nagios/conf.d/${::fqdn}-host.cfg",
  }

  # Optionally install some basic checks
  if ($basic_checks) {
    class { '::nagios::client::checks':
      nrpe => $nrpe,
    }
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
