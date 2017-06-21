# Nagios base class
class nagios {
  if $::osfamily == 'RedHat' {
    package { ['nagios-plugins',
      'nagios-plugins-all',
      'nagios-plugins-bonding',
      'nagios-plugins-perl']:
      ensure  => installed,
      require => Class['epel'],
    }

    package { 'nagios-plugins-check-tcptraffic':
      ensure  => installed,
      require => Yumrepo['resnet'],
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
}
