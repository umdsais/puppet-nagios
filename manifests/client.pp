# Configures nagios client and sets up basic checks
class nagios::client {

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

  package { 'nrpe':
    ensure  => installed,
    name    => $::osfamily ? {
      'RedHat' => 'nrpe',
      'Debian' => 'nagios-nrpe-server',
    },
    require => [Class['epel'],User['nrpe']],
  }

  package { 'nsca-client':
    ensure => installed,
    name   => $::osfamily ? {
      'RedHat' => 'nsca-client',
      'Debian' => 'nsca',
    },
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

  # Install supplementary nrpe config
  # First we template a couple of useful values
  $warnload = $::processorcount*7
  $critload = $::processorcount*10

  $lib = $::architecture ? {
    'i386'   => 'lib',
    'x86_64' => 'lib64',
    default  => 'lib',
  }

  # Add a symlink for the different path on ubuntu
  if $::osfamily == 'Debian' {
    file { '/etc/nrpe.d':
      ensure => link,
      target => '/etc/nagios/nrpe.d',
    }
  }

  # Auto-add a NSCA firewall rule on the monitor server just for us
  @@firewall { "200-nsca-${::fqdn}":
    proto  => 'tcp',
    dport  => '5667',
    tag    => 'nsca',
    source => $::default_ipaddress,
    action => 'accept',
  }
  @@firewall { "200-nsca-v6-${::fqdn}":
    proto    => 'tcp',
    dport    => '5667',
    source   => $::ipaddress6,
    provider => 'ip6tables',
    action   => 'accept',
  }

  # Add a VIRTUAL nrpe user
  @user { 'nrpe':
    ensure => present,
  }

  # Then realize that virtual user with collection syntax
  User <| title == 'nrpe' |>

  # Add firewall rule to allow NRPE from the monitoring server
  Firewall <<| tag == 'nrpe' |>>

}
