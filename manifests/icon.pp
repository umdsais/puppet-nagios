# The nagiosicon custom type installs the GD2 and PNG versions of the icon
define nagios::icon (
  String $filename = $title
) {
  file { "/usr/share/nagios/html/images/logos/${filename}.gd2":
    source  => "puppet:///modules/nagios/icons/${filename}.gd2",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['nagios'],
  }
  file { "/usr/share/nagios/html/images/logos/${filename}.png":
    source  => "puppet:///modules/nagios/icons/${filename}.png",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['nagios'],
  }
}
