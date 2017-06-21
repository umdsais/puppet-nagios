# Installs the nagios plugin itself
# Third-party ones may exist in a yum repo and are installed that way
define nagios::plugin() {
  file { $title:
    name    => "/usr/${::lib_path}/nagios/plugins/${title}",
    source  => "puppet:///modules/nagios/plugins/${title}",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    seltype => 'nagios_services_plugin_exec_t',
    require => $::osfamily ? {
      'RedHat' => Package['nrpe', 'nagios-plugins'],
      'Debian' => Package['nrpe'],
      default  => Package['nrpe'],
    },
  }
}
