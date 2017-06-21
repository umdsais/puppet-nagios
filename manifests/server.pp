# Nagios config for monitoring servers
class nagios::server (
  $nrpe,
  $nsca,
  $selinux,
  $firewall,
  $url,
  $dev = false
) {

  if ($nsca) {
    include ::nagios::nsca::server
  }

  if ($nrpe) {
    include ::nagios::nrpe::server
  }


  include ::mod_auth_cas
  include ::apache::mod::cgi
  include ::apache::mod::php
  include ::apache::mod::rewrite
  include ::nagios
  include ::nagios::client
  include ::nagios::commands
  include ::nagios::manual
  include ::nagios::aggregates
  include ::nagios::templates

  # Install Nagios package
  package { 'nagios':
    ensure => installed,
    name   => $nagios::nagios_package,
  }

  # Install nagios and other necessary packages
  package { [
    'pnp4nagios',
  ]:
    ensure  => installed,
  }

  # Non-SSL redirect
  ::apache::vhost { "${url}-http":
    servername      => $url,
    port            =>  80,
    docroot         => '/usr/lib64/nagios/cgi-bin',
    redirect_status => 'permanent',
    redirect_dest   => "https://${url}/",
  }

  # Main SSL vhost for nagios and pnp4nagios
  ::apache::vhost { "${url}-https":
    servername           => ${url},
    port                 => 443,
    docroot              => '/usr/lib64/nagios/cgi-bin',
    notify               => Service['httpd'],
    ssl                  => true,
    ssl_cert             => '/path/to/cert.crt',
    ssl_key              => '/path/to/key.key',
    ssl_chain            => '/path/to/chain.crt',
    serveradmin          => 'test@example.com',
    directoryindex       => 'index.php',
    setenvif             => 'User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown',
    redirectmatch_regexp => '^/$',
    redirectmatch_dest   => "https://${url}/nagios",
    redirectmatch_status => 'permanent',
    aliases              => [
      {
        scriptalias => '/nagios/cgi-bin',
        path        => '/usr/lib64/nagios/cgi-bin',
      },
      {
        alias => '/nagios',
        path  => '/usr/share/nagios/html',
      },

      {
        alias => '/apple-touch-icon.png',
        path  => '/usr/share/nagios/html/apple-touch-icon.png',
      },
      {
        alias => '/pnp4nagios',
        path  => '/usr/share/nagios/html/pnp4nagios/',
      },
    ],
    directories          => [
      {
        path           => '/usr/lib64/nagios/cgi-bin/',
        options        => '+ExecCGI',
        allow_override => 'All',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => 'CAS',
        auth_require   => 'valid-user local',
      },
      {
        path           => '/usr/share/nagios/html',
        options        => 'None',
        allow_override => 'All',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => 'CAS',
        auth_require   => 'valid-user',
      },
      {
        path           => '/usr/share/nagios/html/bpi',
        options        => 'None',
        allow_override => 'All',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => 'CAS',
        auth_require   => 'valid-user',
      },
      {
        path           => '/usr/share/nagios/html/pnp4nagios/',
        allow_override => 'None',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => 'CAS',
        auth_require   => 'valid-user',
        options        => 'FollowSymLinks',
        rewrites       => [
          {
            comment      => 'Installation directory',
            rewrite_base => '/pnp4nagios/',
          },
          {
            comment      => 'Protect application and system files from being viewed',
            rewrite_rule => [ '^(application|modules|system) - [F,L]' ],
          },
          {
            comment      => 'Allow any files or directories that exist to be displayed directly',
            rewrite_cond => [
              '%{REQUEST_FILENAME} !-f',
              '%{REQUEST_FILENAME} !-d',
            ],
            rewrite_rule => [ '.* index.php/$0 [PT,L]' ],
          },
        ],
      },
    ],
  }


  # Enable notifications or not?
  # Dev Nagios doesn't send notifications
  $enable_notifications = $dev ? {
    true    => 0,
    false   => 1,
    default => 1,
  }

  # Start the Nagios service, and make it restart if there have been changes to the config
  # We use the reload command rather than restart, since it is much faster
  service { 'nagios':
    ensure  => running,
    enable  => true,
    restart => $::operatingsystemmajrelease ? {
      '6'     => '/sbin/service nagios reload',
      '7'     => '/bin/systemctl restart nagios.service',
      default => '/sbin/service nagios restart',
    },
    require => [ Package['nagios'], File['nagios.cfg'] ],
  }

  # Also reload the config hourly to handle items that have been deleted from
  # the config, which for some reason don't trigger a reload automatically
  file { 'reload-nagios':
    ensure  => file,
    path    => '/etc/cron.hourly/reload-nagios',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => $::operatingsystemmajrelease ? {
      '6'     => '/sbin/service nagios reload >/dev/null',
      '7'     => '/bin/systemctl restart nagios.service >/dev/null',
      default => '/sbin/service nagios restart >/dev/null',
    },
  }

  # Install SELinux Nagios policy
  if ($selinux) {
    selinux::module { 'resnet-nagios':
      ensure    => 'present',
      source_te => 'puppet:///modules/nagios/resnet-nagios.te',
    }
  }

  # Guess nagios version
  $nagver = $::operatingsystemmajrelease ? {
    '7'     => 4,
    '6'     => 3,
    default => 3,
  }

  # These configs are the ones that can't be dynamically generated by puppet,
  # for things that aren't managed by puppet, eg ESXi. These are managed by
  # puppet in the traditional way.
  # Nagios master config
  file { 'nagios.cfg':
    name    => '/etc/nagios/nagios.cfg',
    mode    => '0644',
    owner   => 'root',
    group   => 'nagios',
    content => template("nagios/nagios.cfg.${nagver}.erb"),
    require => Package['nagios'],
    notify  => Service['nagios'],
    before  => Service['nagios'],
  }

  file { 'resource.cfg':
    name    => '/etc/nagios/private/resource.cfg',
    mode    => '0640',
    owner   => 'root',
    group   => 'nagios',
    content => template('nagios/resource.cfg.erb'),
    require => Package['nagios'],
    notify  => Service['nagios'],
    before  => Service['nagios'],
  }

  file { 'cgi.cfg':
    name    => '/etc/nagios/cgi.cfg',
    mode    => '0640',
    owner   => 'root',
    group   => 'nagios',
    source  => 'puppet:///modules/nagios/cgi.cfg',
    require => Package['nagios'],
    notify  => Service['nagios'],
    before  => Service['nagios'],
  }

  # Install some custom icons for the web interface
  nagios::icon { 'CentOS': }
  nagios::icon { 'Fedora': }
  nagios::icon { 'RedHat': }
  nagios::icon { 'Ubuntu': }
  nagios::icon { 'VMware': }
  nagios::icon { 'Windows': }
  nagios::icon { 'Debian': }
  nagios::icon { 'Scientific': }
  nagios::icon { 'f5': }
  nagios::icon { 'aggregate': }
  nagios::icon { 'SLES': }
  nagios::icon { 'idrac': }

  # Grab unified users from Hiera
  $unifiedusers = hiera('unifiedusers')

  # Turn all hiera users & groups into virtual users 
  # & groups which will later be selectively realised
  create_resources('nagios::user', $unifiedusers)

  # collect resources and populate /etc/nagios/nagios_*.cfg
  Nagios_host <<| |>> {
    require        => Package['nagios'],
    notify         => Service['nagios'],
    owner          => 'root',
    group          => 'nagios',
    mode           => '0644',
  }
  Nagios_service <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios_servicedependency <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios_contact <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios_contactgroup <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios_servicegroup <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Uob_nagios::Create_servicegroup <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
  }
  Nagios_hostgroup <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Uob_nagios::Create_hostgroup <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
  }
  Nagios_command <<| |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }

  # Create files needed for RADIUS Statistics
  File <<| tag == 'radius-statistics.ini' |>>

  # Install iPhone-friendly icon
  file { 'apple-touch-icon.png':
    name    => '/usr/share/nagios/html/apple-touch-icon.png',
    owner   => 'root',
    mode    => '0644',
    group   => 'root',
    source  => 'puppet:///modules/nagios/apple-touch-icon.png',
    require => Package['nagios'],
  }

  # Purge old configs
  resources { [
    'nagios_host',
    'nagios_service',
    'nagios_servicedependency',
    'nagios_contact',
    'nagios_contactgroup',
    'nagios_command',
    'nagios_servicegroup',
    'nagios_hostgroup',
  ]:
    purge  => true,
    notify => Service['nagios'],
  }

  # A nagios check to monitor the nagios service
  # Problably only useful if >1 nagios server
  # Chicken <=> Egg, anyone?

  @@nagios::create_servicegroup { "${::fqdn}-nagios":
    groupname  => 'nagios',
    groupalias => 'Nagios',
  }

  #### NAGIOS SERVICE
  @@nagios_service { "check_nagios_${::fqdn}":
    check_command       => 'check_nagios!/var/log/nagios/nagios.log!/usr/sbin/nagios',
    service_description => 'Nagios',
    servicegroups       => 'nagios',
  }

  #### NAGIOS STATS
  @@nagios_service { "check_nagiostats_${::fqdn}":
    check_command       => 'check_nagiostats',
    service_description => 'Nagios stats',
    servicegroups       => 'nagios',
  }

  #### NAGIOS CONFIG
  # Check the config every time Nagios is restarted
  exec { 'check_nagios_config_passive':
    command     => '/usr/lib64/nagios/plugins/check_nagios_config_passive',
    refreshonly => true,
    subscribe   => Service['nagios'],
  }

  # Also run the check every hour, so the passive check can't get stale
  file { 'check_nagios_config_passive_symlink':
    ensure => link,
    name   => '/etc/cron.hourly/check_nagios_config_passive',
    target => '/usr/lib64/nagios/plugins/check_nagios_config_passive',
  }

  # Passive Nagios service definition for the above
  @@nagios_service { "check_nagios_config_${::fqdn}":
    service_description   => 'Nagios config',
    active_checks_enabled => 0,
    max_check_attempts    => 1,
    check_freshness       => 1,
    freshness_threshold   => 172800,
    check_command         => 'check_dummy!1 "No passive checks for at least 48h"',
    servicegroups         => 'nagios',
  }

  # Add a snippet to motd
  motd::register{'Nagios monitoring for everything': }
}
