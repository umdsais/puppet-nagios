# Configures nagios client and sets up basic checks
class nagios::client {
  include nagios::nsca::client

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

  include ::nagios
  include ::cron::kernel_passive
  include ::cron::hardware_spec
  include ::nagios::plugins::core

  # Create a hostgroup for our OS
  @@nagios::create_hostgroup { $::fqdn:
    hostgroup      => downcase("${::operatingsystem}-${::operatingsystemmajrelease}"),
    hostgroupalias => "${::operatingsystem} ${::operatingsystemmajrelease}",
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
