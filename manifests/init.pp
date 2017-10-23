# Nagios config for monitoring servers
class nagios (
  Boolean $nrpe               = true,
  Boolean $nsca               = true,
  Boolean $bpi                = false,
  Boolean $selinux            = true,
  Boolean $firewall           = true,
  String $url                = $::fqdn,
  $aliases             = [],
  String $webroot             = $nagios::params::webroot,
  String $cgiroot             = $nagios::params::cgiroot,
  Boolean $dev                = false,
  String $nrpe_plugin_package = $nagios::params::nrpe_plugin_package,
  String $nsca_server_package = $nagios::params::nsca_server_package,
  String $nsca_service        = $nagios::params::nsca_service,
  String $nsca_config         = $nagios::params::nsca_config,
  String $nagios_package      = $nagios::params::nagios_package,
  String $nagios_service      = $nagios::params::nagios_service,
  String $serveradmin         = 'root@localhost',
  String $ssl_cert            = '/path/to/cert.crt',
  String $ssl_key             = '/path/to/key.key',
  String $ssl_chain           = undef,
  String $auth_type           = 'basic',
) inherits nagios::params {

  if ($nsca) {
    class { '::nagios::server::nsca':
      nsca_server_package => $nsca_server_package,
      nsca_service        => $nsca_service,
      nsca_config         => $nsca_config,
      firewall            => $firewall,
    }
  }

  if ($nrpe) {
    class { '::nagios::server::nrpe':
      firewall            => $firewall,
      nrpe_plugin_package => $nrpe_plugin_package,
    }
  }

  if ($bpi) {
    class { '::nagios::server::bpi':
      url     => $url,
      selinux => $selinux,
      webroot => $webroot,
    }
  }

  include ::apache::mod::cgi
  include ::apache::mod::php
  include ::apache::mod::rewrite
  include ::nagios
  include ::nagios::templates

  # Install Nagios package
  package { 'nagios':
    ensure => installed,
    name   => $nagios_package,
  }

  # Create extra config directory
  file { '/etc/nagios/conf.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'nagios',
    mode    => '0755',
    purge   => true,
    recurse => true,
  }

  # Install nagios and other necessary packages
  package { [
    'pnp4nagios',
  ]:
    ensure  => installed,
  }

  # Create command definitions required for PNP4Nagios
  nagios_command { 'process-service-perfdata':
    command_line => '/usr/bin/perl /usr/libexec/pnp4nagios/process_perfdata.pl',
  }
  nagios_command { 'process-host-perfdata':
    command_line => '/usr/bin/perl /usr/libexec/pnp4nagios/process_perfdata.pl -d HOSTPERFDATA',
  }
  nagios_command { 'process-service-perfdata-file':
    command_line => '/usr/libexec/pnp4nagios/process_perfdata.pl --bulk=/var/log/nagios/service-perfdata',
  }
  nagios_command { 'process-host-perfdata-file':
    command_line => '/usr/libexec/pnp4nagios/process_perfdata.pl --bulk=/var/log/nagios/host-perfdata',
  }

  # Create firewall exception
  if ($firewall) {
    firewall { '100-nagios':
      proto  => 'tcp',
      dport  => ['443','80'],
      action => 'accept',
    }
  }

  # Non-SSL redirect
  ::apache::vhost { "${url}-http":
    servername      => $url,
    port            =>  80,
    docroot         => $cgiroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${url}/",
  }

  # Main SSL vhost for nagios and pnp4nagios
  ::apache::vhost { "${url}-https":
    servername           => $url,
    serveraliases        => $aliases,
    port                 => 443,
    docroot              => $cgiroot,
    notify               => Service['httpd'],
    ssl                  => true,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    ssl_chain            => $ssl_chain,
    serveradmin          => $serveradmin,
    directoryindex       => 'index.php',
    setenvif             => 'User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown',
    redirectmatch_regexp => '^/$',
    redirectmatch_dest   => "https://${url}/nagios",
    redirectmatch_status => 'permanent',
    aliases              => [
      {
        scriptalias => '/nagios/cgi-bin',
        path        => $cgiroot,
      },
      {
        alias => '/nagios',
        path  => $webroot,
      },

      {
        alias => '/apple-touch-icon.png',
        path  => "${webroot}/apple-touch-icon.png",
      },
      {
        alias => '/pnp4nagios',
        path  => "${webroot}/pnp4nagios/",
      },
    ],
    directories          => [
      {
        path           => $cgiroot,
        options        => '+ExecCGI',
        allow_override => 'All',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => $auth_type,
        auth_require   => 'valid-user local',
        auth_name      => 'Nagios',
      },
      {
        path           => $webroot,
        options        => 'None',
        allow_override => 'All',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => $auth_type,
        auth_require   => 'valid-user',
        auth_name      => 'Nagios',
      },
      {
        path           => "${webroot}/bpi",
        options        => 'None',
        allow_override => 'All',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => $auth_type,
        auth_require   => 'valid-user',
        auth_name      => 'Nagios',
      },
      {
        path           => "${webroot}/pnp4nagios/",
        allow_override => 'None',
        order          => 'Allow,Deny',
        allow          => 'from All',
        auth_type      => $auth_type,
        auth_require   => 'valid-user',
        auth_name      => 'Nagios',
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
  service { 'nagios':
    ensure     => running,
    name       => $nagios_service,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [ Package['nagios'], File['nagios.cfg'] ],
  }

  # Also reload the config hourly to handle items that have been deleted from
  # the config, which for some reason don't trigger a reload automatically
  file { 'reload-nagios':
    ensure  => file,
    path    => '/etc/cron.hourly/reload-nagios',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => '/bin/systemctl restart nagios.service >/dev/null',
  }

  # Install SELinux Nagios policy
  if ($selinux) {
    selinux::module { 'puppet-nagios':
      ensure    => 'present',
      source_te => 'puppet:///modules/nagios/puppet-nagios.te',
    }
  }

  # Guess nagios version
  $nagver = $::operatingsystemmajrelease ? {
    '7'     => 4,
    '6'     => 3,
    default => 3,
  }

  # Create generic contact
  nagios_contact { 'admin':
    contactgroups => 'users',
    alias         => 'Admin',
    use           => 'generic-contact',
    tag           => hiera('nagios_server'),
    email         => $serveradmin,
  }

  # Create other contacts from Hiera
  $users = hiera_hash('nagios::users')
  create_resources('nagios::user', $users)

  # Create contact groups from Hiera
  $groups = hiera_hash('nagios::groups')
  create_resources('nagios::contactgroup', $groups)

  # These configs are the ones that can't be dynamically generated by puppet,
  # for things that aren't managed by puppet, eg ESXi. These are managed by
  # puppet in the traditional way.
  # Nagios master config
  file { 'nagios.cfg':
    name    => '/etc/nagios/nagios.cfg',
    mode    => '0644',
    owner   => 'root',
    group   => 'nagios',
    content => template('nagios/nagios.cfg.4.erb'),
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

  # collect resources and populate /etc/nagios/nagios_*.cfg
  Nagios_host <<| tag == $::fqdn |>> {
    require        => Package['nagios'],
    notify         => Service['nagios'],
    owner          => 'root',
    group          => 'nagios',
    mode           => '0644',
  }
  Nagios_service <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios_servicedependency <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios_contact <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios_contactgroup <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
    owner   => 'root',
    group   => 'nagios',
    mode    => '0644',
  }
  Nagios::Servicegroup <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
  }
  Nagios::Hostgroup <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
  }
  Nagios::Command <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
  }
  Nagios::Plugin <<| tag == $::fqdn |>> {
    require => Package['nagios'],
    notify  => Service['nagios'],
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

  #### NAGIOS SERVICE
  @@nagios_service { "check_nagios_${::fqdn}":
    check_command       => 'check_nagios!/var/log/nagios/nagios.log!/usr/sbin/nagios',
    service_description => 'Nagios',
    tag                 => 'nagios',
  }

  #### NAGIOS STATS
  @@nagios_service { "check_nagiostats_${::fqdn}":
    check_command       => 'check_nagiostats',
    service_description => 'Nagios stats',
    tag                 => 'nagios',
  }
}
